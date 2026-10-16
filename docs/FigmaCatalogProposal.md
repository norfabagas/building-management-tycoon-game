# Approved full-design catalog — 2026-10-16

The user explicitly approved this catalog on 2026-10-16 with “Setujui katalog usulan”. It fills values absent from the approved Figma boards and is now the implementation contract for catalog 2. Existing apartment rates, five save slots, local-only saves, midnight closing, immediate charging/refunds, taxes, footprint/road rules and level/lift caps remain unchanged. This overrides earlier starter-only deferrals; it does not make a claim that every feature is implemented yet.

## Four playable types

All four types are available at the start. A new building can select 1–10 initial floors; the immutable footprint and original purchase quote are saved. Parking B1 is always included and built after the shell. Initial shell duration is the per-floor duration below multiplied by initial floors; B1 takes one game day. Every type requires manual opening after completion. Later floors use the same per-floor rate and duration. Basements remain $500/tile, one day and $40/day upkeep. Lift prices remain one-quarter/one-half of that type's original **one-floor + B1** quote, with one day installation and $40/day upkeep each.

| Type | Shell price / tile / floor | Shell days / floor | Base floor upkeep / day | Revenue | Occupancy/demand |
| --- | ---: | ---: | ---: | --- | --- |
| Apartment | $2,000 (existing) | 2 (existing) | $40 (existing) | $840/room/week on Sunday | Existing 25% daily admissions, one bay/room |
| Hotel | $2,600 | 2 | $55 | $160/occupied room/day | Refresh guest demand each Morning to 75% of parking-limited rooms, rounded up |
| Office tower | $3,200 | 3 | $80 | $180 × footprint tiles / leased floor / day | Whole-floor leases only; 25% daily eligible-floor admissions, rounded up |
| Food court | $1,800 | 2 | $40 | $25/admitted visitor party | Concurrent party capacity = footprint tiles × completed floors, capped by free bays |

Apartments/hotels retain `floor(0.75 × tiles)` rooms per floor. One office lease occupies an entire floor and reserves `ceil(1.5 × tiles)` bays, as already defined by the usable-area rule. Food-court party demand per four six-hour windows is 25%, 75%, 100%, 50% of eligible concurrent capacity, rounded up; each window releases its visitor bays before the next. Visitor parking is $10 per admitted party, charged once per visit at daily closing. Tenant parking remains the existing $10 per reserved bay per day. New floors and basement capacity affect admissions only from the next Morning. Vacating an office lease frees the complete floor and its bays; hotel room actions apply to that room; F&B details show visits/sales rather than a fake apartment lease.

## Needs, luxury and synergy

- Happiness starts at 100. For floors above two, missing vertical access produces a 5-point penalty per additional floor, reduced by 10 points per standard lift and 10 for an executive lift; total penalty is capped at 30. Happiness scales new demand/admissions, not previously accrued apartment rent. Parking capacity remains a hard cap, not an invented extra cash penalty.
- Luxury tiers are 1–3. Each step costs 30% of the original construction quote, takes one game day, adds $20/day upkeep per completed floor, and increases new rent/sales accrual by 15% per tier above one. Existing pending apartment rent is not repriced. Luxury obeys the same one-job limit and unfinished-job full-refund rule.
- Buildings sharing compatible surrounding-road tiles are neighbors. Food courts receive +5% per neighboring apartment/office; apartments, offices and hotels receive +5% per neighboring food court. Bonuses add and cap at the existing 15%. Apply each day's bonus once to new rent/sales accrual, never retroactively to stored rent or parking fees.

## Achievements, gems and decorations

Achievements grant a saved, one-time reward: first business opened (1 gem), $1,000 cumulative earned revenue (3), all four types open (5), a ten-floor building (5), and seven completed daily closings (2). Evaluate actual saved progress and offline catch-up; failed/repeated writes cannot grant twice. Currency is earned locally; there is no purchase flow.

Cosmetic decoration prices: tree 2 gems, hedge 1, planter 1, bench 2, streetlamp 2, table set 3. Each occupies one free land tile outside buildings and required roads. Confirm placement before charging; canceling a preview is free. Decorations add no income, capacity or happiness. Moving one is free after valid-position confirmation; no gem resale/refund is introduced.

Acceleration uses the already documented one gem per remaining game day, rounded up, with a confirmation quote. It applies only to an active construction/upgrade job and activates completed work at the next Morning; initial buildings still require manual opening. Review must explain exactly which job is accelerated, its price and activation time.

## Presentation without additional balancing decisions

Use the existing artwork, room families, actor roles, lift modules and animation frames. Add reachable Build, Tenants, Upgrades, Finances, Achievements and Decorations flows, with touch/click controls and responsive panels. Audio defaults muted; an explicit sound control enables bundled local music/effects and saves the preference. Respect reduced motion. No new remote service or gameplay account is introduced.

Retain the user's newer 24-hour clock, midnight settlement and single Balance even though older Figma reference images show Noon, duplicate money or illustrative gems. No mall/VIP content is added; those remain future scope.
