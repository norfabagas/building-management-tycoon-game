# Netlify Web deployment

## Floor navigation release — 2026-10-14

The requested floor-navigation update passes formatting, analysis, all 35 tests and asset validation. The final `lib/main.dart` release Web build succeeds with 201 offline resources. Browser floor review used a separate ignored in-memory fixture, never the production entry point or existing player saves. Local Android build is blocked by the missing Android SDK.

The Netlify connector confirms project ID `326e5871-656b-4f7b-87c1-664e001d4ac4` and primary custom-domain URL https://bmt.niceblue.biz.id. The deployment-session CLI authorization succeeded. Source `792d3b2` was uploaded as deploy `6acefcd72165772656d61c1c`, and its production JavaScript SHA-256 matched the local release (`F6142494C9FB7A3D8DCF804B795F0E8CF393BC46E6C5601E930064FE69C14245`). The live offline manifest returned HTTP 200 with 201 resources, and the hosted profile screen launched successfully.

The production check identified the hosting badge's possible overlap with the new navigation on narrow screens. A follow-up reserves 64 pixels beneath Web floor controls; Android spacing remains unchanged. Formatting, analysis and all 35 tests pass again. Final footer-clearance publication evidence is recorded below after upload.

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
