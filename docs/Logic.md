# Game Logic & Architecture

## Game State & Data Models
- **CBD Area (Root):** Holds the `areaName`, total funds, and a 2D layout of `Building` objects on the land.
- **Building:** Attributes include `id`, `type` (Office, Mall, Apartment, etc.), `footprint`, and a list of `Floor` objects.
- **Floor:** Represents a vertical level (can be negative for underground). Contains a list of `Room`/`Facility` objects.
- **Room/Facility:** The actual usable space on a floor. Attributes include `id`, `type`, `level`, `baseRevenue`, `collectionTime`, `powerDraw`, `waterDraw`.
- **Tenant:** Assigned to a `Room`. Attributes include `id`, `type`, `happinessLevel`, `needs`.
- **Persistence:** All models must be serializable for strictly local storage (e.g., JSON to Hive/sqflite).

## Hierarchy
`Area` -> `Building` (X, Y on land) -> `Floor` (Z axis relative to building) -> `Room` -> `Tenant`

## Offline Idle Generation Logic
- The game uses a time-based delta generation system reliant entirely on the local device clock.
- `Revenue = BaseRevenue * LevelMultiplier * HappinessModifier`
- **Offline Calculation:** The system records the `lastSavedTime` locally. Upon next launch, `offlineEarnings = (currentDeviceTime - lastSavedTime) * (Revenue / collectionTime)`.
- Calculates revenue by recursively iterating through all Areas -> Buildings -> Floors -> Rooms.

## Placement & Validation Logic
- **Area Grid System:** The CBD is a 2D coordinate grid (X, Y) where Buildings are placed.
- **Floor Construction:** 
  1. Check if the building type allows the floor expansion.
  2. Check if the player has sufficient funds.
  3. Validate structural limits (max underground/above ground limits per building type).
- **Room/Tenant Assignment:** Rooms are built on specific floors. Tenants are then assigned to those rooms based on room type compatibility.

## Upgrade Logic
- Upgrading a room or building increases its Level by 1.
- Cost scales exponentially: `NextCost = BaseCost * (GrowthFactor ^ Level)`.
