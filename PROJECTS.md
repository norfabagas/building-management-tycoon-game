# Building Management Tycoon

## Full-screen tenant activity — 2026-10-17

Tenant/room taps now open a full-screen interior with live saved status and role-specific ambient routines. All four types, vacant units, food-floor party allocation, management confirmation and return navigation are covered. See [TenantInterior.md](docs/TenantInterior.md) for decisions and validation.

Source `74c7df9` is pushed and published as ready/current deploy `6ad3196f794639eb74f70734` at 13:45 WIB. All 182 Flutter tests, six worker tests, format/analyzer/assets and the 201-resource normal-entry Web build pass. Primary release-file hashes match. Browser review preserves the existing QA save and verifies four-type navigation plus responsive final interiors. Android SDK/device and remote CI remain verification limits. See [Deployment.md](docs/Deployment.md).

## Volumetric characters and visible upward upgrades — 2026-10-17

Outdoor people and cars now use rotating, shaded XYZ geometry. Per-actor depth masks preserve front-side bodies and hide traffic behind nearer facades. Exteriors assemble approved ground/upper-storey texture bays on every footprint, with height tied to completed above-ground floors. Pending/canceled jobs and basement/lift upgrades keep their height. No schema/economy change or large art/dependency is added. See [VolumeAndHeight.md](docs/VolumeAndHeight.md).

Source `430a65d` is pushed and published as ready/current deploy `6ad2ef4d222e81a20dff8c6b` at 10:45 WIB. All 169 Flutter tests, six worker tests, formatter/analyzer/assets and the 201-resource normal-entry Web build pass. Primary hashes match. Actual QA UI purchase/completion raises Apartment 1 from one to two storeys; Floor 2 has Room 5–8 and six gems are retained. Android SDK/device and remote CI remain verification limits.


## Connected district roads and ambient traffic — 2026-10-17

A permanent main highway and connected-ring placement now govern expansion. Old districts receive safe, free access around saved plots/decorations. Cancellation refunds fully while retaining streets needed by neighbours. Open businesses display matching walkers and cars on rounded footprint routes; separate scene layers prevent traffic appearing over facades. Reduced motion/hidden maps pause activity. No economy or runtime-art bytes changed; schema 8 persists compact public roads. See [DistrictRoads.md](docs/DistrictRoads.md).

Source `536b967` is pushed and published as ready/current Netlify deploy `6ad2d6e98259b8bde2676b0a` at 09:01 WIB. All 152 Flutter tests, six offline-worker tests, format/analyzer/assets and the 201-resource Web build pass. Primary bundle/worker/manifest hashes match; the normal production bundle preserves and connects the old two-business QA profile. Android SDK/device and remote CI remain verification limits. See [Deployment.md](docs/Deployment.md).


## Follow-up self-test — 2026-10-17

Reproduced and fixed an equal-price acceleration race: an old shell dialog could accelerate the new B1 job after midnight. The domain now validates the reviewed building/job/start-day identity and price after catch-up; UI captures that identity before opening a scrollable dialog. Six new regressions cover shell/B1, repeated upgrades, rollback/retry and three viewport sizes. Six Node tests cover offline-worker cache, navigation, update isolation and failure behavior; Actions runs them too. See GameplayValidation.md and Deployment.md for current results, publication and limits.

All 138 Flutter tests, six Node checks, analysis, formatting, assets (158 / 124 frames) and the 201-resource Web build pass. Source `09b94c2` is published as ready/current Netlify deploy `6ad2c2de88dc491506049c15` at 07:35 WIB. Primary bundle/worker/manifest match the tested build. Live QA confirms a stale shell review cannot spend the six gems on B1 and Retry restores normal play. Android SDK/device and live Figma/native atomization remain verification limits.

## Gameplay quality audit — 2026-10-16

