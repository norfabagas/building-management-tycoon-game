# Game Logic & Architecture

## Implementation status

The Flutter app uses MVVM with `ChangeNotifier`. `DistrictSimulation` implements the approved apartment starter catalog, five 5-second phases, queued purchases, sequential shell/B1 construction, Morning admissions, Sunday rent, daily parking/expenses/tax and chronological offline catch-up. `GameRepository` reads, simulates and writes a full versioned snapshot in a Sembast transaction (SQLite on Android; IndexedDB on Web) before the district view model publishes success. `SaveManager` retains the five-slot legacy/profile metadata store. Unsupported or corrupt snapshots are preserved. See [Gameplay.md](Gameplay.md) and [Setup.md](Setup.md) for implementation details and the remaining building/upgrade catalogs.

## Game State & Data Models
- **SaveManager:** Handles local serialization for up to **5 distinct Profile slots**.
- **TimeManager:** Tracks the current `Day`, in-game weekday and `Phase` (Morning, Day, Afternoon, Night, Noon/Closing) for the active profile. One day is 25 real seconds, with 5 seconds per phase. Day 1 is Monday; `(day - 1) % 7 == 6` identifies Sunday.
- **CBD Area (Root):** Holds the `areaName`, `dollars` (primary funds), and a 2D layout of `Building` objects on the land.
- **Road layout:** Tracks generated road segments outside building footprints. A confirmed occupied construction plot creates its surrounding road automatically; compatible shared segments are represented once. Road layout is part of full local game state, not profile metadata.
- **Building:** Attributes include `id`, `type`, `luxuryLevel`, `parkingQuota` (calculated from underground levels). 
  - **Immutable Attributes:** `footprintWidth`, `footprintLength`, `roomsPerFloor`, `gridCoordinates`.
  - **Upgradeable Attributes:** 
    - `aboveGroundFloors`: Starts at 1; add floors up to 10 total (2026-10-14 user override of permanent floors).
    - `undergroundFloors`: Starts at 0, upgradable up to a max of 3. Strictly dedicated to Parking.
    - `standardLifts`: Starts at 0, upgradable up to a max of 3.
    - `executiveLifts`: Starts at 0, upgradable up to a max of 1.
    - `hasStairs`: `true` by default.
  - **Upgrade order:** One optional kind/stage/start-day per building. Reserve through `orderUpgrade`, debit at the next Noon, start next Morning, and increment the completed count at the final Noon (2 days for floors, 1 for basements/lifts). Existing business remains open. Price comes from `BuildingUpgrade`: floors/basements use the footprint rate, lifts use 1/4 or 1/2 of the immutable original floor+B1 quote. Each upgrade adds $40/day upkeep when completed and its paid cost to valuation. Lift rent/happiness effects are deferred by user approval.
  - **Capacity and navigation:** Completed floors multiply rooms per floor, completed basements multiply bays per basement. Stable zero-based room IDs span floors; admissions scan all rooms but never exceed free total parking or daily admissions. Per-basement parking use is allocated from B1 downward. Navigate completed levels only, skipping zero.
  - **Schema 4:** Persist completed counts and upgrade order in the existing local transaction. Read schemas 1/2/3 as one floor/B1 and zero lifts with no pending upgrade, preserving construction stage, tenants and ledger. Reject invalid caps, room/bay bounds or order state; older clients reject schema 4. Initial manual opening and clock migrations remain in force.
- **Floor:** Represents a vertical level (can be negative for underground). Contains a list of `Room`/`Facility` objects.
- **Room/Facility:** The usable space. Attributes vary heavily by building type.
- **Persistence:** All state models are serialized strictly to local storage into one of the 5 profile slots.

## Hierarchy
`SaveManager` -> `Profile (1-5)` -> `TimeManager` | `Area` -> `Building` (X, Y on land) -> `Floor` (Z axis relative to building) -> `Room` -> `Tenant/Customer`

## Revenue & Expense Calculation Logic

The selected model is **Option 1: Relaxed idle**, with weekly apartment rent at Sunday Noon and daily settlement for other income. [Economy.md](Economy.md) defines current formulas and billing conventions. [EconomyOptions.md](EconomyOptions.md) is the original comparison; its daily-equivalent apartment figures do not describe the selected payment schedule.
The player's Dollar balance is strictly updated on a daily basis. Throughout the day phases, transactions are simulated, but the actual funds are only modified during the **Noon (Closing the book)** phase.
- **Synergy Multiplier:** Calculate eligible adjacent bonuses, sum them and cap the bonus at 15%. Individual bonuses/adjacency distance remain catalog work; the former +30% example is not a selected value.
- **Closing The Books (Noon Phase):** `OperatingNet = CashGross - Maintenance - Tax`; `balanceAfter = balanceBefore + OperatingNet - queuedPurchaseCosts`. Settle reserved purchases once and show them separately from operating costs.
- **Gross Revenue (Polymorphic):**
  - *Hotel Logic:* `Daily Revenue = Occupied Rooms * Room Rate * synergyModifier`. (Occupied Rooms constrained by `parkingQuota`).
  - *Apartment Logic:* Add the occupied day's portion of weekly rent, with that day's eligible synergy, to a pending ledger. `ApartmentCashGross = pendingRentIncludingToday` only on Sunday; otherwise it is zero. Transfer and clear the ledger in the same Sunday transaction. Occupancy is constrained by parking; leaving tenants retain any already-earned pending rent.
  - *Office Tower Logic:* `Daily Revenue = Floors Rented * Floor Rate * synergyModifier`. (Floors Rented constrained by `parkingQuota`).
  - *F&B Logic:* `Daily Revenue = Simulated Sales per Phase * Item Price * synergyModifier`. (Sales traffic constrained by `parkingQuota`).
  - *Parking Logic:* Daily tenant-bay fees plus per-admitted-visit fees. Reserve tenant bays first; cap simultaneous visitor admissions by remaining bays. Phase turnover can produce more daily visits than physical bays without exceeding simultaneous capacity. Apartment parking still pays daily.
