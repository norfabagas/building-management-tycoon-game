# Activities menu reachability

Implemented for the 2026-10-26 request to move the achievements/goals menu away from the bottom-right corner.

- Pin a labelled **Activities** control at the left of the district action bar, before Build/Tenants/Upgrades/Finances. It stays outside the horizontal scroll area, so scrolling the other actions never hides it or moves its target.
- Use a trophy icon, the approved cream/evergreen outlined control style and a minimum 48 × 48 touch target. Below 400px width use the concise label **Goals**; wider layouts use **Activities**. This leaves space for adjacent actions at enlarged text sizes. Keep the existing **District activities** accessibility tooltip. Text scales normally rather than shrinking to fit.
- Keep the same location in full-area portrait/landscape maps and desktop/tablet layouts, above the existing safe-area/hosting-footer clearance. The menu positions itself within the viewport and retains 48px menu rows.
- Existing Achievements objective/progress/reward and Decorations destinations, their Close behavior and camera/navigation session state are retained. The shipped achievement objectives remain the goal system; no separate quest catalog or economy is introduced.
- This is presentation only: schema 9/catalog 2, all five local saves, money, gems, achieved milestones, construction and other gameplay remain unchanged. No package, artwork, API or persistence change is required.

## Verification

`activities_navigation_test.dart` checks portrait, short landscape, tablet and desktop at 320×568, 360×640, 390×844, 568×320, 640×360, 844×390, 768×1024 and 1440×900, each with normal and 140% text. It loads the shipped Roboto fallback for real text measurements and verifies labelled hit targets, menu rows within the viewport, both destinations, fixed position while other actions scroll and unchanged saved progress. Existing mobile map/camera/review tests remain regression coverage. Build, browser and publication evidence is recorded in PROJECTS.md and Deployment.md after validation.

Formatting of 87 Dart files, Flutter analysis, all **325 Flutter tests** (`--concurrency=1`), **20 Node worker/bridge tests**, the **158-asset / 124-frame** validator and the normal timestamped release Web build pass. The Wasm dry run succeeds and **201 offline resources** are packaged under UTC version **20261026032440925**. Android debug compilation was attempted and reports **No Android SDK found**; physical-device validation remains unavailable on this workstation.

Compiled-package browser QA uses a new Activities QA profile on isolated localhost:8796. Desktop, 320×568 portrait and 568×320 landscape show the fixed left control, readable Goals/Activities labels, reachable popup rows, actual achievement-objective progress, Close/return to map and the existing Decorations destination. No purchases are made; the balance remains $40,000. Browser error logs are empty. Existing player origins/saves are untouched. Ignored proof: `.tools/activities-desktop.png`, `.tools/activities-portrait.png`, `.tools/activities-phone-menu.png` and `.tools/activities-landscape.png`. The review tab is closed and viewport override reset; publication/cleanup receipt belongs in Deployment.md.
