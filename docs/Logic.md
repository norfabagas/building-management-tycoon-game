# Game Logic & Architecture

## Small-device reachability — 2026-10-17

Planning details scroll independently from their action footer. Final review keeps the selected footprint/floor quote and current balance visible; redraw restores the saved preview and camera, while cancellation clears the unsaved plan. Upgrade/acceleration/profile dialogs share a bounded, keyboard-aware review shell; existing view-model/repository busy/error/commit guards remain authoritative. No schema or asset changes. See [MobileReachability.md](MobileReachability.md).

## Custom tenant release design — 2026-10-17

Manage pushes TenantManagementScreen on the existing interior Navigator stack. Read current unit state by stable IDs and commit only through DistrictViewModel.save plus DistrictSimulation.vacate. Failed writes stay in the review with inline retry/refresh; successful writes return to the refreshed interior. No new persistence fields or domain mechanics. See [TenantManagement.md](TenantManagement.md).

## Delete saved profiles — 2026-10-17

Use a transactional profiles/catalog record and profile_lifecycle ownership/deletion watermarks alongside districts. Validate legacy metadata once on import. Deletion checks the reviewed profile identity, removes its snapshot, clears its slot and advances its watermark atomically. Current game updates validate catalog/owner identity before catch-up/actions. Serialize local operations and use database transactions across manager instances. See [DeleteProfiles.md](DeleteProfiles.md).

## Full-screen tenant activity — 2026-10-17

Resolve a full-screen interior by stable building/unit IDs from every DistrictViewModel snapshot. Derive its floor and live status without a second simulation or persisted navigation state. Reuse existing room removal transactions; refresh vacancy/error/retry in place. Schema 8/catalog 2 and economy are unchanged. See [TenantInterior.md](TenantInterior.md).

## Volumetric figures and visible floors — 2026-10-17

Exterior height derives from completedFloors, not footprint alone or the upgrade order. Initial shell completion exposes its completed storeys; a floor upgrade raises the roof only when domain completion increments the saved floor count. Cancel/pending upgrades, basements, lifts and luxury do not add height. Bounds, picking, occlusion and rendering use the same floor-aware projection. Snapshot schema 8/catalog 2 and economy remain unchanged. See [VolumeAndHeight.md](VolumeAndHeight.md).


## Road network and animation — 2026-10-17

Schema **8**, catalog 2 persists `roadNetwork.mainRow` and inclusive axis-aligned public street segments. Schemas 1–7 derive a safe highway/access network on import; their existing financial and clock catch-up order remains intact. Sparse routing uses obstacle boundary coordinates instead of allocating every tile between distant plots. Connectivity floods public segments and building rings from the highway; isolated public segments never seed access. Placement validates road reservations, occupied plots/decorations and connected-ring access before debiting money. Cancellation preserves a bridge ring if removing it would disconnect an existing building. Repository transactions continue to cover migration, actions and rollback. Old clients reject schema 8. Earlier schema-7 statements describe the previous release.

Map traffic uses a separate presentation ticker and repaint boundary, never simulation time or saved counters. TickerMode and reduced-motion settings suspend its clock; changing days does not reset movement. Terrain, picking, traffic and highway share MapProjection. See [DistrictRoads.md](DistrictRoads.md).


## Current override — 2026-10-16

Self-test correction (2026-10-17): acceleration confirmation validates a transient reviewed-job token (building ID, construction stage or upgrade kind, and start day) together with the gem quote, after repository catch-up. Equal-price replacement jobs require a fresh review. Capture the token before awaiting the dialog; never rederive it at confirmation. A rejection rolls back the transaction, including catch-up, so Retry advances the preserved record once. The token is not persisted and schema 7 remains unchanged. See GameplayValidation.md for the failing reproduction and regression cases.

The gameplay audit optimizes offline advancement by memoizing each receiver's synergy only within one synchronous advance. Layout and compatible neighbor types do not change during that operation, including construction/upgrade completion. Clear the transient map in finally; never serialize or retain it across placement/cancellation or other player actions. Every chronological phase, closing, rounding and reward still executes. See GameplayValidation.md for whole-state replay and performance evidence.

Schema 7/catalog 2 implements the user's approved [four-type catalog](FigmaCatalogProposal.md). Existing schema 1–6 saves first catch up using catalog 1 and their saved clock cadence; only then switch to catalog 2 and award eligible historical achievements once. Existing balances, room IDs, pending rent, completed levels/lifts, queue stages and closing IDs survive. Old clients reject schema 7. All mutations, achievement rewards, visits/sales, gems and decoration placement/moves remain in the existing repository transaction. Unknown versions/catalogs and invalid caps/collisions preserve the original record.

The existing `ApartmentBuilding` class is retained as a compatible serialization/model name and now stores `type`, immutable `initialFloors`/`originalQuote`, luxury, visitor counters and optional acceleration alongside the existing fields. Apartments/hotels index rooms across floors; office IDs index whole floors with weighted bay reservations; food courts have no fabricated room tenants. Food counters contain current-window parties and daily visits/sales/parking. Luxury/type modifiers apply to new revenue, not historic accrual. Achievement IDs form a saved set, independent of spent gems. Decorations occupy one validated tile and cannot block future roads or footprints. Initial and upgrade acceleration store the active job and paid gems, activate at the next Morning and preserve manual opening.

