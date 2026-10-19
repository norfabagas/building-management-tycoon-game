# DRY, YAGNI and KISS maintenance — 2026-10-20

The user requested these principles while preserving every existing feature. This pass completes the pending full-area mobile map/smooth-rotation work and simplifies its presentation code. It does not claim that every repeated line in the repository should share an abstraction.

## Concrete changes

- DRY: district audio controls share one implementation while retaining each view's existing disabled-state guard. Both initial-floor selectors share one stepper, keys, bounds and callbacks, with review mode still disabling edits. Mobile/desktop coin feedback share one animation/visibility helper with the existing sizes. Preview, drawing actions and cost review delegate construction validation to one helper calling the unchanged domain rule.
- KISS: the compact district layout composes separate HUD and action helpers around a short map/overlay layout. Remove the redundant inner audio listener because the screen already listens to the same view model. Keep existing view-model ownership and plain private methods; no navigation/state framework is introduced.
- YAGNI: add no dependency, generic control factory, new service, speculative feature flag, save field or migration. Retain the existing platform adapters and domain/persistence boundaries because Android/Web and local-save correctness use them today.

Existing five profiles, local persistence, four building types, purchase/refund/upgrade rules, tenant interiors/release, roads, time/settlement, sound/reduced motion, mobile/desktop layouts, map picking/pan/zoom/two-finger rotation, animated compass commands and timestamp/Sync updater remain in scope for regression checks. Approved runtime assets and BM master remain unchanged. Refactoring changes code organization, not game mechanics or stored data.

## Verification

Run formatting, Flutter analysis, the full Flutter suite (including existing audio, construction, catalog, mobile map, gesture and update cases), Node worker/bridge tests, asset validation and the normal timestamped Web build. Browser QA must verify the final compiled release, not the earlier pre-refactor bundle. Android build/device limitations and final deployment evidence are recorded after execution. See [MobileMap.md](MobileMap.md) and [Deployment.md](Deployment.md).

Final checks on 2026-10-20 pass: formatting of 78 Dart files, Flutter analysis, all 288 Flutter tests, 20 Node tests, the 158-asset / 124-frame validator and the normal-entry Web build with successful Wasm dry run and 201 offline resources. Build timestamp 20261019233239245 UTC is shared by Dart, bridge, worker and metadata. Android debug compilation reports No Android SDK found; physical Android/touchscreen execution remains unverified. Browser and publication evidence follows in Deployment.md.

Final browser QA (2026-10-20) uses a new Maintenance QA profile on isolated localhost:8772, leaving the existing player tab/origin intact. The compiled timestamp is confirmed on home. At 390x844 and 320x568 the map fills the screen behind floating controls; 568x320 checks rotated roads, the building footprint and the separate left-side zoom controls. Through normal UI, the shared floor stepper increases/decreases, expanded plan details and cost review agree on a connected 2x3 apartment (one floor, four rooms, twelve B1 bays, $15,000), construction completes, Open to Business succeeds and the unchanged floor/basement/lift/luxury upgrade catalog opens and returns to the same map. Only this isolated QA game was played; no real profile/tenant was deleted or released. Online console errors are empty. Proof is retained in ignored .tools/maintenance-portrait.png and .tools/maintenance-landscape.png; QA tab/server are closed and viewport reset at handoff.