- **Maintenance Logic:** Apartments use $40 per completed floor, basement, standard lift and executive lift daily. Other type/luxury coefficients remain unfinished.
- **Tax Logic:** `Tax = 0.0005 * completedBuildingValuation + 0.02 * CashGross`, with valuation/revenue components separately rounded to cents. Apartment pending rent is excluded from cash gross until Sunday; daily valuation tax and upkeep continue throughout the week.

### Apartment billing and save state

Persist weekly rent, pending daily accruals, completed closing IDs and the game-day/phase remainder alongside the wallet and order queue. Use actual occupied days for partial weeks, with deterministic integer-cent allocation as defined in Economy.md. Accrue Sunday's occupied-day rent before collecting the ledger. Do not reprice past accruals after upgrades or count collection as a second earning for unlocks. The finance panel shows pending apartment rent and next Sunday payment separately from spendable dollars.

## Offline Idle Generation Logic
- The game relies on the local device clock to simulate the passage of in-game **Days** while offline.
- **Offline Calculation:** 
  1. Determine nonnegative elapsed time from the saved device-clock watermark; retain the game-day/phase remainder and convert at 25 real seconds per game day. Do not use real-world Sundays for rent billing. Schema 1 saves first catch up at 60 seconds per phase; schema 2 stores the interval. After catch-up, scale the phase remainder proportionally to the current 5-second interval and commit the migration atomically with the snapshot. Backward clocks retain the watermark while still migrating fractional progress. Unknown schemas/intervals remain errors and must not reset a wallet.
  2. Simulate missed phases and closings chronologically without a cap, including construction, rent accrual, daily receipts, maintenance, taxes and purchases. Collect apartment rent at each crossed in-game Sunday Noon; retain it pending when no Sunday is crossed.
  3. Save the resulting wallet, pending rent, closing IDs, orders and clock together, then publish the already-applied summary. Retrying/loading the same result must not duplicate rent. Backward device-clock changes add no elapsed time and must not lower the saved watermark.

## Placement & Construction Logic

Construction now ends at `parkingDone` and does not advance automatically to `ready`. `DistrictSimulation.openBusiness` validates completion, changes the stage to `ready` without charging or admitting tenants, and treats repeated opening as a no-op. The repository persists it atomically before the view model publishes success. Subsequent Morning processing admits tenants under the existing quota. While closed, rent/parking accrual is zero; completed maintenance and valuation taxes remain payable. Schema 3 prevents old clients from bypassing this gate, while preserving schema 1/2 already-open buildings.

`constructionProgress` derives the shell's fraction from its nine Morning-to-final-Noon phase intervals (2/3 weight) and B1 from its four intervals (1/3 weight). Queue/payment states are 0; the shell/B1 wait holds at 2/3; completed/open states are 1. The view model supplies elapsed phase time for live presentation. Active B1 stays below 100% until the completed state is committed. Progress is display state derived from the snapshot, not a separate persisted timer.
- **Area Grid System:** The CBD is a 2D coordinate grid (X, Y).
- **Construction Wizard:**
  1. Player selects building type (e.g., Hotel, Office).
  2. Player drags and drops on the grid to define `footprintWidth` and `footprintLength`.
     - Derive a surrounding-road preview outside the selected footprint. Validate its required space alongside footprint collisions/bounds; do not generate saved roads while the player is only drawing or canceling a preview.
  3. Player inputs `aboveGroundFloors`.
  4. **Unit Capacity Check:** System calculates `roomsPerFloor`. For Hotels and Apartments, this is mathematically derived based on the total area (`footprintWidth * footprintLength`), capping the number of units that can fit on a single floor.
  5. System calculates the initial capital required. 
  6. On successful confirmation, reserve the purchase funds and mark the selected empty plot as occupied by a construction site. Generate its surrounding road in the same saved placement operation, merging compatible existing road segments without overwriting buildings. A failed/canceled placement leaves neither a site nor orphan roads. Payment and construction start still follow the selected Noon/Morning schedule.

### Automatic road generation

Roads are generated around the occupied footprint rather than carved out of its usable floor area. They do not alter immutable building dimensions or parking capacity. The approved starter uses a one-tile ring including corners, free of cost/upkeep, on unbounded land. A set union of saved occupied-plot rings derives the road layout, so shared tiles appear once and canceling an unpaid plot removes only its unshared road tiles. Saving plots atomically also saves the full information needed to reconstruct roads. Manual road tools and traffic/pathfinding simulation are outside this release.
