# Game Logic & Architecture

## Game State & Data Models
- **TimeManager:** Tracks the current `Day` and `Phase` (Morning, Day, Afternoon, Night, Noon/Closing).
- **CBD Area (Root):** Holds the `areaName`, total funds, and a 2D layout of `Building` objects on the land.
- **Building:** Attributes include `id`, `type`, `luxuryLevel`. 
  - **Immutable Physical Attributes:** `footprintWidth`, `footprintLength`, `totalFloors`, `roomsPerFloor`. These are set once during construction.
- **Floor:** Represents a vertical level (can be negative for underground). Contains a list of `Room`/`Facility` objects.
- **Room/Facility:** The usable space. Attributes vary heavily by building type.
- **Persistence:** All models must be serializable for strictly local storage.

## Hierarchy
`TimeManager` | `Area` -> `Building` (X, Y on land) -> `Floor` (Z axis relative to building) -> `Room` -> `Tenant/Customer`

## Revenue & Expense Calculation Logic
During the **Noon (Closing the book)** phase, the game calculates net profit: `Net = Gross Revenue - Maintenance - Tax`.
- **Gross Revenue (Polymorphic):**
  - *Hotel Logic:* `Daily Revenue = Occupied Rooms * Room Rate (Scaled by luxuryLevel)`.
  - *Apartment Logic:* `Daily Revenue = Rented Rooms * Rent Rate (Scaled by luxuryLevel)`.
  - *Office Tower Logic:* `Daily Revenue = Floors Rented * Floor Rate (Scaled by luxuryLevel)`.
  - *F&B Logic:* `Daily Revenue = Simulated Sales per Phase * Item Price`.
- **Maintenance Logic:** Each building type utilizes a complex formula. Examples:
  - *Hotels:* Base cost + (Occupied rooms * Cleaning cost) + (Total Floors * Utility factor).
  - *Offices:* Fixed high utility and security costs based on total physical footprint.
- **Tax Logic:** Evaluated based on the area's overall valuation, building types, and daily gross revenue.

## Offline Idle Generation Logic
- The game relies on the local device clock to simulate the passage of in-game **Days** while offline.
- **Offline Calculation:** 
  1. Determine elapsed real time since `lastSavedTime` and convert to in-game Days.
  2. Iterate the Revenue & Expense Calculation Logic (including maintenance and taxes) for the missed days.
  3. Deduct expenses from revenues to award net offline earnings upon next launch.

## Placement & Construction Logic
- **Area Grid System:** The CBD is a 2D coordinate grid (X, Y).
- **Construction Wizard:**
  1. Player selects building type.
  2. Player drags and drops on the grid to define `footprintWidth` and `footprintLength`.
  3. Player inputs `totalFloors` and `roomsPerFloor`.
  4. System calculates the massive initial capital required. If funds are sufficient, the building is instantiated with permanently locked physical dimensions.
