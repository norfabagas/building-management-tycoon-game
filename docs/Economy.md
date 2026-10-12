# Selected economy: Relaxed idle

The user selected **Option 1** on 2026-10-12, with one override: **apartment rent is paid weekly on Sunday at Noon; all other income is paid daily at Noon**. This document records the selected model and its settlement logic. [EconomyOptions.md](EconomyOptions.md) preserves the original comparison; Options 2 and 3 are not selected.

These are the gameplay rules for future implementation. The current app still has no wallet, construction, tenancy or financial simulation. Individual prices and upkeep coefficients remain unfinished; selecting the model does not turn the original illustrative starter amounts into a complete catalog.

## Time and billing calendar

- One in-game day lasts **5 real minutes**: Morning, Day, Afternoon, Night, then Noon (closing), with one minute per phase.
- Sunday means **in-game Sunday**, not the real device's weekday. Calendar convention: Day 1 is Monday; days 7, 14, 21 and so on are Sundays. `weekdayIndex = (day - 1) % 7`, with Monday at index 0 and Sunday at index 6.
- Hotel rooms, whole-floor office leases, F&B sales and parking receipts settle every day at Noon.
- Apartment rent accumulates for occupied game days and settles only at **Sunday Noon**, including that Sunday's occupancy. Pending rent is not available cash. Apartment-associated parking is still daily income.
- Maintenance and taxes remain payable every day at Noon, including apartment expenses on non-payment days.

## Capital, spending and construction

- Start a new profile with **$40,000**. After initialization, wallet changes occur only at Noon, or in the batch of missed closings applied on load.
- `Available = max(0, balance - reservedPurchases)`. Confirming a purchase reserves its complete quote immediately; projected income and pending apartment rent cannot fund a new reservation.
- At Noon, settle each queued purchase once: `balanceAfter = balanceBefore + cashGross - maintenance - tax - queuedPurchaseCosts`. Keep purchase costs separate from operating net in the finance statement.
- Construction begins at the next Morning after payment. The starter shell takes **2 game days**, followed by a separate **1-day B1 parking job**. The starter quote includes both jobs so the initial purchase can become usable.
- When successful placement turns empty land into an occupied construction site, automatically generate a road around the footprint, as confirmed by the user on 2026-10-12. Road space is outside the footprint and does not increase room or parking capacity. Any road price/upkeep remains undefined; this addition does not introduce an immediate wallet debit outside Noon.
- Underground levels start at zero when the shell finishes. No occupancy is possible without completed parking. Completed buildings/upgrades become operational at the following Morning; they do not earn a full day's income from a partial day.
- Release reservations if an unpaid order is canceled. Refunds after payment remain an open policy; do not implement them implicitly.
- Operating losses may make the balance negative. Keep simulation running and block purchases when available funds are zero. No automatic loans, grants or gem-to-dollar conversions.

## Capacity and demand

- One footprint tile represents **100 square metres**. Apartments/hotels reserve 25% of a floor for circulation/services: `roomsPerFloor = floor(0.75 * footprintTiles)`. Reject footprints that yield no rooms. Above-ground sizing stays immutable.
- `baysPerBasement = floor(2 * footprintTiles)`; `parkingQuota = baysPerBasement * completedBasements`, with no more than three basements. Underground is parking only.
- Apartments/hotels reserve one bay per occupied room. A whole-floor office lease requires `ceil(usableFloorArea / 50)` bays and cannot be partially admitted.
- F&B requires a bay per admitted visitor party. Limit simultaneous visitors by available bays and release visitor bays at the phase boundary. The turnover allowance per phase still needs a catalog value.
- Allocate tenant bays before visitors. Collect one daily fee per occupied tenant bay and one fee per admitted visitor visit; never sell a tenant-reserved bay again or charge twice for the same use.
- Apartments/offices use preset rents. Demand moves toward full parking-limited occupancy when basic needs are met, admitting up to **25% of eligible capacity per day**. Integer rounding and exact happiness thresholds remain tuning decisions.
- Hotels/F&B use a fixed daily demand pattern, modified by local population and happiness. Stairs-only high-rises retain the documented happiness penalty; lifts improve happiness but add substantial upkeep.
- Luxury has **three tiers**. Adjacent synergy bonuses add together and cap at **15%** per receiving building. Individual bonuses and adjacency distance remain to be defined; the old +30% office/F&B example is not a selected constant.
- Unlocks use cumulative earned revenue and remain permanent. Track earned apartment rent when accrued, once; its Sunday collection must not count it a second time. Thresholds and initial building availability remain to be defined; malls are future scope.

## Apartment rent ledger

Billing convention: rent is prorated by actual occupied game days, so moving in late in the week does not charge seven days and moving out before Sunday does not erase earned rent.