Schema 6 uses four six-second phase windows, representing 00:00–06:00, 06:00–12:00, 12:00–18:00 and 18:00–24:00. At midnight, close the old day once before advancing the calendar and running the next Morning actions. Legacy schemas 1–5 first catch up using their stored five-phase cadence (60 or 5 seconds per phase), then preserve the fraction within the current daylight phase in its new six-second window. An already-closed legacy Noon advances once into the next Morning instead of billing twice. Preserve backward-clock watermark, transactional rollback and all balances/ledgers. Old clients reject schema 6. Construction progress uses elapsed new game days, not the former five-phase divisor.

## Implementation status

The Flutter app uses MVVM with `ChangeNotifier`. `DistrictSimulation` implements the approved apartment starter catalog, five 5-second phases, queued purchases, sequential shell/B1 construction, Morning admissions, Sunday rent, daily parking/expenses/tax and chronological offline catch-up. `GameRepository` reads, simulates and writes a full versioned snapshot in a Sembast transaction (SQLite on Android; IndexedDB on Web) before the district view model publishes success. `SaveManager` retains the five-slot legacy/profile metadata store. Unsupported or corrupt snapshots are preserved. See [Gameplay.md](Gameplay.md) and [Setup.md](Setup.md) for implementation details and the remaining building/upgrade catalogs.

## Game State & Data Models

Schema 5 adds `purchasesSinceClosing`/`refundsSinceClosing` and closing refund history. Before offline advancement, schemas 1–4 deduct only their previously uncharged queued building/upgrade costs. Already-paid states keep their balance. This conversion and the user action commit in one repository transaction. Immediate actions change Balance; closing copies/clears history counters and applies only operating net. Cancellation removes a pre-opening building or unfinished upgrade and credits its quote once; retain incurred costs and prior tenants/rent. Old clients reject schema 5.
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
  - **Upgrade order:** One optional kind/stage/start-day per building. Debit Balance immediately through `orderUpgrade`, queue through the next Noon without another debit, start the following Morning, and increment the completed count at the final Noon (2 days for floors, 1 for basements/lifts). Existing business remains open. Price comes from `BuildingUpgrade`: floors/basements use the footprint rate, lifts use 1/4 or 1/2 of the immutable original floor+B1 quote. Each upgrade adds $40/day upkeep when completed and its paid cost to valuation. Lift rent/happiness effects are deferred by user approval.
  - **Capacity and navigation:** Completed floors multiply rooms per floor, completed basements multiply bays per basement. Stable zero-based room IDs span floors; admissions scan all rooms but never exceed free total parking or daily admissions. Per-basement parking use is allocated from B1 downward. Navigate completed levels only, skipping zero.
  - **Schema 4:** Persist completed counts and upgrade order in the existing local transaction. Read schemas 1/2/3 as one floor/B1 and zero lifts with no pending upgrade, preserving construction stage, tenants and ledger. Reject invalid caps, room/bay bounds or order state; older clients reject schema 4. Initial manual opening and clock migrations remain in force.
- **Floor:** Represents a vertical level (can be negative for underground). Contains a list of `Room`/`Facility` objects.
- **Room/Facility:** The usable space. Attributes vary heavily by building type.
- **Persistence:** All state models are serialized strictly to local storage into one of the 5 profile slots.

## Hierarchy
`SaveManager` -> `Profile (1-5)` -> `TimeManager` | `Area` -> `Building` (X, Y on land) -> `Floor` (Z axis relative to building) -> `Room` -> `Tenant/Customer`

## Revenue & Expense Calculation Logic

The selected model is **Option 1: Relaxed idle**, with weekly apartment rent at Sunday Noon and daily settlement for other income. [Economy.md](Economy.md) defines current formulas and billing conventions. [EconomyOptions.md](EconomyOptions.md) is the original comparison; its daily-equivalent apartment figures do not describe the selected payment schedule.
The single Balance changes immediately for confirmed purchases and cancellation refunds. Operating income, maintenance and tax still settle at Noon. Refunds never increase earned revenue or taxable cash gross.
- **Synergy Multiplier:** Calculate eligible adjacent bonuses, sum them and cap the bonus at 15%. Individual bonuses/adjacency distance remain catalog work; the former +30% example is not a selected value.
- **Closing The Books (Noon Phase):** `OperatingNet = CashGross - Maintenance - Tax`; `balanceAfter = balanceBefore + OperatingNet`. Purchase/refund history accumulators are copied to the closing statement and cleared without affecting the wallet again.
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
  6. On successful confirmation, deduct the complete quote from Balance and mark the selected empty plot as occupied by a construction site in the same transaction. Generate its surrounding road in the same saved placement operation, merging compatible existing road segments without overwriting buildings. A failed/canceled placement leaves neither a site nor orphan roads. Payment is immediate; the existing Noon queue transition and following-Morning construction start remain unchanged.

### Automatic road generation

Roads are generated around the occupied footprint rather than carved out of its usable floor area. They do not alter immutable building dimensions or parking capacity. The approved starter uses a one-tile ring including corners, free of cost/upkeep, on unbounded land. A set union of saved occupied-plot rings derives the road layout, so shared tiles appear once and canceling an unpaid plot removes only its unshared road tiles. Saving plots atomically also saves the full information needed to reconstruct roads. Manual road tools and traffic/pathfinding simulation are outside this release.
