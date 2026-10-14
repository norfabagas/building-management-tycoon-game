# Game Rules & Mechanics

The user selected **Option 1: Relaxed idle** on 2026-10-12, with apartment rent paid **weekly on Sunday at Noon** and other income paid **daily at Noon**. The apartment starter and automatic-road geometry were approved next; on 2026-10-14 the user replaced the one-floor restriction with floor, basement and lift upgrades defined below. [Economy.md](Economy.md) defines the selected catalog; [Gameplay.md](Gameplay.md) records implementation. Hotel, office, F&B, luxury and happiness systems remain pending. [EconomyOptions.md](EconomyOptions.md) preserves the original alternatives.

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

- As requested on 2026-10-14, phases change every **5 real seconds**. A game day lasts **25 seconds**. Phase order and per-game-day economy remain unchanged.
- Use an in-game Monday-to-Sunday week. Day 1 is Monday; every seventh day is Sunday. This calendar is independent of the device's real weekday.

## Economy & Finances
- **Primary Currency (Dollars $):** The main currency used for construction, upgrades, and paying expenses. Show one Balance. Purchases deduct it immediately and cancellations refund it immediately; operating income/expenses still settle daily.
- **Hard Currency (Gems):** Earned via achievements (no online monetization dependencies). Used to speed up wait times or buy premium decorations.
- **Income schedule:** Apartment rent accrues for occupied days and is paid at Sunday Noon, prorated for partial weeks. Hotels, offices, F&B and parking pay daily at Noon, including parking attached to apartments.
- **Spending:** Confirming a building or upgrade deducts its entire price immediately from Balance. Cancel a building before opening or an unfinished upgrade for an immediate full purchase refund. No second purchase/refund debit occurs at Noon. Pending apartment rent and projected income are not spendable cash.
- **Maintenance Fees:** Daily fixed coefficients. Starter apartments use $40 per completed floor plus $40 per completed basement; other types, lifts and luxury remain catalog work.
- **Taxes:** Daily tax is **0.05% of completed building valuation + 2% of cash gross received at that closing**. Apartment revenue tax is paid with Sunday rent; valuation tax remains daily. See Economy.md for rounding and valuation scope.

## Universal Building Constants
Regardless of the type of building constructed, the following constraints **always** apply without exception:
- **Land Area Requirement:** Every new building requires the player to manually define its physical footprint via a **drag-and-drop tool on the CBD map** before construction.
- **Underground Depth Limit:** No building can exceed a maximum of **3 underground levels**.
- **Above-Ground Limit (2026-10-14):** Buildings can expand upward to **10 total above-ground floors** for now.
- **Standard Lift Limit:** A building can have a maximum of **3 standard lifts**.
- **Executive Lift Limit:** A building can have a maximum of **1 executive lift**.

## Building Construction & Upgrades
- **Custom Construction:** When purchasing a new building, the player selects the Type, defines the Land Area, and specifies the total number of *above-ground* floors. 
  - **Unit Density Check:** For partitioned buildings like **Hotels and Apartments**, the total number of units/rooms per floor is **automatically calculated and determined** by the physical size (land area footprint) of the building.
- **Automatic Surrounding Roads:** As confirmed by the user on 2026-10-12, when a new building occupies previously empty land, the game automatically creates a road around the occupied footprint. The player does not need to draw or place that road manually. Create it when the plot becomes an occupied construction site, not during an unconfirmed placement preview.
  - Roads sit outside the building footprint; they do not add room capacity or underground parking quota. Reuse compatible existing road segments instead of duplicating them, and never overwrite another building.
  - Placement review previews and validates both the footprint and surrounding road. The approved starter uses a free one-tile rectangular ring including corners on unbounded land, merging shared road segments. Existing roads cannot become building footprints; road rings cannot overwrite occupied plots.
- **Permanent footprint:** Land area, coordinates and rooms per floor are locked. As requested on 2026-10-14, above-ground floors can be added through upgrades, up to 10 total, superseding the earlier permanent-floor/starter restriction. Each building starts with one floor and B1; caps include these initial levels.
- **Underground Parking Expansion:** Through upgrades, players can excavate lower ground floors up to the universal max of 3 levels deep. These are strictly used for parking.
- **Vertical Logistics:** Buildings have stairs by default. Lifts must be purchased as upgrades (up to the universal limits) to improve efficiency.
- **Apartment upgrade catalog (2026-10-14):** Added floor: $2,000/tile, 2 game days, +$40/day upkeep. Added basement: $500/tile, 1 day, +$40/day. Standard lift: 1/4 of the original floor+B1 quote; executive lift: 1/2. Both lifts take 1 game day and add $40/day each. The user approved this price basis and deferred lift rent/happiness effects. One job per building; charge on confirmation, queue through the next Noon, begin the following Morning. Keep existing business open. Completed capacity and upkeep/valuation apply at completion; new admissions wait until Morning and remain parking-limited. Cancel any unfinished upgrade for a full immediate purchase refund; completed upgrades cannot be canceled.
- **Luxury Upgrades:** Players can upgrade existing buildings to increase their luxury rating.
- **Selected construction baseline:** Starter shell takes two game days, then a separate B1 job takes one day. Include both in the starter quote; occupancy remains zero until parking is operational.
- **Manual opening (2026-10-14):** When both jobs finish, construction reaches 100% and the building waits for **Open to Business**. No tenants, new rent accrual or parking income before this action. Admissions begin at the next Morning after opening. Completed components still incur their documented maintenance/valuation taxes. Existing open buildings remain open after upgrade; no new price, refund or automatic opening is introduced.
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
- Players must actively manage tenants. The future happiness system will account for high-rise lift needs; its penalty/bonus formula is deferred for this apartment upgrade release, as approved on 2026-10-14.
- If tenant needs are not met, occupancy, rentals, and sales will decrease.
