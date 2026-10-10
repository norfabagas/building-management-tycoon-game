# Game Logic & Architecture

## Game State & Data Models
- **SaveManager:** Handles local serialization for up to **5 distinct Profile slots**.
- **TimeManager:** Tracks the current `Day` and `Phase` (Morning, Day, Afternoon, Night, Noon/Closing) for the active profile.
- **CBD Area (Root):** Holds the `areaName`, `dollars` (primary funds), and a 2D layout of `Building` objects on the land.
- **Building:** Attributes include `id`, `type`, `luxuryLevel`, `parkingQuota` (calculated from underground levels). 
  - **Immutable Attributes:** `footprintWidth`, `footprintLength`, `aboveGroundFloors`, `roomsPerFloor`, `gridCoordinates`.
  - **Upgradeable Attributes:** 
    - `undergroundFloors`: Starts at 0, upgradable up to a max of 3. Strictly dedicated to Parking.
    - `standardLifts`: Starts at 0, upgradable up to a max of 3.
    - `executiveLifts`: Starts at 0, upgradable up to a max of 1.
    - `hasStairs`: `true` by default.
- **Floor:** Represents a vertical level (can be negative for underground). Contains a list of `Room`/`Facility` objects.
- **Room/Facility:** The usable space. Attributes vary heavily by building type.
- **Persistence:** All state models are serialized strictly to local storage into one of the 5 profile slots.

## Hierarchy
`SaveManager` -> `Profile (1-5)` -> `TimeManager` | `Area` -> `Building` (X, Y on land) -> `Floor` (Z axis relative to building) -> `Room` -> `Tenant/Customer`

## Revenue & Expense Calculation Logic
The player's Dollar balance is strictly updated on a daily basis. Throughout the day phases, transactions are simulated, but the actual funds are only modified during the **Noon (Closing the book)** phase.
- **Synergy Multiplier:** Before calculating revenue, the Area iterates through all buildings to calculate a `synergyModifier` based on adjacent `gridCoordinates`. (e.g., F&B next to Office = +30% Sales Modifier).
- **Closing The Books (Noon Phase):** `Net = Gross Revenue - Maintenance - Tax`. The Net is then committed.
- **Gross Revenue (Polymorphic):**
  - *Hotel Logic:* `Daily Revenue = Occupied Rooms * Room Rate * synergyModifier`. (Occupied Rooms constrained by `parkingQuota`).
  - *Apartment Logic:* `Daily Revenue = Rented Rooms * Rent Rate * synergyModifier`. (Rented Rooms constrained by `parkingQuota`).
  - *Office Tower Logic:* `Daily Revenue = Floors Rented * Floor Rate * synergyModifier`. (Floors Rented constrained by `parkingQuota`).
  - *F&B Logic:* `Daily Revenue = Simulated Sales per Phase * Item Price * synergyModifier`. (Sales traffic constrained by `parkingQuota`).
  - *Parking Logic:* `Daily Revenue = Min(Visitor/Tenant Traffic, parkingQuota) * Daily Parking Fee`.
- **Maintenance Logic:** Each building type utilizes a complex formula. Base cost + Room maintenance + **Lift Maintenance** (Elevators incur high daily fees).
- **Tax Logic:** Evaluated based on the area's overall valuation, building types, and daily gross revenue.

## Offline Idle Generation Logic
- The game relies on the local device clock to simulate the passage of in-game **Days** while offline.
- **Offline Calculation:** 
  1. Determine elapsed real time since `lastSavedTime` for the loaded profile and convert to in-game Days.
  2. Iterate the Revenue & Expense Calculation Logic (including maintenance and taxes) for the missed days.
  3. Batch-commit the calculated Net Profit/Loss for all missed days to the player's Dollar balance upon next launch.

## Placement & Construction Logic
- **Area Grid System:** The CBD is a 2D coordinate grid (X, Y).
- **Construction Wizard:**
  1. Player selects building type.
  2. Player drags and drops on the grid to define `footprintWidth` and `footprintLength`.
  3. Player inputs `aboveGroundFloors` and `roomsPerFloor`.
  4. System calculates the initial capital required. 