The [audit](docs/GameplayValidation.md) fixes investment clarity, B1-limited capacity review, selected-floor hierarchy, short-landscape usability, portrait opening discovery and layout-stable cash feedback. It retains the approved art, offline five-slot saves, 24-second days and catalog values. A transient synergy cache removes repeated geometry work during chronological offline advancement: the 20-business/30-real-day local benchmark improves from about 90 seconds to 1.5 seconds with identical final cash/gems/closing count. No new schema, economy adjustment or runtime artwork is introduced.

Formatting of 52 Dart files, analysis, all 132 tests, asset validation (158 resources / 124 frames) and the 201-resource Web release pass. The production build explicitly targets `lib/main.dart`; review fixtures remain ignored. Browser review retains the QA save across the update and checks actual admissions/rent/costs, portrait/landscape presentation and purchase consequences. Android SDK/device verification and live Figma/native atomization remain unavailable. See Deployment.md for verified publication evidence.

Published source `1cf74ae` as ready/current Netlify deploy `6ad24326f0a099547884454c` at 22:30 WIB. Primary JavaScript/worker/manifest return 200 and match the tested build; the isolated deploy origin starts with five slots. Close/reopen installed updates while retaining site data. See Deployment.md for hashes and review limitations.

## Four-type Figma implementation — 2026-10-16

The user approved [catalog 2](docs/FigmaCatalogProposal.md). Apartment, Hotel, Office tower and Food court now have distinct behavior, initial-floor selection, correct artwork/actors, parking allocations, income, luxury, needs, synergy, achievements/gems, decorations, active-job acceleration, local audio and motion. [FigmaAssessment.md](docs/FigmaAssessment.md) maps all 16 board topics to code/tests and documents the limits of quota-blocked live Figma/native component inspection.

Schema 7 migrates saves after original-catalog catch-up, preserving balances, pending rent and progress. All five slots remain local. Type-aware directories, reviewed purchases/refunds, a copy-only financial forecast and two-finger pinch/pan work across responsive layouts. The unchanged runtime pack remains in Git; large originals and review screenshots stay archived/ignored. The user requested GitHub push and existing-site Netlify deployment; the release record is in Deployment.md after final checks.

