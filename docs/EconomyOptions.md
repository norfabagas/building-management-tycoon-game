# Economy logic options

Status: **original comparison; Option 1 selected** on 2026-10-12. The user added a weekly apartment payment at Sunday Noon; other income pays daily at Noon. [Economy.md](Economy.md), [Rules.md](Rules.md) and [Logic.md](Logic.md) now define the selected contract. The original alternatives and calibration examples below are retained for context, not as competing active rules. The current app has no economy simulation.

The three options below differ in management depth. Option 2 was the original recommendation, but the user's selection is **Option 1**, with the apartment billing override recorded in Economy.md.

## Shared proposed logic

### Spending and daily closing

- Show three amounts: wallet balance, reserved purchases and available funds. `Available = max(0, balance - reservations)`.
- Confirming construction or an upgrade reserves its full quoted price immediately. Reject a purchase above available funds; do not count projected income as spendable cash.
- At the next Noon, settle each queued purchase once alongside the operating result: `balanceAfter = balanceBefore + gross - maintenance - tax - queuedPurchaseCosts`.
- Show construction/upgrade costs separately from operating net. `Operating net = gross - maintenance - tax` remains the documented formula.
- Construction begins the next Morning after payment. A completed building or upgrade becomes operational at the following Morning, so partial days never earn a full day's income. Canceling an unpaid order releases its reservation; refunds after payment need a separate rule.
- Initialize starting capital when creating the profile. After initialization, dollars change only at Noon or the documented batch of missed closings on load.

### First building, capacity and parking

- Keep underground levels at zero when the above-ground shell completes. The starter quote includes a separate B1 parking job and clearly shows its price and wait. No occupancy is allowed until B1 finishes. This avoids an unusable first purchase without adding undocumented external parking.
- Candidate geometry: one footprint tile represents 100 square metres. Apartments/hotels allocate 25% of each floor to circulation/services, then use one room per 100 usable square metres: `roomsPerFloor = floor(0.75 * footprintTiles)`. Reject footprints that produce zero rooms.
- Candidate parking geometry: `baysPerBasement = floor(2 * footprintTiles)`; `parkingQuota = baysPerBasement * completedBasements`. Preserve the three-basement limit.
- Apartments/hotels reserve one bay per occupied room. For offices, each whole-floor lease requires `ceil(usableFloorArea / 50)` bays. Reject a lease unless its full parking requirement fits; never create a partial floor lease.
- For F&B, use one bay per admitted visitor party. Each phase has a limited number of visits per bay; occupied bays release at the phase boundary. Daily admissions can exceed physical bays, but simultaneous demand cannot. The turnover allowance must be tuned per option before implementation.
- Allocate tenant reservations before visitor admissions. Charge one daily parking fee per occupied tenant bay; charge visitors once per admitted visit. Do not charge the same use twice or sell a reserved bay to a visitor.
- Above-ground capacity remains immutable. Stairs are free and present by default; lift upgrades improve happiness and add substantial recurring costs, within the documented limits.

### Accounting, offline time and losses

- Use integer cents, with one documented rounding rule per ledger entry. Store completed closing IDs, paid orders, construction progress and the clock remainder in the same game snapshot.
- Simulate missed phases/days using the chosen day duration, including construction, demand, upkeep and taxes. Publish one saved result and an already-applied summary; reopening it cannot pay again. Resume from the saved partial-day remainder rather than rounding every absence down independently.
- All three options retain the documented uncapped missed-day simulation. Do not silently introduce an earnings cap or omit offline losses.
- When the device clock moves backward, apply zero new elapsed time and retain the previous time watermark until it catches up. Forward changes count as elapsed time under the existing local-clock rule; tamper-resistant time is outside this offline design.
- Proposed loss handling: operating expenses may take the balance below zero. Block new spending while available funds are zero, keep the simulation running and show the causes of the loss. Do not add automatic loans, grants or dollar purchases with gems.
- Achievements grant gems once when their completion is saved. A proposed acceleration rule is one gem per remaining game day, rounded up, with the cost shown before confirmation; acceleration completes the wait but activation still occurs at the next Morning. Decoration prices require their own catalog. No online monetization.

## Option 1: Relaxed idle — selected

Best for short visits, predictable income and forgiving expansion.

- Starting capital: **$40,000**. One game day: **5 real minutes**, divided equally across the documented five phases.
- Construction: starter shell **2 game days**, then B1 **1 day**. Prices use a fixed quote by type, footprint and floor count.
- Apartments/offices use preset rents. Demand moves toward full parking-limited occupancy when basic needs are met; admissions fill up to 25% of eligible capacity per day. Hotels/F&B use a fixed daily demand pattern, modified by local population and happiness.
- Selection override: apartment rent accumulates for occupied days and pays weekly on **in-game Sunday Noon**; office, hotel, F&B and parking income pay daily at Noon. Expenses remain daily. See Economy.md for partial weeks, taxes and offline settlement.
- Upkeep uses a low fixed cost per building, floor, occupied unit and lift. No wear system. Stairs-only high-rises still suffer the documented happiness penalty.
- Tax: `0.05% of building valuation + 2% of gross revenue`, assessed daily. Parking revenue is included in gross; valuation excludes cash and unbuilt orders.
- Luxury has three tiers with preset income and upkeep increments. Approved adjacent synergies add together, capped at **15%** per receiving building.
- Proposed unlocks use cumulative earned revenue, so a difficult day cannot relock a building type.

