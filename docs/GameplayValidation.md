# Gameplay validation — 2026-10-16

## Review standard

The audit follows the approved catalog and the sixteen archived design boards. A tycoon loop must let a player compare businesses, commit limited cash and land, wait for construction, deliberately open, see actual demand/parking/revenue, then reinvest. Illustrations or placeholder counters alone do not satisfy this. The review also checks save durability, responsive navigation and feedback that does not move the controls.

Avoid generic promotional copy, arbitrary extra metrics, decorative dashboards and promises of guaranteed profit. Reuse the approved artwork, BM mark, colors and tactile controls. Explain the specific investment consequence at the point of purchase. “No AI slop” is a qualitative design criterion, not an automated certification or a claim that the source illustrations were made without AI.

## Findings and fixes

| Finding | Decision and verification |
| --- | --- |
| A type card quoted construction but omitted the actual earning rate and B1 surcharge. | Show the approved base revenue, collection cadence and separate parking construction rate/time. No invented ROI or guaranteed occupancy. |
| A multi-floor purchase could look fully usable even when B1 could not serve every unit. | Review shows B1-supported capacity versus total capacity, remaining cash, upkeep and demand/tax caveat before confirmation. A two-floor 2×2 Office example explicitly shows 1 / 2 floor leases and $12,400 remaining. |
| Generic metadata displaced the selected floor and artwork. | Put the floor and larger room cutaways before building-wide accounting; place footprint, counts, luxury, needs and synergy in a persistent expandable Building details section. Warnings and active-job actions remain visible. Opening a business resets the floor scroll position so the new rooms start in view. |
| Landscape HUD consumed much of the available floor view. | At widths ≥600 with a short body, use one compact HUD row, retaining one Balance, clock, weekday and gems. In short landscape layouts with at least 700 px of detail width, put the overview beside the floor. Keep the requested fixed floor controls and Web footer clearance. The selected-floor viewport exceeds 135 px at 844×390; its content scrolls. |
| A completed building could be missed on a portrait map, whose sidebar is hidden. | Add an Open [building] map shortcut for the first completed unopened business. It opens review; the player still explicitly presses Open to Business. It never grants early occupancy or income. |
| Cash-closing animation temporarily changed the map's height. | Render the one-shot coin over the fixed Balance icon, preserving layout and reduced-motion behavior. |
| Offline revenue repeatedly rebuilt unchanged neighbor road geometry. | Cache synergy only inside one synchronous advance, then clear it in finally. No saved cache, new schema, timing cap, skipped closing or price change. A 365-game-day phase-by-phase comparison checks the whole serialized state; placement/cancellation after catch-up checks invalidation. |

## Performance evidence

An opening-economy audit starts each type independently with $40,000, buys one 2×2 single-floor building, opens immediately when completed, then advances 28 closings with no other purchases, bonuses or player interventions. Apartments, Hotel and Food Court can open on Day 5; Office on Day 6. All retain positive cash throughout. Cash at the start of Day 29 is $36,239.40 / $36,505.20 / $38,872.80 / $36,530.40 respectively; apartment receivables have just cleared on Sunday. These are deterministic scenarios, not a promised return or an assertion that the catalog is optimally balanced. The distinct collection cadences, parking constraints, construction waits and reinvestment costs remain real decisions.

An ignored Dart JIT benchmark advances an evenly spaced mixed district through 30 real days, equivalent to 108,000 game-day closings at the approved speed. Four businesses took 7,569 ms before and 557 ms after; twenty took 90,186 ms before and 1,482 ms after. Both versions produced the same final balances (17,188,581,720 and 85,926,908,600 cents respectively), eleven earned gems and 108,000 closings. Repeating the same watermark changed no cash. These workstation measurements are indicative, not a Web/mobile latency guarantee; chronological simulation still grows with elapsed time and business count.

## Coverage and limits

Final checks: 52 Dart files formatted, `flutter analyze --no-pub`, 132 tests, the release Web build with 201 offline resources, and asset validation (158 resources / 124 frames). Android debug build was attempted and reports No Android SDK found. The build script now explicitly names `lib/main.dart` as its production target. Release publication is verified separately in Deployment.md.

Domain coverage includes all four admission/income models, weighted parking, Sunday accrual/collection, luxury, happiness, shared-road synergy, upgrades, one-time achievements, gem purchases/refunds, decoration moves, legacy migration, rollback and repeated/backward clocks. UI coverage exercises purchase/refund, tenant/floor navigation, upgrade/acceleration review, responsive controls and simultaneous pinch pointers. New usability checks cover the completed-building shortcut, details disclosure, minimum landscape viewport and investment review without a debit.

Browser review uses an isolated localhost origin and disposable QA district. Production player data is untouched. The first-play path includes creation, drawing, purchase, construction, explicit opening, admissions, daily costs, pending rent and Sunday collection; the same district is reopened after updating the bundle to check local persistence. Final release/test/publication evidence is recorded in Deployment.md.

Live Figma inspection and native component atomization remain blocked by the Starter MCP quota. The approved archive supports this assessment, not certification of unknown live-file edits. Android compilation/device, physical pinch/speaker quality and a disconnected-browser run remain unverified on this workstation. No economy rebalance, new unlock gate, marketing overlay or network gameplay service was introduced.