1. Store a preset **weekly rent** and a pending-rent ledger per apartment tenancy, plus the last processed closing ID.
2. At each Noon, add that day's occupied-room rent to the ledger, using the rate and eligible synergy for that day. Later upgrades or rate changes do not reprice prior accruals. A full seven-day tenancy earns the weekly rate before eligible modifiers.
3. On non-Sundays, apartment rent contributes **zero** to cash gross; retain its ledger as pending rent.
4. On Sunday, after adding Sunday's accrual, transfer all pending apartment rent into that closing's cash gross and clear the settled entries in the same saved transaction.
5. Preserve pending entries when a tenant leaves. They still settle on Sunday; prevent collecting them again if that room has a new tenant.

Use integer cents. Divide weekly rent into seven deterministic daily portions: `base = weeklyCents ~/ 7`, `remainder = weeklyCents % 7`; the first `remainder` weekdays (Monday onward) receive one additional cent. Round each day's modified amount once to the nearest cent, with half cents rounded up. Sum stored accruals for settlement rather than recomputing old days. This preserves the unmodified full-week total exactly.

Weekly rent values still need the price catalog. To preserve the original comparison's $120/day earning rate, its illustrative weekly equivalent is **$840 per room**, not $120 per week.

## Daily expenses and taxes

- Use low fixed upkeep coefficients by building type, floors, occupied units, parking, lifts and luxury. No wear system. The selected model sets the structure, not the unfinished coefficient table.
- `Tax = 0.0005 * completedBuildingValuation + 0.02 * cashGross`, assessed at every Noon. Round the valuation and revenue components separately to cents, then add them. Valuation excludes cash and unbuilt orders.
- Cash gross includes that day's hotel, office, F&B and parking receipts, plus apartment rent **only on Sundays**. The revenue tax on apartment rent is therefore collected on Sunday; the valuation tax and upkeep remain daily. Do not tax pending rent again when it is collected.
- `Operating net = cashGross - maintenance - tax`. Show pending rent separately from gross receipts and available cash.

## Offline settlement and persistence

- Use the saved game-day index and phase remainder to simulate missed time at five minutes per day, without an offline earnings cap. Device timestamps measure elapsed duration; they do not choose the game's weekday.
- Process missed days chronologically. Accrue apartment rent each occupied day and pay it on each crossed Sunday, including multiple weeks. If no Sunday is crossed, leave rent pending. Apply daily income, expenses and queued purchases on their scheduled closings.
- Save wallet, pending rent, completed closing IDs, paid orders, construction progress and calendar/clock state together before publishing success. The summary describes already-applied results, with no second claim action.
- If the device clock moves backward, apply zero additional time and keep the prior timestamp watermark until it catches up. Forward changes count as elapsed time under the offline local-clock rule.
- A failed save must retain the last successful snapshot and its pending-rent ledger; retry must not duplicate Sunday income. Select a durable full-game persistence strategy before implementing this transaction.

## Gems

Achievements grant gems once when completion is saved. Acceleration costs one gem per remaining game day, rounded up, with the quote shown before confirmation. Finishing a wait still activates the result at the next Morning. Decoration prices and achievement definitions remain catalog work. There are no ads, purchases or online monetization.

## Worked weekly cash-flow example

Illustrative mature starter only: six apartment rooms occupied all week, $840 weekly rent per room, $60 parking receipts each day, $80 daily upkeep and $20,000 completed valuation. No synergy or purchases. These are the original calibration anchors, not a finalized catalog.

| Closing | Apartment rent received | Parking | Maintenance | Tax | Operating net |
| --- | ---: | ---: | ---: | ---: | ---: |
| Each Monday–Saturday | $0 | $60 | $80 | $11.20 | -$31.20 |
| Sunday | $5,040 | $60 | $80 | $112.00 | $4,908.00 |
| Full week | $5,040 | $420 | $560 | $179.20 | $4,720.80 |

Weekly average net remains $674.40/day, as in the original relaxed-idle comparison, but actual cash arrives on Sunday. Six non-payment days incur $187.20 in net outflow; the finance panel must show the upcoming rent payment and reserve needs.

## Remaining implementation decisions

Finalize building/upgrade/decoration prices, weekly apartment rents and other daily rates, upkeep coefficients, happiness/lift formulas, demand rounding/turnover, synergy bonuses, non-starter construction durations, unlock thresholds, achievement definitions and paid-order cancellation/refunds. Automatic roads also need width/corner geometry, district-edge handling and a cost/upkeep decision. The UI must show an in-game weekday, apartment pending rent and the next Sunday closing. The approved Canva boards predate these rule updates; their daily-income examples remain illustrative and have not been edited in Canva for weekly billing or automatic-road placement.