Source `5658c22` is pushed and published as ready/current deploy `6ad23abd9abc018af77fbd70` at [bmt.niceblue.biz.id](https://bmt.niceblue.biz.id). All 127 tests, formatting, analysis, assets and the 201-resource offline Web build pass; hosted bundle/worker/manifest bytes match. Browser startup confirms five local slots. Android build is blocked by the missing SDK; live Figma/native atomization remains quota-blocked. See [Deployment.md](docs/Deployment.md) and the [self-assessment](docs/FigmaAssessment.md).

## Rectangular buildings, 24-hour time and smooth daylight — 2026-10-16

Rectangular apartments now extend along both actual footprint axes, repeat the approved facade bays and use a proportional roof with a compact service unit. Square plots keep the original approved sprite. Geometry, labels and click bounds follow the plot rather than a square image size. No artwork bytes, costs or capacities changed.

One game hour equals one real second. The 24:00 event closes the completed day before calendar rollover and new-day admissions. Schema 6 first catches legacy offline time up at its saved 5/60-second cadence, then migrates phase fractions; previously closed legacy Noon advances without duplicate settlement. Daily/Sunday billing, immediate purchases/refunds and level limits remain intact. Daylight uses cyclic, directional color gradients with 800 ms interpolation; midnight does not animate backward through the day.

All 81 tests pass, covering clock migration, exact closing boundaries, Sunday rent, offline parity, rollback, responsive controls, elongated geometry in both axes and midnight lighting interpolation. Asset validation remains 158 files/124 frames. Android build remains blocked by the absent SDK. See Setup.md and Deployment.md for final build/publication checks.

Published source `1fcb976` as ready Netlify deploy `6ad1bcb716eba45303af59bb`. Production JavaScript, service worker and offline manifest match the validated release Web build byte-for-byte (201 offline resources). The clock/geometry subset passes all 15 tests. See [Deployment.md](docs/Deployment.md) for hashes, review limits and update activation.

## Figma migration and rebuild — 2026-10-16

Moved all 348 repository graphics into the new [Figma design archive](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ), organized within the Starter plan's three-page limit. All nodes and aspect ratios were verified. Removed 73 large design/reference files (35.28 MiB) from the tracked tree while keeping runtime assets, the unchanged BM master and authoring tools. The manifest records source hashes, node links and PPTX recovery; [DesignArchive.md](docs/DesignArchive.md) documents raster-board limitations, source restoration and retained Git history.

Formatting, analysis, all 75 tests, full restored-source validation (158 assets/124 frames) and the release Web build (201 offline resources) pass. Source restoration from Figma was tested byte-for-byte. Android build is blocked by the missing SDK. After user CLI authorization, source `6eb2f54` was published as ready deploy `6ad1b64af7f7b6f53f19e3f8` at [bmt.niceblue.biz.id](https://bmt.niceblue.biz.id). Hosted JavaScript, service worker and offline manifest return HTTP 200 and exactly match the tested local files. See [Deployment.md](docs/Deployment.md). Work uses ignored `.tools/release-workspace/` because the older checkout/SDK has incompatible Windows ACLs.

## Contract and implementation

Read `docs/Project.md`, `docs/Platform.md`, `docs/Rules.md`, `docs/Logic.md` and `docs/Design.md` before changing behavior. The approved design, BM identity and runtime asset contracts live in `docs/DesignKit.md`, `docs/Assets.md` and `assets/game/manifest.json`.

Flutter/Dart targets Android and Web, portrait and landscape, with MVVM and five entirely local save slots. Apartments start with one floor and B1 parking. The 2026-10-14 upgrade request supersedes the earlier fixed-floor restriction: allow up to 10 above-ground floors, 3 basements, 3 standard lifts and 1 executive lift per building. Luxury and other building catalogs remain pending.

## Single balance and immediate payments — 2026-10-14

- The user's money feedback supersedes the previous reservation/Noon-payment rules. Show one **Balance** chip and the clock in the HUD. Remove Dollars, Available and pending-rent chips, duplicate build/upgrade wallet rows and reservation totals. Keep uncollected rent and historical earnings in financial detail; they cannot fund purchases. Offline summaries label their difference Net change rather than Balance.
- Confirming any building or upgrade immediately deducts its complete price from `DistrictGame.balance`, atomically with the order/site. Validate affordability against that same balance; no separate available/reserved money exists. Preserve the existing construction queue schedule and phase order: next Noon advances the order to its start-wait stage, then construction begins the following Morning. Noon never deducts the purchase again.
- **Cancel building** remains available until opening, including during shell/B1 work and the completed-but-closed stage. It immediately refunds the original floor+B1 quote, removes the site and its unshared roads, and retains operating costs already incurred. Open buildings cannot be canceled. **Cancel upgrade** refunds its complete price immediately at any unfinished stage, preserves existing tenants/rent/completed counts, and removes the order. Completed upgrades cannot be canceled. Repeat attempts cannot refund twice.
- Save schema 5 migrates schemas 1–4 before catch-up: deduct each legacy queued building/upgrade quote exactly once, leave previously paid work alone, then persist with the migration/action in the existing transaction. Preserve clock-speed migration, level/lift counts, initial opening state, rooms and rent. Failed writes/cancellations preserve the source snapshot. Older clients reject schema 5.
- Persist purchase/refund amounts since the previous closing. Copy them into the next statement for history and clear the counters; do not debit/credit the wallet again. Refunds do not increase earned revenue or taxable cash gross. Operating income, upkeep and taxes retain their existing daily/Sunday schedule.
- All 75 tests pass, including immediate wallet/UI updates at three viewport sizes, refunds at every pre-opening construction stage and all unfinished upgrade stages, no duplicate debit/refund, non-taxable refund history, legacy queued/paid migration, rollback, limits and offline parity. The final money/UI subset also passes all 23 tests. Formatting, Flutter analysis, asset validation (158 resources/124 frames) and the release Web build (201 offline resources) pass. Android debug compilation was attempted and remains blocked by the missing SDK.
- An ignored in-memory browser fixture verified $40,000 → $30,000 on confirmation of a $10,000 building, then $30,000 → $40,000 immediately when canceled during shell construction. The next closing kept $40,000 and recorded the refund with zero income/tax; financial detail has no duplicate wallet. Evidence: `docs/images/immediate-building-charge.jpg`, `immediate-building-refund.jpg` and `single-balance-finances.jpg`. The temporary review tab/server are closed; production player data was not changed.

The earlier upgrade and release notes below retain historical validation; the immediate-payment contract above takes precedence over their reservation/payment wording.

Source `550bf01` is pushed to GitHub and published as Netlify deploy `6acf193d578dc06d1622110b`. The connector confirms current/ready. Production JavaScript matches the tested release (`E991772342C1ADB544EFDDAFD522C72322885C051025E0E29468C459A9406D65`); the live offline manifest returns HTTP 200 with 201 resources. See Deployment.md. Close older tabs and reopen without clearing site storage to activate schema 5.

## Building upgrades — 2026-10-14

- **Upgrade building** appears beside the building title, including while initial construction is unfinished. Its menu shows all four upgrade types, current/maximum counts, cost, added daily upkeep, construction time and a review/confirmation step. Buying requires an open building; show disabled states for construction, an active job, insufficient available funds and the maximum. One upgrade runs per building; separate buildings may upgrade concurrently. Unpaid upgrades can be canceled.
- The user approved existing level rates and times: each added floor costs $2,000 per footprint tile, takes 2 game days and adds $40/day upkeep; each added basement costs $500/tile, takes 1 day and adds $40/day upkeep. A standard lift costs 1/4 of the original floor-plus-B1 construction price; an executive lift costs 1/2. The user confirmed this original-price basis, $40/day upkeep per lift and 1 game day installation, with rent/happiness effects deferred. Do not apply an invented stairs penalty or lift bonus.
- Reserve the quote immediately, pay once at the next Noon, start next Morning, and complete at Noon on the final construction day. Existing tenants and business remain open. Completed upgrades immediately add valuation/upkeep; new rooms admit tenants next Morning subject to total parking capacity. Initial construction still requires manual **Open to Business**; upgrades do not close an already-open building. Map and building detail show upgrade percentage/progress.
- Footprint, roads and rooms-per-floor remain fixed. Room IDs are stable across floors: `(floor - 1) * roomsPerFloor + localRoomIndex`. Navigation reaches all completed floors and basements, skips zero and stops at Floor 10/B3. Parking details allocate occupied tenant bays from B1 downward and show per-basement usage. Approved exterior art remains the map symbol; lift modules appear inside completed buildings.
- Save schema 4 persists level/lift counts and the single upgrade order (kind/stage/start day) atomically with money and time. Schemas 1/2/3 migrate with the original one floor/B1 and zero lifts, preserving occupancy, rent and initial manual-opening state. Older clients cannot read schema 4. Validate limits, order state and room/parking bounds before accepting snapshots. Purchases are revalidated in the repository transaction.
- Formatting, Flutter analysis, all 68 tests and the release Web build pass (201 offline resources). The unchanged asset catalog validates all 158 resources/124 frames. Tests cover every cap through real queued jobs, reservation/cancellation/payment timing, fixed lift prices, completion upkeep/valuation, stable upper-floor room IDs, parking caps, migration, offline parity, rollback/concurrent orders and responsive UI at 390×844, 844×390 and 1440×900. Android debug compilation was attempted and remains blocked by the missing SDK. Browser review on an ignored in-memory fixture confirms the title-row button, review, reservation, live progress, completion and Floor 2 admissions/navigation in portrait, plus the landscape layout. Evidence: `docs/images/upgrade-button.jpg`, `upgrade-review.jpg`, `upgrade-progress-portrait.jpg`, `upgraded-floor-2.jpg`, `upgrade-button-landscape.jpg` and `upgrade-lift-cards.jpg`. Production saves were not edited.

The upgrade browser review also confirmed one standard lift completing with the same original-price quote after a floor upgrade, its saved count increasing, and the approved lift module appearing beside the stairs. Evidence: `docs/images/installed-standard-lift.jpg`. The temporary review tab is closed and the review server stopped; no fixture data is shipped.

Source `75c21ac` is pushed to GitHub and published as Netlify deploy `6acf15edceedcc9c7df1de50`. The connector confirms current/ready. Live JavaScript matches the tested release (`1FEDCF3FC30A891C6F514C69D2138133BB2A70D11819E30BED6F7FC8437EE773`); the offline manifest returns HTTP 200 with 201 resources. See Deployment.md. Close older game tabs and reopen without clearing site storage to activate the update.

Earlier iterations below retain their validation history; the current upgrade contract above supersedes their one-floor restriction.

## Building floor navigation — 2026-10-14

- Selecting an existing building on the map or district list replaces the map area with that building's floor detail. New construction confirmation opens the same detail with its real construction status.
- Enter on Floor 1. Show only its rooms; room management retains its saved occupancy and pending-rent behavior. B1 shows parking artwork and actual capacity/used/free bay counts, without tenant rooms.
- Bottom controls are ordered **Exit building | Go up | Go down**, with a persistent **Current floor** indicator. Navigation skips floor zero: Floor 1 connects directly to B1. Disable Go up at Floor 1 and Go down at B1. B1 is accessible after its construction completes, including the pre-admission stage.
- Web floor detail reserves 64 pixels beneath the toolbar to keep the Netlify badge clear of navigation, including narrow portrait screens. Native Android retains its normal safe-area spacing.
- Selection/floor position live in `DistrictViewModel` and are session UI state. Re-entering a building starts at Floor 1. The hidden map stays mounted so Exit building restores its camera zoom/pan. Existing save schema, phase order, prices and building limits remain unchanged.
- Reuse the approved room, resident, stairs and parking assets without changing the catalog or BM master. Scroll floor content while keeping navigation visible.

## Pacing, wording and gestures — 2026-10-14

- User feedback changes the interval to 5 seconds per phase, or 25 seconds per game day. Keep Morning → Day → Afternoon → Night → Noon and existing per-game-day prices, construction, admissions, rent and costs.
- Save schema 2 records its clock interval. Schema 1 snapshots use the original 60-second interval for their first offline catch-up, then scale the remaining fraction of the phase to 5 seconds. Commit this migration in the existing transaction. Repeated reads and backward clocks must preserve earned money and avoid duplicate settlement; unsupported data must remain untouched.
- Simplify game copy, including replacing Payment at Noon with Queued and removing technical catalog/settlement explanations from the player UI.
- Map pinch zoom is continuous, 50%–200%, and anchors the world beneath the moving finger midpoint. Buttons step to the next 25% level. Two-finger gestures restore the previous placement preview and suppress trailing-finger drawing/taps until a fresh gesture. Preserve single-finger pan and mouse land selection.
- No artwork, monetary values, save-slot counts or building limits change. Formatting, analysis and all 43 tests pass, including multi-pointer pinch, limits, preview restoration, post-pinch picking, legacy clock catch-up, migration rollback, backward-clock progress and five-second countdown tests. Android debug build remains blocked by the missing Android SDK. The Web build includes 201 offline resources. Browser review on an isolated localhost origin verified the faster clock, short construction statuses and mouse placement; evidence is `docs/images/pacing-and-copy.jpg`. Physical-device pinch remains unverified. The review server is stopped.
- Source `6103052` is pushed to GitHub and published as Netlify deploy `6acf076d4d86214e639668c3`. The connector confirms current/ready, production JavaScript matches the tested release, and the live offline manifest returns HTTP 200 with 201 resources. See `docs/Deployment.md` for the hash and release link. Close old game tabs and reopen to activate this release without clearing player data.

## Approved exterior, construction progress and manual opening — 2026-10-14

- The user requested the defined design image on buildings. Use the existing approved `assets/game/buildings/apartment.png` directly on the map instead of mapping roof/facade textures into a one-floor box. Preserve the 512 × 512 sprite's proportions, centre it on the saved plot and anchor its bottom to the plot's bottom. The image is a visual symbol; its illustrated storeys do not add playable floors, rooms or bays. Saved footprint/capacity, one playable floor and roads remain unchanged. Picking uses the same sprite rectangle plus the ground plot, in visual depth order.
- Show construction progress on map labels/bars and in the building detail with an accessible percentage/bar. Weight the two-day apartment job as 2/3 and the one-day B1 job as 1/3. Fractions follow saved game phases plus the current phase's elapsed time; waiting states hold their completed fraction. Publish 100% only when both jobs are committed complete. No timers or money are changed.
- Completed buildings stay `parkingDone` with zero admissions/income until **Open to Business**. The action is transactional, requires completed parking, is idempotent, changes the stage to `ready`, and preserves money/earned rent. Tenant admissions retain the next-Morning rule. Completed upkeep/valuation taxes still apply while closed.
- Save schema 3 prevents older clients from automatically opening completed construction. Schemas 1/2 remain readable; already-open buildings stay open, while unfinished/awaiting-open buildings must use the button. Existing timing migration remains intact.
- The asset validator passed all 158 assets/124 frames before the reference change. No artwork bytes or the BM master changed. Formatting, analysis and all 50 tests pass; coverage includes progress, facade picking, manual opening at three viewport sizes, legacy open/closed state, idempotency and rollback. The final Web build passes with 201 offline resources; Android compilation remains blocked by the missing SDK. Browser review of an ignored in-memory fixture confirmed approved art, live progress, holding at 100% through several game days, manual opening and the portrait button. Evidence is in `docs/images/approved-apartment-map.jpg`, `construction-progress.jpg`, `open-to-business.jpg` and `open-to-business-portrait.jpg`. The review server is stopped.
- Source `1f1afac` is pushed to GitHub and published as Netlify deploy `6acf10cf5408a342b1f9f9ac`. The connector confirms current/ready; production JavaScript matches the tested build and the live offline manifest returns HTTP 200 with 201 resources. Deployment.md records the hash and deploy link. Close older game tabs and reopen without clearing site data to activate the update.

## Earlier validation

Use `tool/bootstrap.ps1` for the pinned project-local SDK and dependencies. This workstation initially had no Flutter SDK; bootstrap installed the pinned version successfully after a Windows file-lock retry.

Validation on 2026-10-14: formatting passes for 33 files; Flutter analysis has no issues; all 35 tests pass. Asset validation passes all 158 resources and 124 referenced frames. The final release Web build passes and packages 201 offline resources. Android debug build was attempted but is blocked by the missing Android SDK on this workstation; no Android device validation was performed.

Browser review used an ignored, in-memory fixture entry point (`.tools/review_floor.dart`), separate from the production entry point and player saves. Verified Floor 1 rooms, B1 parking, disabled boundaries, return to 125% map zoom, and scrollable content with fixed controls at desktop, 390 × 844 and 844 × 390 sizes. Evidence: `docs/images/building-floor-1.jpg`, `building-b1.jpg` and `building-floor-portrait.jpg`. The review server was stopped afterward.

## Hosting and source

- GitHub: `norfabagas/building-management-tycoon-game`, existing `main` branch.
- Netlify project ID: `326e5871-656b-4f7b-87c1-664e001d4ac4`; primary URL verified through the connector: https://bmt.niceblue.biz.id.
- `docs/Deployment.md` records the upload procedure and previous release. `.netlify/` remains ignored. Never commit credentials or build outputs. Browser saves are origin-specific.
- Final floor-navigation source `82a049a` is pushed to GitHub and published as Netlify deploy `6acefdf545e77e78c0a6d783` on 2026-10-14. The connector confirms current/ready, and the production JavaScript SHA-256 matches the tested Web build. The offline manifest returns HTTP 200 with 201 resources. Git-based hosting remains unconnected; deployments use the CLI.
- GitHub Actions for initial source `792d3b2` returned `startup_failure` with zero jobs. Its cause is not established; do not claim remote CI or Android validation from that run.
