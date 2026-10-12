# Game Rules & Mechanics

The user selected **Option 1: Relaxed idle** on 2026-10-12, with apartment rent paid **weekly on Sunday at Noon** and other income paid **daily at Noon**. [Economy.md](Economy.md) defines the selected model and billing conventions; [EconomyOptions.md](EconomyOptions.md) preserves the original alternatives. Economy simulation is not implemented yet.

## The Core Loop
1. **Name Your Area:** At the start of a new game, the player names their CBD area.
2. **Initial Capital:** The player starts with **$40,000** to construct their first building and its parking.
3. **Build & Expand:** Plan and construct new buildings on the map.
4. **Floor Management:** Manage the internal facilities and tenants within the established floors.
5. **Earn & Reinvest:** Collect daily net profit or cover losses at the end of each in-game day (Noon phase) and reinvest into new buildings or upgrades.

## Time System
- Progression is calculated in **Days**.
- Each day is divided into 5 distinct phases:
  1. **Morning:** Start of the daily cycle, tenants arrive or wake up.
  2. **Day:** Peak activity for offices and certain F&B.
  3. **Afternoon:** Shift in activity, preparations for evening.
  4. **Night:** Peak activity for hotels and residential areas.
  5. **Noon (Closing the book):** The final phase of the day where daily financial calculations (revenue, maintenance, tax) are finalized and profits/losses are committed to the player's balance.

- One game day lasts **5 real minutes**, with one minute per phase.
- Use an in-game Monday-to-Sunday week. Day 1 is Monday; every seventh day is Sunday. This calendar is independent of the device's real weekday.

## Economy & Finances
- **Primary Currency (Dollars $):** The main currency used for construction, upgrades, and paying expenses. The player's balance is strictly updated on a daily basis.
- **Hard Currency (Gems):** Earned via achievements (no online monetization dependencies). Used to speed up wait times or buy premium decorations.
- **Income schedule:** Apartment rent accrues for occupied days and is paid at Sunday Noon, prorated for partial weeks. Hotels, offices, F&B and parking pay daily at Noon, including parking attached to apartments.
- **Spending:** Purchases reserve funds immediately and settle once at the next Noon. Pending apartment rent and projected income are not spendable cash.
- **Maintenance Fees:** Low fixed coefficients by building type, floors, occupancy, parking, lifts and luxury, charged daily. Installing lifts adds heavy daily fees. Exact coefficients remain catalog work.
- **Taxes:** Daily tax is **0.05% of completed building valuation + 2% of cash gross received at that closing**. Apartment revenue tax is paid with Sunday rent; valuation tax remains daily. See Economy.md for rounding and valuation scope.

## Universal Building Constants
Regardless of the type of building constructed, the following constraints **always** apply without exception:
- **Land Area Requirement:** Every new building requires the player to manually define its physical footprint via a **drag-and-drop tool on the CBD map** before construction.
- **Underground Depth Limit:** No building can exceed a maximum of **3 underground levels**.
- **Standard Lift Limit:** A building can have a maximum of **3 standard lifts**.
- **Executive Lift Limit:** A building can have a maximum of **1 executive lift**.

## Building Construction & Upgrades
- **Custom Construction:** When purchasing a new building, the player selects the Type, defines the Land Area, and specifies the total number of *above-ground* floors. 
  - **Unit Density Check:** For partitioned buildings like **Hotels and Apartments**, the total number of units/rooms per floor is **automatically calculated and determined** by the physical size (land area footprint) of the building.
- **Automatic Surrounding Roads:** As confirmed by the user on 2026-10-12, when a new building occupies previously empty land, the game automatically creates a road around the occupied footprint. The player does not need to draw or place that road manually. Create it when the plot becomes an occupied construction site, not during an unconfirmed placement preview.
  - Roads sit outside the building footprint; they do not add room capacity or underground parking quota. Reuse compatible existing road segments instead of duplicating them, and never overwrite another building.
  - Placement review must preview the surrounding road and validate both the building footprint and required road space. Road width, district-edge handling and any road cost/upkeep still need definition; do not silently add a charge or assume roads may extend outside the district.
- **Permanent Above-Ground Sizing:** The above-ground physical size (land area, total floors, max unit capacity) is **locked** once constructed.
- **Underground Parking Expansion:** Through upgrades, players can excavate lower ground floors up to the universal max of 3 levels deep. These are strictly used for parking.
- **Vertical Logistics:** Buildings have stairs by default. Lifts must be purchased as upgrades (up to the universal limits) to improve efficiency.
- **Luxury Upgrades:** Players can upgrade existing buildings to increase their luxury rating.
- **Selected construction baseline:** Starter shell takes two game days, then a separate B1 job takes one day. Include both in the starter quote; occupancy remains zero until parking is operational.
- **Selected capacity:** Apartments/hotels use `floor(0.75 * footprintTiles)` rooms per floor; each basement supplies `floor(2 * footprintTiles)` parking bays. Full space/parking allocation rules are in Economy.md.
- **Selected progression:** Three luxury tiers; permanent unlocks based on cumulative earned revenue, with thresholds still to be defined.

## Building Mechanics, Uniqueness & Synergy
Each building possesses unique traits, and strategic placement on the map unlocks **Synergy Bonuses**:
- **Hotels:** Income based on daily room occupancy. Synergizes well with nearby Malls.
- **Apartments:** Long-term room rentals, paid weekly on Sunday at Noon for occupied days. Pending rent is retained if a tenant leaves before Sunday. Acts as a population driver for nearby businesses.
- **Office Towers:** Massive income based on entire floors rented to corporate tenants. Generates high daytime foot traffic.
- **F&B (Food Courts/Restaurants):** Income based on daily sales volume. *Synergy Example:* Placing an F&B building surrounded by Offices or Apartments will drastically boost its daily sales traffic and profit.
- **Underground Parking:** Generates daily revenue based on visitor traffic. High-attraction buildings will generate massive parking revenue. 

Selected synergy bonuses add together and cap at **15%** per receiving building. Individual adjacency bonuses remain to be defined; older +30% examples are not current balancing constants.

## Tenant & Visitor Management
- **The Parking Quota Hard Limit:** The total parking quota dictates the maximum possible occupancy of a building. If a building lacks sufficient parking, it cannot take in more tenants or visitors.
- Players must actively manage tenants. A lack of lifts in high-rises will drastically reduce tenant happiness.
- If tenant needs are not met, occupancy, rentals, and sales will decrease.
