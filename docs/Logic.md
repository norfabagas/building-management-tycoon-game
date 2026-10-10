# Game Logic & Architecture

## Game State & Data Models
- **Building:** Holds a grid/list of Room objects, tracks total capacity, total power usage, and total water usage.
- **Room:** Attributes include `id`, `type`, `level`, `cost`, `baseRevenue`, `collectionTime`, `powerDraw`, `waterDraw`.
- **Tenant:** Attributes include `id`, `happinessLevel`, `assignedRoom`.

## Idle Generation Logic
- The game uses a time-based delta generation system.
- `Revenue = BaseRevenue * LevelMultiplier * HappinessModifier`
- When offline, the system records the `lastLoginTime`. Upon next login, `offlineEarnings = (currentTime - lastLoginTime) * (Revenue / collectionTime)`. (Capped at a maximum offline time limit, e.g., 12 hours).

## Placement & Validation Logic
- **Grid System:** The building is a 2D grid `(X, Y)`.
- When placing a room:
  1. Check if the cell is empty.
  2. Check if the player has sufficient funds.
  3. Check if the building has sufficient utility capacity (Power/Water).
  4. If valid, deduct funds, update grid, recalculate building utility usage.

## Upgrade Logic
- Upgrading a room increases its Level by 1.
- Cost scales exponentially: `NextCost = BaseCost * (GrowthFactor ^ Level)`.
- Revenue scales linearly or on a custom curve.
