# Netlify Web deployment

## Approved building art, progress and manual opening — 2026-10-14

Source [`1f1afac`](https://github.com/norfabagas/building-management-tycoon-game/commit/1f1afac) uses the approved apartment exterior image directly, adds map/detail construction bars and percentages, and requires **Open to Business** after both jobs finish. Schema 3 preserves already-open buildings while preventing older clients from automatically opening completed-but-closed construction. Admissions still begin at the next Morning after opening; prices, capacity, five-second phases and other financial rules are unchanged.

- Published to https://bmt.niceblue.biz.id with the existing CLI workflow.
- Deploy [`6acf10cf5408a342b1f9f9ac`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6acf10cf5408a342b1f9f9ac); connector confirms current/ready.
- Live `main.dart.js` SHA-256 matches the tested release: `3E649BE4E0DBE3147ACD98304A9F109FFA6EF9E0FA42B3B42EC0D6E59C0FB66B`.
- Live offline manifest returns HTTP 200 and 201 resources. Hosting remains manual CLI; GitHub pushes are separate.
- Formatting, analysis, all 50 tests and the final release Web build pass. The ten gameplay UI tests were repeated after the final help-copy adjustment. The approved asset catalog validates all 158 assets/124 frames; apartment PNG bytes match its unchanged catalog hash. Android compilation was attempted and remains blocked by the missing SDK.
- Browser review used an ignored in-memory fixture to verify approved art, live progress, completed construction remaining closed for several game days, the manual action and portrait layout. No production player saves were edited. The review server is stopped. Evidence is linked in Gameplay.md.

Close existing game tabs and reopen to activate the updated cache; keep site storage intact. Older app clients cannot read schema 3 and must not overwrite the upgraded snapshots.

## Pacing, copy and pinch release — 2026-10-14

Source [`6103052`](https://github.com/norfabagas/building-management-tycoon-game/commit/6103052) adds 5-second phases (25-second days), concise construction/finance/tenant copy and continuous focal-point pinch zoom at 50%–200%. Schema 2 records the clock interval; older saves catch up at their original speed before changing interval and preserving phase progress. Five slots, prices, per-game-day rules and phase order remain unchanged.

- Published to https://bmt.niceblue.biz.id through the existing CLI deployment path.
- Deploy: [`6acf076d4d86214e639668c3`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6acf076d4d86214e639668c3); connector confirms current/ready.
- Live `main.dart.js` SHA-256 equals the tested local release: `589315243C906D619FCD0AED28696D4E30F4AC6A64604DC4C5899909D002195D`.
- Live offline manifest returns HTTP 200 with 201 resources. Git-based hosting remains unconnected; the source was pushed separately.
- Formatting, Flutter analysis, all 43 tests and release Web build pass. Android debug build was attempted and remains blocked by the missing Android SDK. Physical-device pinch remains unverified; multi-pointer Flutter tests cover it in simulation.
- Browser review on an isolated localhost origin confirmed running phases, short statuses and the 2 × 4 mouse construction flow. Existing production saves were not edited. Evidence: `images/pacing-and-copy.jpg`.

Close all old game tabs and reopen to activate the new code/cache. Schema 2 is deliberately unreadable by older app clients; keep browser storage intact to preserve the local saves.

## Floor navigation release — 2026-10-14

The requested floor-navigation update passes formatting, analysis, all 35 tests and asset validation. The final `lib/main.dart` release Web build succeeds with 201 offline resources. Browser floor review used a separate ignored in-memory fixture, never the production entry point or existing player saves. Local Android build is blocked by the missing Android SDK.

The Netlify connector confirms project ID `326e5871-656b-4f7b-87c1-664e001d4ac4` and primary custom-domain URL https://bmt.niceblue.biz.id. The deployment-session CLI authorization succeeded. Source `792d3b2` was uploaded as deploy `6acefcd72165772656d61c1c`, and its production JavaScript SHA-256 matched the local release (`F6142494C9FB7A3D8DCF804B795F0E8CF393BC46E6C5601E930064FE69C14245`). The live offline manifest returned HTTP 200 with 201 resources, and the hosted profile screen launched successfully.

The production check identified the hosting badge's possible overlap with the new navigation on narrow screens. A follow-up reserves 64 pixels beneath Web floor controls; Android spacing remains unchanged. Formatting, analysis and all 35 tests pass again. The final Web build includes 201 offline resources. Updated desktop/portrait browser screenshots are in Gameplay.md; the review server is stopped.

**Final publication:** source `82a049a`, deploy [`6acefdf545e77e78c0a6d783`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6acefdf545e77e78c0a6d783), production https://bmt.niceblue.biz.id. The Netlify connector confirms this is the current ready deploy. Production `main.dart.js` SHA-256 matches the tested final build: `F5AC08FA3723289617370DE9F6DDC28FAD9DA66DA812817219BEDF6963510C8D`. The final live offline manifest returns HTTP 200 and 201 resources. No real player saves were edited during validation.

The site's API build settings have no Git provider/repository configured. Hosting therefore remains manual CLI upload; GitHub pushes do not deploy automatically. `.netlify/` remains ignored and CLI credentials are outside the tracked project.

The Web app is published at [building-management-tycoon-game.netlify.app](https://building-management-tycoon-game.netlify.app). The user resumed deployment on 2026-10-12 and authorized the Netlify CLI. The latest release replaces the empty-canvas bootstrap with the approved apartment starter: construction, automatic roads, local full-game saves, tenant rooms, Sunday rent and daily finances. See [Gameplay.md](Gameplay.md) for scope and remaining building/upgrade systems.

## Build and hosting configuration

- `netlify.toml` publishes `build/web` and runs `bash tool/build_netlify.sh` for Git-based Netlify builds.
- The Bash entry point installs the Flutter version in `toolchain.json`, verifies its exact Git revision, resolves the checked-in lockfile and invokes `tool/build_web.dart`. `.gitattributes` preserves LF line endings for this Linux build entry point.
- The Web builder bundles renderer/fonts locally and generates the versioned service worker and asset manifest. Publish the whole output directory, including `canvaskit/` and `assets/`.
- The Netlify fallback serves `index.html` for client navigation while allowing existing files to resolve normally. Stable Flutter output names revalidate on the host; the application's versioned cache handles offline reloads.
- `.netlify/` is ignored. CLI linkage belongs to the local workstation and must not be committed. No access token belongs in the repository or Web output.

## Local upload

Authorize/link the intended project and build the Web release:

```powershell
./.tools/flutter/bin/cache/dart-sdk/bin/dart.exe run tool/build_web.dart
netlify deploy --prod --dir build/web --no-build
```

The `--no-build` flag uploads the already-built output. A manual upload does not by itself connect GitHub continuous deployment. Record the actual project/deploy identity, live URL and whether Git-based builds are connected after deployment succeeds.

## Offline and saves

The first visit needs connectivity to install the app's resources. Later reloads work offline once caching completes. The current app stores five local profile slots in browser storage tied to the live origin. Preview URLs and custom domains have separate storage; opening a new origin does not move existing saves. Browser storage clearing removes local profiles. Updates activate after previous app clients close.

## Deployment status

**Published on 2026-10-12.**

- Project: `building-management-tycoon-game`, team `norfabagas`.
- Project ID: `326e5871-656b-4f7b-87c1-664e001d4ac4`.
- Production URL: [Open the game](https://building-management-tycoon-game.netlify.app).
- Dashboard: [Netlify project](https://app.netlify.com/projects/building-management-tycoon-game).
- Deploy ID: `6acce85f79f475141097f789`.
- Deploy details: [Production deployment](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6acce85f79f475141097f789).
- Uploaded release: source checkout `2aca7b3`, using `netlify deploy --prod --dir build/web --no-build`.
- Deployment mode: manual CLI upload. GitHub continuous deployment is **not connected**; future pushes alone do not publish the site. Build locally and run the upload command above for updates, or explicitly connect Git builds later.
- Local project linkage remains in ignored `.netlify/state.json`; credentials are stored by the CLI outside tracked project files.

Before this zoom update, formatting (33 files), Flutter analysis, all **32 tests**, Android debug and release Web builds passed. Construction UI tests run at 125% zoom with semantics enabled at phone, landscape and desktop sizes. The unchanged 158-file resource catalog retains its earlier asset validation; the offline Web build includes 201 resources.

Live zoom verification: mouse clicks changed 100% → 125% → 75%, then returned to 125% during planning without drawing a footprint. A subsequent fast drag selected the expected 2 × 4 tiles, six rooms, sixteen B1 bays and $20,000 quote. The buttons are in the map's bottom-right above the footer. Review used an isolated deploy-permalink origin; main-origin player saves were not changed. The production JavaScript hash matches the validated zoom bundle.

After publication, the production main JavaScript SHA-256 matched the validated build. On the deploy-permalink origin, browser review with accessibility enabled verified profile creation, $40,000 initialization, a fast-drag 2 × 4 footprint, six derived rooms, sixteen B1 bays, the $20,000 cost review, confirmation/reservation and the automatically saved road ring. Review data is isolated from the main origin's player saves. The semantic canvas interception found during the first upload was fixed forward in this release.

The local host was stopped and the app reloaded successfully from its final offline cache. The saved district loaded with its paid order, roads and correct construction/calendar progression; the purchase was not charged a second time. This verifies local offline reload, not a disconnected reload against the live HTTPS origin. The hosting badge remains provided by Netlify. Other gameplay limits are in Setup.md and Project.md.

## Loading a newer release

Updates wait for existing game tabs to close so an active session keeps a consistent code/cache version. Refresh once to check for and download the new cache, allow the download to finish, then close all tabs on the game origin and reopen it. A desktop hard refresh (Ctrl+Shift+R) can load the new hosted bundle directly. Keep browser site data intact to retain existing local profiles and game snapshots.

Primary references: [Netlify file configuration](https://docs.netlify.com/build/configure-builds/file-based-configuration/), [headers](https://docs.netlify.com/manage/routing/headers/) and [CLI deployments](https://docs.netlify.com/cli/get-started/).
