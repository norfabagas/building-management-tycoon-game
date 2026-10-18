# Game Rules & Mechanics

## Timestamp version and Sync — 2026-10-18

Sync updates application files only. It does not alter saves, five slots, time, economy or schema. Keep playing offline when checks fail; refuse activation while another same-scope game tab is open. See [AppVersionSync.md](AppVersionSync.md).

## Camera rotation and building actions — 2026-10-18

Map rotation and action hierarchy are presentation only. Twisting/rotating, opening upgrade review, closing panels and returning to floors do not purchase or alter land. Road connectivity, footprint dimensions, capacity, prices, limits, phases and five local save slots are unchanged. See [CameraAndActions.md](CameraAndActions.md).

## Small-device reachability — 2026-10-17

Mobile reachability changes only presentation: reviewing, scrolling, redraw and Cancel construction reserve no money. Confirm construction still revalidates placement, road access and the current balance through the existing domain transaction. Prices, capacities, construction timing, phases and five save slots are unchanged. See [MobileReachability.md](MobileReachability.md).

## Custom tenant release design — 2026-10-17

Reviewing or canceling a release is free and non-mutating. The explicit release action uses the existing vacancy rule, freeing reserved bays and retaining already accrued apartment rent. Keep all existing admissions, clock, income, limits and save rules. This changes presentation, not economy. See [TenantManagement.md](TenantManagement.md).

## Delete saved profiles — 2026-10-17

Deleting a saved profile requires an explicit district/slot confirmation and is permanent. Cancel makes no change. Successful deletion clears only that district, freeing its slot; a replacement starts with the normal empty-game rules. Old sessions cannot save into a deleted/replaced profile under the current client. No prices, limits, occupancy or clock rules change. See [DeleteProfiles.md](DeleteProfiles.md).

## Full-screen tenant activity — 2026-10-17

Tenant inspection is free and does not mutate the game. Time and business simulation continue in the full-screen interior. Daily routines are illustrative; saved occupancy, parking and catalogue income remain authoritative. Vacating still requires the existing confirmation and transaction, preserving accrued rent. Food courts expose dining floors rather than individual room leases. See [TenantInterior.md](TenantInterior.md).

## Volumetric figures and visible floors — 2026-10-17

A completed above-ground floor adds one visible storey. During a pending or canceled floor order the completed building retains its height. Basement, lift and luxury upgrades do not add above-ground storeys. These are presentation rules for existing saved floor counts; costs, capacity, construction durations and limits do not change. Outdoor models remain cosmetic and only appear at open businesses. See [VolumeAndHeight.md](VolumeAndHeight.md).


## Main road and district life — 2026-10-17

The user selected **Harus menempel jaringan jalan**. A new building's free one-tile ring must overlap or share an edge with the main highway or an already connected street. Diagonal-only contact and isolated streets do not count. No automatic connector is added for new construction. Building footprints and decorations cannot occupy highway/public-street tiles. The highway is a permanent two-tile strip extending along the x axis; new districts start at rows −3 and −2. It has no purchase price or maintenance. Existing costs, capacity, demand, synergy, opening and clock rules stay unchanged.

Preserve all existing buildings and progress: older districts receive free access streets routed around their plots and decorations. Cancellation still refunds the full unfinished purchase. Keep the canceled ring as public street only when another connected building needs it; otherwise remove its unshared road as before. Public streets remain land reservations. Walkers and vehicles are cosmetic and appear only around manually opened businesses, including businesses undergoing upgrades. They do not represent tenant counts or add income. See [DistrictRoads.md](DistrictRoads.md).


## Current override — 2026-10-16

The user subsequently approved the complete [four-type catalog](FigmaCatalogProposal.md) with “Setujui katalog usulan”. Catalog 2 supersedes the starter-only deferrals below: Apartment, Hotel, Office tower and Food court are available immediately; initial floors can be 1–10. Apply that document's exact prices, demand, parking allocation, luxury, needs, synergy, achievements, decorations and acceleration. The 24-hour clock, five profiles, local-only saves, taxes, manual opening, immediate purchase/refund and structural limits remain unchanged. Earlier “pending catalog” statements below are historical. Touchscreen navigation includes two-finger pinch zoom/pan, anchored at the moving focal point, with no accidental placement or selection.

The 2026-10-16 user request supersedes the five-second phase clock: one game day is 24 real seconds, with 1 game hour per second. Close the completed day's books exactly at 24:00, then begin the next day at 00:00. Preserve the internal Morning → Day → Afternoon → Night → closing order: four six-hour windows and an instantaneous closing event. Daily costs, construction day counts, Sunday rent, limits and immediate purchases/refunds are unchanged. Earlier Noon references below now mean the 24:00 closing.

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
