# Game Logic & Architecture

## Game State & Data Models
- **Building:** Holds a 2D layout (X, Y axis) of Room objects, tracks total capacity, total power usage, and total water usage.
- **Room:** Attributes include `id`, `type`, `level`, `cost`, `baseRevenue`, `collectionTime`, `powerDraw`, `waterDraw`.
- **Tenant:** Attributes include `id`, `happinessLevel`, `assignedRoom`.
- **Persistence:** All models must be serializable for strictly local storage (e.g. JSON to Hive/sqflite).

## Offline Idle Generation Logic
- The game uses a time-based delta generation system reliant entirely on the local device clock.
- `Revenue = BaseRevenue * LevelMultiplier * HappinessModifier`
- **Offline Calculation:** The system records the `lastSavedTime` locally. Upon next launch, `offlineEarnings = (currentDeviceTime - lastSavedTime) * (Revenue / collectionTime)`. (Capped at a maximum offline time limit, e.g., 12 or 24 hours to prevent infinite accumulation).
- **Cheat Prevention (Optional):** Basic sanity checks on local time jumps, though less critical for a strictly offline single-player experience.

## Placement & Validation Logic
- **Grid System:** The building is a strict 2D coordinate grid (X, Y).
- When placing a room:
  1. Check if the cell(s) are empty within the 2D space.
  2. Check if the player has sufficient funds.
  3. Check if the building has sufficient utility capacity (Power/Water).
  4. If valid, deduct funds, update layout, recalculate building utility usage.

## Upgrade Logic
- Upgrading a room increases its Level by 1.
- Cost scales exponentially: `NextCost = BaseCost * (GrowthFactor ^ Level)`.
- Revenue scales linearly or on a custom curve.
