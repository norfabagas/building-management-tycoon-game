# Project instructions

- Always refer to the documentation before implementing or changing behavior.
- Always update the documentation with implementation decisions, setup steps and material limitations.
- Use `docs/Project.md`, `docs/Platform.md`, `docs/Rules.md`, `docs/Logic.md` and `docs/Design.md` as the game contract.
- The user approved the current Canva design on 2026-10-11. Follow `docs/DesignKit.md` and reuse the defined BM logo and artwork. Large design originals moved to Figma on 2026-10-16; `docs/DesignArchive.md` and `design/figma-manifest.json` record locations and exact restoration. Keep runtime exports in `assets/game/` and the BM master in `design/brand/`.
- Runtime assets and frame/geometry contracts are in `docs/Assets.md` and `assets/game/manifest.json`. Keep the BM master unchanged; export through `design/production/` and validate the catalog before changing asset references.
- Target Flutter/Dart for Android and Web. Support portrait and landscape.
- Keep play and save data entirely local. Do not add accounts, network services, analytics, ads or payment flows.
- Use MVVM. Put game rules in the domain layer, persistence in repositories and presentation state in view models.
- Preserve five save slots, the documented phase order and building limits. Do not invent economy values or resolve open mechanics silently.
- Before handing off application changes, run formatting, `flutter analyze`, meaningful tests and builds appropriate to the change. Record any checks blocked by the local toolchain.
