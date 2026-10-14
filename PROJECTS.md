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

## Setup and validation

Use `tool/bootstrap.ps1` for the pinned project-local SDK and dependencies. This workstation initially had no Flutter SDK; bootstrap installed the pinned version successfully after a Windows file-lock retry.

Validation on 2026-10-14: formatting passes for 33 files; Flutter analysis has no issues; all 35 tests pass. Asset validation passes all 158 resources and 124 referenced frames. The final release Web build passes and packages 201 offline resources. Android debug build was attempted but is blocked by the missing Android SDK on this workstation; no Android device validation was performed.

Browser review used an ignored, in-memory fixture entry point (`.tools/review_floor.dart`), separate from the production entry point and player saves. Verified Floor 1 rooms, B1 parking, disabled boundaries, return to 125% map zoom, and scrollable content with fixed controls at desktop, 390 × 844 and 844 × 390 sizes. Evidence: `docs/images/building-floor-1.jpg`, `building-b1.jpg` and `building-floor-portrait.jpg`. The review server was stopped afterward.

## Hosting and source

- GitHub: `norfabagas/building-management-tycoon-game`, existing `main` branch.
- Netlify project ID: `326e5871-656b-4f7b-87c1-664e001d4ac4`; primary URL verified through the connector: https://bmt.niceblue.biz.id.
- `docs/Deployment.md` records the upload procedure and previous release. `.netlify/` remains ignored. Never commit credentials or build outputs. Browser saves are origin-specific.