Tradeoff: easy to understand and tune, but rent-setting and operating decisions have less depth.

## Option 2: Balanced tycoon — not selected

Best for an idle game where parking, tenants and upgrade timing materially affect profit.

- Starting capital: **$30,000**. One game day: **10 real minutes**, divided equally across the documented five phases.
- Construction: starter shell **4 game days**, then B1 **2 days**. Quotes separate shell, parking and optional upgrades, with projected recurring costs beside each.
- Offer three rent presets: economy (**90%** of benchmark), standard (**100%**) and premium (**115%**). Their initial demand targets are **100%, 85% and 65%** of eligible capacity, multiplied by `happiness / 100`. Move toward the target by at most 20% of physical capacity per day, with at least one unit when a change is possible. Offices adjust only whole leases that fit the parking budget.
- Apartments/offices retain their leases until a daily satisfaction/affordability decision removes them. Hotels reevaluate rooms daily. F&B derives phase demand from nearby occupied apartments and offices, then applies parking admission limits.
- Upkeep: `typeBase + floorCost + occupiedUnitCost + parkingLevelCost + liftCost + luxuryCost`. Each building type has its own coefficients; lifts must represent a visible, substantial expense.
- Tax: `0.10% of building valuation + 3% of gross revenue`, assessed daily. Valuation counts completed shell and upgrades at purchase cost, excluding cash and queued jobs.
- Luxury has three tiers. Synergies add together and are capped at **30%** per receiving building; the docs' office/F&B +30% example remains illustrative until the individual bonus table is approved.
- Proposed unlocks combine sustained occupancy and positive operating results across several days. Once unlocked, a type stays unlocked.

Tradeoff: requires careful demand tuning, but gives the player understandable choices without a large economic subsystem.

## Option 3: Detailed management — not selected

Best for players who want to adjust prices and study operating performance.

- Starting capital: **$28,000**. One game day: **15 real minutes**, divided equally across the documented five phases.
- Construction: starter shell **6 game days**, then B1 **3 days**. Each project uses the same full-price reservation and settlement logic; completion waits are longer.
- Allow rents/prices from **50% to 200%** of a benchmark. A candidate demand curve is `eligibleCapacity * clamp(1 - elasticity * (priceRatio - 1), 0, 1) * happiness / 100`. Elasticity differs by building type. Lease turnover is bounded per day; hotels and F&B have demand profiles per phase.
- Upkeep includes type, floor, occupancy, parking, lift and luxury costs plus utilization-dependent service costs. High traffic can raise both revenue and expenses. Do not add staff, breakdowns or repairs without separate scope approval.
- Tax: `0.20% of building valuation + progressive gross-revenue tax`. Candidate daily revenue brackets: **4%** on the first $1,000, **6%** on the next $4,000 and **8%** above $5,000. Brackets apply to the CBD total and are marginal, not a single rate on all revenue. Allocate the revenue tax to buildings in proportion to their gross for the finance panel.
- Luxury has five tiers. Synergies cap at **40%** and reduce as nearby visitor capacity saturates; increased demand never bypasses parking limits.
- Proposed unlocks combine occupied capacity, tenant happiness and sustained operating profit. Unlocks remain permanent.

Tradeoff: deeper planning, more UI explanations and a larger balancing/testing burden. This is better suited to a later depth update than the first playable MVP.

## Comparable starter example

This is a **mature, fully occupied** apartment example from the original comparison, not a promise of immediate earnings. Its apartment amounts are daily earning equivalents, not daily payments. The selected Option 1 now collects them on Sundays; Economy.md contains the actual weekly cash-flow example. Occupancy growth, construction time and weekly collection extend actual cash payback.

Common starter: a 2-by-2 footprint, two above-ground floors, three rooms per floor, six rented rooms, one completed basement with eight bays, no lifts, base luxury and 100 happiness. The proposed all-in quote and valuation are **$20,000**. Six tenant bays each pay **$10/day**. No synergy applies. Option 2 uses the economy preset against a $111.11 benchmark, giving a $100 realized rent after rounding; Option 3 uses its $100 benchmark. Both therefore allow the full-occupancy comparison under their proposed demand rules.

| Daily-equivalent item | Relaxed idle | Balanced tycoon | Detailed management |
| --- | ---: | ---: | ---: |
| Rent per occupied room | $120 | $100 | $100 |
| Room revenue | $720 | $600 | $600 |
| Parking revenue | $60 | $60 | $60 |
| Gross revenue | $780 | $660 | $660 |
| Total upkeep, illustrative | $80 | $120 | $240 |
| Tax using each option's formula | $25.60 | $39.80 | $66.40 |
| Operating net | $674.40 | $500.20 | $353.60 |
| Simple cost / mature daily net | 29.7 days | 40.0 days | 56.6 days |

The $20,000 quote and aggregate upkeep amounts are calibration anchors. They do not define every building/upgrade price or maintenance coefficient. Those catalogs must be written and checked against the selected model before implementation.

## Selection and remaining decisions

The user chose **Option 1** with Sunday apartment rent. The selected shared settlement logic and Option 1 parameters are recorded in Economy.md. Options 2 and 3 remain historical alternatives.

Rules.md/Logic.md and the design/setup gates now refer to the selection. Finalize the price/maintenance catalog, weekly apartment rent values, happiness and lift formula, F&B turnover, synergy adjacency/bonuses, construction duration scaling, unlock thresholds, achievement catalog and refund policy. Initial playable building availability is a separate scope decision; malls remain future content. The selected model is documented but not implemented.
