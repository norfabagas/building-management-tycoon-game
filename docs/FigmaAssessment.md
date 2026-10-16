# Figma implementation self-assessment — 2026-10-16

## Scope and result

The subsequent [gameplay quality audit](GameplayValidation.md) records player-facing findings, improvements and performance evidence. It adds purchase consequences, compact landscape information, progressive disclosure and a portrait opening shortcut without changing approved economic values. Refer to the latest Deployment.md entry for the current validation/release; older counts below describe the preceding catalog release.

Target: [Building Management Tycoon — Game Design](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ), all 16 approved boards, as preserved by `design/figma-manifest.json`, `design/tycoon/build.mjs` and the verified local archive. The user explicitly approved [catalog 2](FigmaCatalogProposal.md) with “Setujui katalog usulan”. Earlier starter-only deferrals are superseded.

All 16 board topics now map to functional game code and verification below. Apartment, Hotel, Office tower and Food court are playable types with distinct admission, parking and income behavior. This is a functional implementation assessment, not a claim of pixel-identical static boards or certification of unknown current Figma edits. Live `get_design_context` remains blocked by the Starter MCP quota. The earlier request to atomize components inside Figma also remains blocked; reusable Flutter widgets do not constitute editing that Figma file.

User overrides remain authoritative: one Balance and immediate payments/refunds; 24 hours at one real second per hour; midnight closing; ten-floor cap and later floor upgrades; footprint-shaped long buildings; automatic roads; selected-floor detail replacing the map. Board amounts, district names and sample tenant names were illustrative. Malls/VIP remain future scope.

## Board matrix

| Board | Implemented behavior and presentation | Verification |
| --- | --- | --- |
| 01 Identity | Unchanged BM mark, shared title/theme, approved artwork and offline font fallback | Asset hashes, profile/UI tests, browser render |
| 02 Exteriors | Four canonical silhouettes; rectangles follow both land axes; Food Court has a lower wall height; actual luxury tier labels | Browser district; software render of eight type/orientation combinations; geometry tests |
| 03 Map | Unbounded land, automatic roads, shared-road collision rules, valid/blocked previews, neighbor synergy capped at 15%, decoration conflicts | Domain collision/synergy tests; rendered roads; pointer/zoom tests |
| 04 Interiors | Correct furnished/vacant room families, whole-office lease modules, Food Court facility, parking-only B1–B3, stairs/lifts | Type-detail and floor UI tests; guest/office/F&B browser review |
| 05 People | Resident, guest, corporate tenant, customer and maintenance sheets; idle/walk/stair poses; finite lift carriage/door travel and one-shot effects | Role-specific callsites, asset frame tests, motion/reduced-motion tests, browser render |
| 06 Controls | Native button states, single Balance, clock/gems, Build/Tenants/Upgrades/Finances and District activities for Achievements/Decorations; local sound control | Responsive interactions, actual gem purchases/rewards, audio failure/mute tests |
| 07 Profiles | Exactly five entirely local save slots and existing naming/validation | Existing profile/repository tests; production startup check recorded in Deployment.md |
| 08 District | All-type map/list and context; directories open the actual saved tenant floor or building upgrade catalog; exit preserves map camera | Directory tests and browser selection/rotation |
| 09 Build type | Four usable cards, four columns on wide screens and responsive rows/stacking; type-specific description and rates | All-type construction UI tests and browser card comparison with board 09 |
| 10 Footprint | Manual drawing, permanent land, roads and type/floor-aware validation/quotes; pinch restores previous plans | Purchase/refund/collision tests; multi-pointer tests including decoration preview |
| 11 Floors/review | 1–10 initial floors, calculated rooms/floor leases/party capacity, B1, type-specific cost/upkeep/time and confirmation | Multi-floor quote, construction timing, cancellation and three-viewport UI tests |
| 12 Building detail | Actual selected floor rooms/lease/facility, per-basement used/free bays, role-aware context/actions and installed lift counts | Floor/directory/type UI tests; browser guest and office dialogs, including safe nested-Navigator dismissal |
| 13 Needs/parking | Saved occupancy; happiness/access formula scales only new demand; weighted office bays and visitor-window hard caps | Exact occupancy/parking tests; distinct guest/lease/facility browser values |
| 14 Upgrades | All-type floors, B1–B3, standard/executive lifts and luxury 1–3; one job, reviewed costs/time/upkeep, limits, full unfinished refunds; active-job gem acceleration | Cap/cost/timing/rollback tests; luxury and acceleration review/confirm/cancel at all three sizes |
| 15 Finances | Sunday apartment ledger, daily hotel/office/sales/parking, costs/taxes, purchase/refund history, copy-only closing forecast, loss styling and already-applied offline net | Exact cents/receipts tests; Sunday/migration/offline parity; forecast does not mutate the save |
| 16 Responsive | Portrait panels, landscape/Web contexts and independent floor scrolling; fixed floor controls/footer clearance; plans, selection and camera retained across resizing | 390×844, 844×390 and 1440×900 UI tests plus browser portrait/landscape/desktop review |

