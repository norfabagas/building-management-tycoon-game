# Netlify Web deployment

## Timestamp version and Sync — 2026-10-18

Source [`c6cd3fe`](https://github.com/norfabagas/building-management-tycoon-game/commit/c6cd3fef9a57b524602b3bd788449a6333e33ae0) is pushed to main and published at the [primary site](https://bmt.niceblue.biz.id). Netlify deploy [`6ad49ff1819b775e2081ef09`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad49ff1819b775e2081ef09) is ready/current, published **2026-10-18 at 17:31:18 WIB**. The deployed timestamp code is **20261018102654273 UTC** (build start); the manual upload records the complete source hash and uses the normal-entry release Web build.

Home now validates the installed timestamp against uncached same-origin metadata and exposes a pinned top-right Sync only for a valid mismatch. Sync waits for a complete matching offline pack, refuses activation while another game tab is open, verifies the new controlling worker and reloads without clearing local saves. See [AppVersionSync.md](AppVersionSync.md) for architecture, retries and rollout limitations.

- Formatting of **77 Dart files**, Flutter analysis, all **272 Flutter tests**, **20 Node worker/bridge tests**, the **158-asset / 124-frame** validator and the final normal-entry Web build pass. Both successive release builds pass Wasm dry runs with **201 offline resources**. Android debug compilation reports **No Android SDK found**; physical Android/device execution remains unverified. GitHub returned no commit statuses, so remote CI is not certified.
- Two-release browser QA first installs A 20261018102351049, creates/loads a local Sync QA district, stops the server and successfully reloads offline with profile/game and balance preserved. With B hosted, cached A displays the mismatch and a real 48x48 Sync target at x=256/y=8 on 320x568. Another open QA tab prevents activation with an inline instruction; closing it then retrying activates B, reloads to its timestamp and removes Sync. The same local district loads afterward with $40,000 and normal time advancement/rewards. Final online console errors are empty. Original player tabs/saves remain untouched; QA tabs/servers are closed and viewport reset. Ignored proof: `.tools/version-offline.png`, `.tools/version-sync-320.png`, `.tools/version-synced-320.png`.
- Primary responses are **200** and SHA-256 matches the local release: main.dart.js **6043697b2725eb95632181b59bfa85c83535e02c796dc55a03aa96a44e72a57d**, offline_worker.js **85547fdffe751ce7cd37b08793ec92fcacd6a9f935a6fdb9822f359b077949d8**, offline-assets.json **bdb5d4b1197d7da381791f86e125baa39634941a29e41ec6fd4e5963db8c3c21**, app_update.js **63b0ec4199fb841684dec9fdce14e234449fc822c1ec4ac7de10dce729dd9daa**, app-version.json **9a96a8fa97cace61f645d98e5e1265a922707a209bd04888addea38ba258b7e8**. Live metadata contains the expected timestamp; both metadata and worker headers are **Cache-Control: no-store**. Packaging confirms the shared timestamp in Dart/bridge/worker/metadata and all 201 resources exist.

For pre-feature cached clients only: let the new worker download, close all old game tabs and reopen (repeat once if necessary). Preserve browser/app storage. After this updater is installed, future mismatches use Sync. Documentation-only commits after the source hash do not change the deployed bundle.

## Camera rotation and building actions — 2026-10-18

Source [`e6ad234`](https://github.com/norfabagas/building-management-tycoon-game/commit/e6ad2341d1e293c0c872bc77fbec401a2b5a0aa0) is pushed to main and published at the [primary site](https://bmt.niceblue.biz.id). Netlify deploy [`6ad4982f4a7f32000890157a`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad4982f4a7f32000890157a) is ready/current, published **2026-10-18 at 16:58:11 WIB**. The linked site's manual production upload uses the normal-entry release Web build with the full source hash in its message.

Building interiors now pin Upgrade/Back above the scrolling content, panel close controls have a visible label, and neutral floor navigation gives the primary upgrade action clear priority. Touch controls keep at least 48px targets on Web desktop as well as mobile. The map supports two-finger twist/pinch/pan and compass quarter-turn/reset with matching projected road geometry, facade/depth ordering, actor headings/occlusion and world picking. See [CameraAndActions.md](CameraAndActions.md) for behavior and material rendering limits.

- Formatting of **70 Dart files**, Flutter analysis, all **263 Flutter tests** (19 new camera/action regressions), six offline-worker tests and the **158-asset / 124-frame** catalog validator pass. The normal lib/main.dart Web build passes its Wasm dry run and packages **201 offline resources**. Android debug compilation reports **No Android SDK found**; physical Android/touchscreen execution remains unverified.
- Final browser QA on the isolated Camera QA origin verifies rotated map selection, correct road/building/traffic yaw, pinned portrait Upgrade/Back after scrolling, landscape review and actual 48px DOM touch targets. Console errors are empty. The isolated QA apartment was built/opened through normal controls; existing player tabs/saves were preserved. Ignored proof: `.tools/camera-map-final.png`, `.tools/building-actions-final-320.png`, `.tools/building-actions-final-landscape.png`. Review tab/servers are closed and viewport reset.
- Primary HTTP responses are **200** and SHA-256 matches the local release: main.dart.js **fe57a0be5b7048628e50559145c8e49f4d6824b76d668250766b03be04634cc8**, offline_worker.js **67e761e88f89d5ec8d674985324369ef92bdda3a9a1fed90838cddac806635a7**, offline-assets.json **d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea**. GitHub returned no commit statuses; remote CI is not certified.

Keep browser/app storage. Let the offline pack install, close all old game tabs and reopen; cached clients can need a second close/reopen. Documentation-only commits after the source hash do not change the deployed bundle.

## Small-device reachability — 2026-10-17

Source [`2ca091d`](https://github.com/norfabagas/building-management-tycoon-game/commit/2ca091d5e9f15267eae9e633637ba01f16cbb8c1) is pushed to main and published at the [primary site](https://bmt.niceblue.biz.id). Netlify deploy [`6ad337668d368ce959049c1e`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad337668d368ce959049c1e) is ready/current, published **2026-10-17 at 15:52:59 WIB**. The existing linked site's manual production upload uses the explicit normal-entry Web build and records the source hash.

Construction reviews now use a full-area independently scrolling body with pinned cost/balance/confirmation/cancel/redraw. Small-phone HUD/profile cards and landscape building controls recover content space; keyboard-aware game-styled dialogs retain reachable actions. Short maps stack zoom controls to preserve central land selection. See [MobileReachability.md](MobileReachability.md).

- Formatting of **68 Dart files**, Flutter analysis, all **244 Flutter tests**, six worker tests and the **158-asset / 124-frame** validator pass. Final normal-entry release Web build passes its Wasm dry run and packages **201 offline resources**. Android debug compilation reports **No Android SDK found**; physical Android/device and real soft-keyboard execution remain unverified.
- Eleven dedicated reachability cases cover 320×568, 360×640, 568×320 and 640×360 construction reviews at normal/140% text, plus simulated keyboard insets of 260px/290px/120px. Hit-testable actions remain within the visible area with at least 48px height. Expanded integration regressions cover small-phone purchases/refunds, upgrades, floor navigation, opening, decorations, deletion/reuse, acceleration and custom tenant management.
- Final-build browser QA at 320×568 and 568×320 verifies large balance/clock separation, connected-footprint drawing, pinned review totals/actions while scrolling, landscape action row, floor/live-balance navigation, scrolling Add floor popup and safe cancellation. Both existing QA apartments/floor counts and six gems remain; no purchase, profile deletion or tenant release is committed. Console errors are empty. Ignored proof: `.tools/mobile-building-review-320.png`, `.tools/mobile-building-review-568.png`, `.tools/mobile-upgrade-review-568.png`. Review tabs/server are closed and viewport reset.
- Primary HTTP responses are **200** and SHA-256 matches the local release: `main.dart.js` **a61dcf6ad86a0e814a07822c17817e1277a1414cabb5ee4712ffa55a2a136c43**, `offline_worker.js` **2fcc23a37f38732327884e7600bf408abab72a417751608d9e03e12c21a366fe**, `offline-assets.json` **d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea**. GitHub returned no commit statuses; remote CI is not certified.

Keep browser/app storage. Allow the offline pack to install, close all old game tabs and reopen; previously cached clients can need a second close/reopen. Documentation-only commits after the source hash do not change the deployed bundle.


## Custom tenant release review — 2026-10-17

Source [`ccf70c4`](https://github.com/norfabagas/building-management-tycoon-game/commit/ccf70c4577bd31bb9318fbb62ffac040c1f2032d) is pushed to main and published at the [primary site](https://bmt.niceblue.biz.id). Netlify deploy [`6ad325b3ff8916d1c9049c41`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad325b3ff8916d1c9049c41) is ready/current, published **2026-10-17 at 14:37:27 WIB**. The existing manual production upload uses the explicit normal-entry Web build, with the source hash in its deploy message.

Manage now opens a designed full-screen tenant release review, replacing the default AlertDialog. Current/empty artwork, an occupied pill, actual parking/rent effects and pinned tactile Keep/release actions follow the approved cream/evergreen game kit. Confirmation commits the existing vacancy transaction and returns to the refreshed interior; failures stay inline with retry/refresh. See [TenantManagement.md](TenantManagement.md). No new economy, dependency, runtime asset, save schema or profile lifecycle change is introduced.

- Formatting of **66 Dart files**, Flutter analysis, all **203 Flutter tests** (11 new release-review regressions), six offline-worker tests and the **158-asset / 124-frame** validator pass. The normal `lib/main.dart` Web build passes its Wasm dry run and packages **201 offline resources**. Android debug compilation reports **No Android SDK found**; no Android/device run or remote-CI certification is claimed.
- Tests cover apartment/hotel/whole-floor office review, cancellation/commit at 390×844, 844×390 and 1440×900, absence of default dialogs, matching current/vacant art, pinned actions, preserved balance/rent, freed parking, pending/back protection, failed-save retry and live vacancy refresh. Existing directory and room-release integrations also pass.
- Browser review of the normal production bundle on the retained localhost QA profile checks the page at 1000×800, 390×844 and 844×390, loaded previews, independently scrolling portrait summary, fixed actions and Keep tenant returning to the occupied interior with its one reserved bay and 8/12 building bays unchanged. Browser errors are empty. No real tenant was released; destructive paths use isolated automated tests. Proof stays ignored in `.tools/tenant-management-desktop.png` and `.tools/tenant-management-portrait.png`; review tab/server are closed and the viewport override reset.
- Primary HTTP responses are 200 and SHA-256 matches the local release: `main.dart.js` **de96f1196b7978f24ecaee9ce4aa78d44773a23ca39a83e2d19afc314883b395**, `offline_worker.js` **0edaafdf9dd3d666ba94d9fb20c6325073cd7b4657a1bb21e508809966b7af15**, `offline-assets.json` **d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea**.

Keep browser/app storage. Allow the offline pack to install, close all old game tabs and reopen; older cached clients can need a second close/reopen. Documentation-only commits after the source hash do not change the deployed bundle.


## Delete saved profiles — 2026-10-17

Source [`22e6633`](https://github.com/norfabagas/building-management-tycoon-game/commit/22e6633ccd3e9260d5d43196b7109bd52c348d52) is pushed to main and published at the [primary site](https://bmt.niceblue.biz.id). Netlify deploy [`6ad322635f8b26171e20723c`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad322635f8b26171e20723c) is ready/current, published **2026-10-17 at 14:23:19 WIB**. The existing linked site's manual production upload uses the explicit normal-entry Web build and records the source hash.

Occupied slots now offer Delete with a named, permanent-deletion confirmation. The authoritative local profile catalog and full district record are changed in the same transaction; stale current-client sessions/reviews are rejected and reused slots start empty. Validated legacy metadata imports once without changing game progress. SharedPreferences becomes a repairable compatibility mirror. See [DeleteProfiles.md](DeleteProfiles.md) for identity, rollback, clock-reversal and old-client limitations.

- Formatting of **64 Dart files**, Flutter analysis, all **192 Flutter tests** (ten deletion regressions), six worker tests and the **158-asset / 124-frame** validator pass. Final normal-entry Web build passes its Wasm dry run and packages **201 offline resources**. Android debug compilation reports **No Android SDK found**; Android/device execution is unverified.
- Automated isolated-memory tests confirm destructive removal/reuse, preservation of the other four profiles, stale-session/confirmation rejection, concurrent managers, mirror failures, corrupt/unsupported legacy state, disabled pending actions/back and retry after failure. Responsive UI cases cover 390×844, 844×390 and 1440×900.
- Browser review uses the retained localhost QA profile: named Slot 01 confirmation, portrait layout, Cancel, successful reload of both open apartments/six gems and return to the refreshed profile list. No real profile was deleted. Browser errors are empty. Proof is ignored at `.tools/delete-profile-confirmation.png`; review tabs/server are closed and viewport override reset.
- Primary HTTP responses are 200 and SHA-256 matches the local release for `main.dart.js` **b648f9ba47674d22cc3c08e006a2030ea6112cae10488f2c2c7f5b8cf1a54b34**, `offline_worker.js` **327a45c00bc359c98a3ca66574fc510bb233caeceac8771f60e654288ac957c1** and `offline-assets.json` **d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea**. GitHub returned no commit statuses; this does not certify remote CI.

Keep browser/app storage. Allow the new offline pack to install, close all old game tabs and reopen; older cached clients can need a second close/reopen. Clients predating deletion lifecycle checks should not continue writing. Documentation-only commits after the source hash do not change the deployed bundle.


## Full-screen tenant interiors — 2026-10-17

Source [`74c7df9`](https://github.com/norfabagas/building-management-tycoon-game/commit/74c7df9437eee3dd534cc664d82940c7e4ec9f9f) is pushed to main and published at the [primary site](https://bmt.niceblue.biz.id). Netlify deploy [`6ad3196f794639eb74f70734`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad3196f794639eb74f70734) is ready/current, published **2026-10-17 at 13:45:08 WIB**. The manual production upload uses the explicit `lib/main.dart` build, with its source hash recorded in the deploy message. Review fixtures are excluded.

Tenant directory rows, room/whole-floor lease cards and food-floor activity now open the full application viewport. The read-only interior shows role-specific ambient routines plus live saved occupancy, parking, happiness and financial information; Manage preserves the existing confirmation/transaction. Back restores the originating floor. See [TenantInterior.md](TenantInterior.md) for architecture, cosmetic-motion boundaries and all-type behavior.

- Formatting of **63 Dart files**, Flutter analysis, all **182 Flutter tests**, six offline-worker tests and the **158-asset / 124-frame** validator pass. Final normal-entry Web build (including Wasm dry run) passes with **201 offline resources**. Android debug compilation was attempted but is blocked by **No Android SDK found**; no Android/device run is claimed.
- Tests cover all four types at 390×844, 844×390 and 1440×900, live phase/vacancy refresh, preserved money/rent, Back, management confirmation and full cutaway visibility on short landscape. Browser review covers the in-memory four-type fixture and the normal-entry retained QA save, including unchanged occupancy/six gems, clock updates and Manage → Keep tenant. Final 1000×800/844×390 review confirms larger proportional actors and the complete room on short landscape. Browser error logs are empty. Proof remains ignored in `.tools/tenant-interior-final.png`; all review tabs/servers are closed and the viewport override is reset.
- Primary HTTP responses for the three release files are 200 and their SHA-256 values match the local package: `main.dart.js` **d4bcfec2600fb1eeb804b28fa673abe8b03963409e636e12a696ec8338a907c9**; `offline_worker.js` **0bdf1c81b184a155eb8a9bc91d61296e5171fdd77e4d17a2a55933b2d64af93a**; `offline-assets.json` **d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea**.
- GitHub returned no commit status entries; local validation is not a remote CI certification. Saves remain local, schema 8/catalog 2 is unchanged, and no economy/asset bytes/dependencies were changed.

Allow the primary URL to install the new offline pack, close all game tabs and reopen without deleting site data. An older cached client can require a second close/reopen. Documentation-only commits after the source hash do not change the deployed bundle.


## Volumetric figures and floor-driven exteriors — 2026-10-17

Source `430a65d2dfacf41caceacc7bcf3bcde6194566e8` is pushed to main and published as ready/current Netlify deploy `6ad2ef4d222e81a20dff8c6b` at **10:45:21 WIB** on [bmt.niceblue.biz.id](https://bmt.niceblue.biz.id). The normal `lib/main.dart` build includes 201 offline resources; review entry points remain ignored.

All **169 Flutter tests**, six worker tests, formatting, analyzer and asset checks pass. Coverage includes volumetric rotation, completed-floor growth on all types/plot axes, unchanged basement/lift height, save round trips, upper-facade picking and pixel regressions for occlusion/cache invalidation. Browser review verifies 1/4/10-storey geometry and the normal QA game's actual Add floor transaction through completion, two-storey exterior, Floor 2 rooms and preserved six gems. Browser errors are empty. Android debug compilation remains blocked by the missing SDK; remote CI is not certified because GitHub returned no reported statuses.

Primary resources return HTTP 200 and match SHA-256: main.dart.js `b366f4964b5faa2aba5d480d454809f2b1eb8d2607aea98f3cc6379313b2dcb0`; offline_worker.js `7e8f6b3898fadd2bf67b092e1e67984bf63ab13c54ee2a71e124883f5a3ecdda`; offline-assets.json `d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea`. Close/reopen old tabs to activate the offline pack without clearing save data. See [VolumeAndHeight.md](VolumeAndHeight.md) for model/render decisions and limits.


## Connected district roads and traffic — 2026-10-17

- Source: `536b967bd4bf5e4cb6da478b9bab7126c745d7b9`, pushed to `main`.
- Production: [bmt.niceblue.biz.id](https://bmt.niceblue.biz.id), ready/current deploy `6ad2d6e98259b8bde2676b0a`, published 09:01:18 WIB (02:01:18 UTC).
- Explicit normal-entry Web build passes with 201 offline resources. All 152 Flutter tests, six offline-worker tests, analyzer, format and asset checks pass. Android debug build is blocked by the missing SDK. Remote CI is not certified: the GitHub combined-status response had no reported checks.
- HTTP 200 and SHA-256 equality verified on the primary domain for `main.dart.js` (`48a544cee9bf2f755d6c3d03299fcae649c5650f6b8314be8c6f3b9751eafcfd`), `offline_worker.js` (`955530180d717fc77570ca84d063250388ed33f86a7ec1726307a46803e931bd`) and `offline-assets.json` (`d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea`).
- Browser review checks the four-type activity fixture across desktop/portrait/landscape, actual artwork occlusion, Main road navigation, and the normal production bundle migrating the existing local two-business QA save. The public domain starts successfully with five slots. Existing profiles retain their data; close all older tabs and reopen to activate the updated offline pack. No physical disconnected-device, Android or live-Figma certification is implied. See [DistrictRoads.md](DistrictRoads.md) for the rules, migration and cosmetic traffic limits.


## Acceleration self-test release — 2026-10-17

Source [`09b94c2`](https://github.com/norfabagas/building-management-tycoon-game/commit/09b94c2a1e2a3e1c6978197e7842f2ea8adabbdf) is pushed to GitHub main and live on the [primary site](https://bmt.niceblue.biz.id). Netlify confirms deploy [`6ad2c2de88dc491506049c15`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad2c2de88dc491506049c15) ready/current, published at **07:35 WIB on 2026-10-17**. Manual production upload used the existing linked site and the successful `lib/main.dart` release build; Git continuous deployment remains unconnected.

The fix binds gem acceleration confirmation to the reviewed building, work kind/stage, start day and price, preventing a stale shell dialog from purchasing B1 acceleration at an equal price. The dialog content scrolls in short viewports. Existing economy, game cadence, save schema and runtime artwork remain unchanged. See GameplayValidation.md for the failing pre-fix reproduction.

- Format (53 Dart files), Flutter analysis, **138 Flutter tests**, **six Node offline-worker tests**, and validation of **158 assets / 124 frames** pass. The Web build contains **201 resources**, all present locally. Android debug compilation was attempted and remains SDK-blocked. Worker tests mock CacheStorage/fetch; a physical disconnected-browser run and Android hardware verification remain outside this evidence.
- Primary `main.dart.js`, `offline_worker.js` and `offline-assets.json` return **HTTP 200** and match the tested local bundle. SHA-256 respectively: `cba7d3856f97bf9d47904176218ce8793617180c1d6ddd6df58ec7fc95e84e6f`, `8166e61d0d238ca0a2c74cb98a35c9cdb511166c3a298693b934248f3324da3e`, `d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea`.
- Live browser testing used the retained localhost QA district, not production saves. A one-gem Apartment 2 shell review remained open across the transition to B1; confirmation showed “The job changed. Review acceleration again.” and retained all **six gems**. Retry resumed catch-up, construction completed, explicit opening succeeded and the new business admitted a tenant. Browser error logs are empty. Evidence stays ignored in `.tools/self-test-2026-10-17-stale-review.png`.
- The isolated [deploy origin](https://6ad2c2de88dc491506049c15--building-management-tycoon-game.netlify.app) starts with all five empty slots and no browser errors; no profile was created there. Review tabs/server are closed. GitHub returned no commit statuses; local checks do not assert a remote CI pass. Native Figma atomization/live-file verification remains unavailable under the previously recorded Starter MCP limit.

Retain browser site data. Allow the primary URL to install the new offline pack, close all game tabs and reopen to activate it; an older cached client may need a second close/reopen. Documentation-only commits after the source hash do not change the deployed bundle.

## Gameplay quality audit — 2026-10-16

Source [`1cf74ae`](https://github.com/norfabagas/building-management-tycoon-game/commit/1cf74ae83244792d0f15013e206941684a727b5c) is pushed to GitHub main and published on the [primary site](https://bmt.niceblue.biz.id). Netlify deploy [`6ad24326f0a099547884454c`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad24326f0a099547884454c) is ready/current, published 2026-10-16 at 22:30 WIB. Upload used the existing linked site with `deploy --prod --dir build/web --no-build`; its message records the source hash. Git continuous deployment remains unconnected.

The [gameplay audit](GameplayValidation.md) explains investment-review changes, room-first detail, compact landscape presentation, the explicit opening shortcut, stable cash animation and transient offline synergy caching. Approved economy, artwork, BM mark, clock, local saves and schema remain unchanged. The build script now explicitly compiles `lib/main.dart`.

- Formatting of 52 Dart files, Flutter analysis, all **132 tests**, the additional four usability checks, and asset validation (**158 resources / 124 frames**) pass. Android debug build was attempted and remains blocked by the missing SDK.
- Final production Web build succeeds with **201 offline resources**, all present locally. No review fixture or new large design source was included. Screenshots/benchmarks remain ignored in `.tools/`.
- Primary-site JavaScript, service worker and offline manifest return HTTP **200** and match the final local files byte-for-byte. SHA-256: `main.dart.js` = `4250c851b25a470272cc6225a9902e41e0f7fc097062ae28d58ec49990c758f8`; worker = `d04e2db60bc2b19a366ffa14290ce5fb47bd3cf59a7b8ccf9b743a1b9ac1426e`; manifest = `d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea`.
- Isolated localhost play verified profile creation, drawing/purchase, queued construction, manual opening, admissions, pending rent, daily costs, Sunday collection and retained progress across the cache update. Final portrait/844×390 landscape review shows the real room art and fixed controls, with no console errors. Local evidence: `.tools/gameplay-audit-landscape.jpg` and `gameplay-audit-portrait.jpg`.
- The isolated [deploy origin](https://6ad24326f0a099547884454c--building-management-tycoon-game.netlify.app) starts with five empty slots. No production-origin save was opened or modified. GitHub's status connector returned no statuses for the source; this is local validation, not evidence of a passing remote CI run.
- Live Figma/native atomic components remain quota-blocked. Android hardware, physical pinch/speakers and disconnected-browser execution remain unverified. See the audit for measured performance and assessment limits.

Retain site data to preserve saves. Load the primary URL to allow the offline update to install, then close all game tabs and reopen it to activate the new worker. If an older offline build was still cached, a second close/reopen after installation may be needed; do not clear storage. Deploy permalinks have separate local saves. Later documentation-only commits do not change this deployed bundle.

## Four building types and Figma gameplay — 2026-10-16

Source [`5658c22`](https://github.com/norfabagas/building-management-tycoon-game/commit/5658c22b6941fbb3ab42efacfb48655c99c0af06) is pushed to `origin/main` and published at [bmt.niceblue.biz.id](https://bmt.niceblue.biz.id) as deploy [`6ad23abd9abc018af77fbd70`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad23abd9abc018af77fbd70). Netlify confirms ready/current, published at 21:54 WIB. The deploy title records the source hash; upload used the existing linked site and `deploy --prod --dir build/web --no-build` after a successful production build of `lib/main.dart`.

The release implements approved catalog 2: four real building types, initial floors, type-specific interiors/actors/capacity/income, luxury/needs/synergy, achievements/gems, decorations, active-job acceleration, local audio/motion, directories and closing forecasts. Two-finger pinch/pan remains anchored and suppresses accidental placement; rectangular families follow both footprint axes. Schema 7 catches existing saves up under catalog 1 before migration and preserves balances, pending rent, levels and five local slots. [FigmaAssessment.md](FigmaAssessment.md) maps all 16 archived boards and records adaptation/verification limits.

- Formatting (51 files), Flutter analysis, all **127 tests** and validation of **158 assets / 124 frames** pass. Android debug compilation was attempted but is blocked by the missing Android SDK.
- The final Web build contains **201 offline resources**, with no missing local paths. Production JavaScript contains no in-memory review fixture. No runtime artwork, BM master or large design originals were added/changed.
- Hosted JavaScript, service worker and offline manifest each return HTTP 200 and match the tested local files byte-for-byte. JavaScript SHA-256: `272445b0c371f4a579601e5f257d79a102a56876897220b945564a900fd37367`; worker: `3528c931f3656a00ac1fbf0096815d9b4ef2bff8e5e340da52c579b55694d5e1`; offline manifest: `d88b8768ca6a3e49c002341e16bfd700e04e0acb3951fbe860d9c7ee6406b6ea`.
- The isolated [deploy permalink](https://6ad23abd9abc018af77fbd70--building-management-tycoon-game.netlify.app) launches with all five empty local slots and no browser errors. No profile was created there. Browser review of the actual game widgets used an ignored localhost/in-memory fixture; it verified all four exteriors/cards, portrait Hotel guest detail, landscape Office lease/bay detail, Food Court visits/sales/parking, separated finances/forecast and explicit local audio initialization. Test tabs/server are closed; production player saves were not modified.
- Current Figma inspection/native component atomization remains blocked by its Starter MCP quota. Android hardware, physical pinch/speaker quality and a new disconnected-origin browser test remain unverified. The GitHub status connector returned no statuses for the source commit; it supplies no remote CI evidence. Local checks above are the release validation.
- Git continuous deployment is unconnected (`repo_url`/provider are null); uploads remain manual CLI releases. `.netlify/`, SDK/cache, source backups, fixtures and screenshots remain ignored. Subsequent documentation-only commits do not change this deployed application bundle.

Close older game tabs and reopen the primary URL to activate the updated code/cache. Retain browser site data to preserve local saves; old clients reject schema 7. Saves remain bound to their original browser origin, so the new deploy-permalink origin is not a migration destination for existing districts.

## Rectangular buildings and 24-hour daylight release — 2026-10-16

Source `1fcb976` is published at [bmt.niceblue.biz.id](https://bmt.niceblue.biz.id) as deploy [`6ad1bcb716eba45303af59bb`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad1bcb716eba45303af59bb). The connector confirms ready; publication completed at 12:57 WIB. This release adds footprint-shaped rectangular apartments, 24 hours per 24 real seconds, book closing at 24:00 and smooth directional daylight. Schema 6 safely migrates prior clock saves; old clients reject that schema.

Formatting, Flutter analysis and all **81 tests** pass. The final clock/geometry subset also passes all 15 tests. The unchanged catalog validates 158 runtime assets and 124 frames. Software-rendered visual review checked 2×8, 8×2 and square buildings and prompted correction of a stretched roof texture before release. The final roof uses a proportional grey surface, cream rim and compact service unit. This review fixture is ignored and is not a production entry point; no player save was modified during review. Android debug compilation remains blocked by the missing SDK.

The final release Web build packages 201 offline resources; every manifest path exists. Hosted `main.dart.js`, `offline_worker.js` and `offline-assets.json` return HTTP 200 and match the tested local files exactly. JavaScript SHA-256: `17d308f6993a12d86a566fccfaf310cb0c269641b1875d92cfe10c9225cc733a`; service worker SHA-256: `c7f2b1aaa5108f27193fc2bec22b3882a3c98319c7d3de95380d9f6a12e4fda9`. No new interactive/disconnected-origin browser test was performed. Close existing game tabs and reopen to activate the new worker; retain browser site data to preserve local saves.

## Rebuild and deployment request — 2026-10-16

Rebuilt current GitHub source `bbd6d28` in a fresh release checkout after discovering stale local refs and Windows ACL failures in the old checkout. The release Web build succeeds with 201 offline resources. `main.dart.js` SHA-256 is `E991772342C1ADB544EFDDAFD522C72322885C051025E0E29468C459A9406D65`, matching the latest existing gameplay release. Formatting, analysis, all 75 tests and validation of 158 assets/124 frames pass; Android debug compilation is blocked by the absent Android SDK. Design-only repository cleanup does not change application/runtime bytes; see [DesignArchive.md](DesignArchive.md).

The user completed CLI authorization and the new production upload succeeded on 2026-10-16. Source checkout `6eb2f54` was published to existing site `326e5871-656b-4f7b-87c1-664e001d4ac4` with `netlify deploy --prod --dir build/web --no-build`.

- Production: [bmt.niceblue.biz.id](https://bmt.niceblue.biz.id).
- Deploy: [`6ad1b64af7f7b6f53f19e3f8`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6ad1b64af7f7b6f53f19e3f8), confirmed ready by the Netlify connector, published at 12:29 WIB.
- Hosted `main.dart.js`, `offline_worker.js` and `offline-assets.json` each returned HTTP 200 and matched local bytes exactly. The offline manifest lists 201 resources with no missing local paths. The worker SHA-256 is `32cc792ce65b6880ff876ecf6f01694b7eca8d6be1704ad27d494b1b4e652a21`.
- CLI linkage stays in ignored `.netlify/`; no credential was committed. Hosting remains manual CLI; GitHub pushes do not publish automatically.
- This confirms publication and resource integrity, not a new interactive or disconnected-browser gameplay test. Close old game tabs and reopen to activate the updated worker without clearing browser site data or saves.

## Single balance and immediate purchase/refund release — 2026-10-14

Source [`550bf01`](https://github.com/norfabagas/building-management-tycoon-game/commit/550bf01) shows one **Balance**, immediately deducts confirmed building/upgrade prices, and immediately refunds cancellation before building opening or upgrade completion. Construction timing and daily/Sunday income/cost schedules stay unchanged. Schema 5 migrates legacy queued orders exactly once without charging already-paid work again. Purchase/refund history does not mutate the wallet again at closing; refunds are not income or taxable revenue.

- Pushed to `origin/main` and uploaded through the existing CLI workflow.
- Deploy [`6acf193d578dc06d1622110b`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6acf193d578dc06d1622110b) is current/ready according to the connector; production is https://bmt.niceblue.biz.id.
- Live `main.dart.js` returns HTTP 200 and matches the tested release SHA-256: `E991772342C1ADB544EFDDAFD522C72322885C051025E0E29468C459A9406D65`.
- The live offline manifest returns HTTP 200 with 201 resources. Hosting remains manual CLI, separate from GitHub pushes.
- Browser startup on the isolated deploy-permalink origin succeeds and shows all five local slots. No game data was created; that temporary tab is closed.
- All 75 tests pass, including the final 23 money/UI cases. Formatting, analysis, asset validation (158 resources/124 frames) and release Web build pass. Android debug compilation was attempted and remains blocked by the missing SDK.
- An ignored in-memory localhost fixture verifies $40,000 → $30,000 on confirmation, then $30,000 → $40,000 on cancellation during construction. The next closing records the $10,000 refund with zero income/tax and no second balance change. The temporary review tab/server are closed. Production player saves were not edited. Gameplay.md links the screenshots.

Close old tabs and reopen to activate the new code/cache; retain site storage. Older app clients reject schema 5. Existing room, rent, level/lift counts and initial manual-opening state migrate transactionally.

## Apartment floors, basements and lifts — 2026-10-14

Source [`75c21ac`](https://github.com/norfabagas/building-management-tycoon-game/commit/75c21ac) adds **Upgrade building** beside the apartment title, cost/upkeep/time review, queued upgrades up to 10 floors, 3 basements, 3 standard lifts and 1 executive lift, construction progress, expanded per-floor room/parking detail and schema 4 migration. The user approved level rates/times and lift prices/upkeep/installation, with rent/happiness effects deferred. See Economy.md for the exact catalog. Existing businesses stay open while upgrading; initial manual opening remains required.

- Source pushed to `origin/main`; GitHub connector credentials also verified for the repository owner.
- Published by CLI to https://bmt.niceblue.biz.id as deploy [`6acf15edceedcc9c7df1de50`](https://app.netlify.com/projects/building-management-tycoon-game/deploys/6acf15edceedcc9c7df1de50). The connector confirms current/ready.
- Live `main.dart.js` returns HTTP 200 and matches the tested release SHA-256: `1FEDCF3FC30A891C6F514C69D2138133BB2A70D11819E30BED6F7FC8437EE773`.
- Live offline manifest returns HTTP 200 with 201 resources. No backend, credentials or fixture data are included in the build. Git-based hosting remains unconnected; future pushes alone do not deploy.
- The published release launches successfully in the browser on its isolated deploy-permalink origin, showing all five local slots. This startup check created no game data; the temporary tab is closed.
- Formatting, analysis, all 68 tests, asset validation (158 resources/124 frames) and release Web build pass. Android debug compilation remains blocked by the missing SDK; no Android device validation is claimed.
- Browser review used an ignored in-memory localhost fixture to verify review/reservation/payment/progress/completion, Floor 2 admissions/navigation, unchanged original-price lift quotes after floor expansion, installed standard lift artwork/count and portrait/landscape controls. That tab and server are closed; production player saves were not edited. Gameplay.md links the evidence.

Close older game tabs and reopen to activate the new code/cache without clearing site storage. Older clients cannot read schema 4. Schemas 1/2/3 migrate inside the existing local transaction and retain prior rooms, rent and initial opening state.

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
