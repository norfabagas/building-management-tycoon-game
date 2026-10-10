# Game Logic & Architecture

## Game State & Data Models
- **TimeManager:** Tracks the current `Day` and `Phase` (Morning, Day, Afternoon, Night, Noon/Closing).
- **CBD Area (Root):** Holds the `areaName`, total funds, and a 2D layout of `Building` objects on the land.
- **Building:** Attributes include `id`, `type`, `footprint`, and a list of `Floor` objects.
- **Floor:** Represents a vertical level (can be negative for underground). Contains a list of `Room`/`Facility` objects.
- **Room/Facility:** The usable space. Attributes vary heavily by building type.
- **Persistence:** All models must be serializable for strictly local storage (e.g., JSON to Hive/sqflite).

## Hierarchy
`TimeManager` | `Area` -> `Building` (X, Y on land) -> `Floor` (Z axis relative to building) -> `Room` -> `Tenant/Customer`

## Revenue Calculation Logic
Because different buildings operate uniquely, revenue calculation uses polymorphic logic triggered during the day and finalized during the **Noon (Closing the book)** phase:
- **Hotel Logic:** Algorithm simulates daily check-ins/check-outs. `Daily Revenue = Occupied Rooms * Room Rate`.
- **Apartment Logic:** Stable income. `Daily Revenue = Rented Rooms * Rent Rate`. (Requires maintaining tenant happiness to prevent move-outs).
- **Office Tower Logic:** Macro-scale income. `Daily Revenue = Floors Rented * Floor Rate`.
- **F&B Logic:** Transactional income. `Daily Revenue = Simulated Sales per Phase (Morning -> Night) * Item Price`. Influenced heavily by building traffic and day phases.

## Offline Idle Generation Logic
- The game relies on the local device clock to simulate the passage of in-game **Days** while offline.
- **Offline Calculation:** 
  1. Determine how much real time has passed since `lastSavedTime`.
  2. Convert elapsed real time into elapsed in-game Days and Phases.
  3. Iterate the Revenue Calculation Logic for the number of missed days.
  4. Summarize and award total offline earnings upon next launch.

## Placement & Validation Logic
- **Area Grid System:** The CBD is a 2D coordinate grid (X, Y) where Buildings are placed.
- **Floor Construction:** 
  1. Check if the building type allows the floor expansion.
  2. Check if the player has sufficient funds.
  3. Validate structural limits.
