# Building Management Tycoon

## Contract and implementation

Read `docs/Project.md`, `docs/Platform.md`, `docs/Rules.md`, `docs/Logic.md` and `docs/Design.md` before changing behavior. The approved design, BM identity and runtime asset contracts live in `docs/DesignKit.md`, `docs/Assets.md` and `assets/game/manifest.json`.

Flutter/Dart targets Android and Web, portrait and landscape, with MVVM and five entirely local save slots. The approved starter has one apartment floor and B1 parking. Extra floors, basements, lifts, luxury and other building catalogs remain pending; UI navigation must not enable unsupported construction or change economy rules.

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
- The asset validator passed all 158 assets/124 frames before the reference change. No artwork bytes or the BM master changed. Formatting, analysis and all 50 tests pass; coverage includes progress, facade picking, manual opening at three viewport sizes, legacy open/closed state, idempotency and rollback. Web output has 201 offline resources; Android compilation remains blocked by the missing SDK. Browser review of an ignored in-memory fixture confirmed approved art, live progress, holding at 100% through several game days, manual opening and the portrait button. Evidence is in `docs/images/approved-apartment-map.jpg`, `construction-progress.jpg`, `open-to-business.jpg` and `open-to-business-portrait.jpg`. Final publication evidence will be recorded after upload.

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