## Self-assessment criteria and evidence

A different label or a bundled image was not accepted as a building implementation. Hotels refresh guests daily; offices rent entire floors and reserve area-based bays; Food Courts release/re-admit parties across four windows, carrying real daily sales/parking counters. Their interfaces and rates follow that behavior. Saved apartment rent is never retroactively boosted. The new schema first catches old saves up under their original catalog before activating catalog 2.

Gems, achievements, decoration charges/moves and acceleration are persisted in the existing repository transaction. Tests verify one-time rewards, canceled previews, full unfinished refunds, stale/invalid actions, rollback and repeat/backward-clock idempotence. The next closing estimate runs on a copied snapshot and cannot grant cash or rewards to the real save.

All runtime media remain local and unchanged. Sound starts only after an explicit gesture; playback failure/mute stops local players without blocking saves. Browser initialization succeeded, then the fixture was muted again. Motion tests check carriage movement, a single arrival, one-shot completion and reduced motion. Long offline daylight jumps take a short cyclic transition instead of sweeping through hundreds of day/night cycles.

Isolated review used ignored in-memory fixtures and a localhost origin, never production player saves. Browser inspection compared the four type cards with archived board 09, checked the four-type district, Hotel rooms/guest context in portrait, Office whole-floor lease/six reserved bays in landscape, and Food Court party/sales/parking data on desktop. Software review checked all four rectangular families in both orientations. The software test font uses block glyphs; browser review supplies the real bundled-font evidence. Review screenshots remain local in `.tools/figma-building-types.jpg`, `figma-district-desktop.jpg`, `figma-hotel-portrait.jpg`, `figma-office-landscape.jpg` and `all-exteriors.png`; large references/screenshots were not restored to Git.

## Final checks and remaining limits

Formatting passes for 51 Dart files, Flutter analysis reports no issues and all **127 tests pass**, including responsive luxury/acceleration review/refund and the offline-lighting regression. The final release Web build explicitly compiles `lib/main.dart` and succeeds with **201 offline resources**. The asset validator passes 158 runtime resources and 124 animation frames. It verifies provenance for ten archived raster originals without refetching their remote bytes; this is not a full restored-source audit. Publication evidence is recorded in Deployment.md once the upload is verified.

Publication is verified: source `5658c22` is on GitHub main and Netlify deploy `6ad23abd9abc018af77fbd70` is ready/current. The primary site's JavaScript, worker and offline manifest return HTTP 200 and exactly match the tested build. The isolated deploy origin starts with all five slots and no console errors. [Deployment.md](Deployment.md) contains the release links, hashes and safe update instructions. Local review tabs/server are closed.

Android compilation and physical-device/two-finger/speaker verification remain blocked by the missing Android SDK/device. Touch behavior is verified with simultaneous Flutter pointer events, including focal anchoring, both zoom limits and no accidental drawing/selection. Current remote Figma/native component verification remains quota-blocked. Trebuchet is the design reference; packaged Roboto/Noto Sans Thai remains the approved offline fallback. Scrolling selected-floor layouts follow the newer user instruction rather than the older multi-floor board composition. These limits prevent a claim of live-file pixel-perfect or native-Figma-component parity.
