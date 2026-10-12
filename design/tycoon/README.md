# Tycoon game design kit

Current Canva kit: [Building Management Tycoon — Artwork and Game Design](https://www.canva.com/d/51ESDDCqVSdEOVT).

Rebuilt from page 01 on 2026-10-11 after the user rejected the previous assets. The game uses the requirements in `docs/Project.md`, `docs/Design.md`, `docs/Rules.md`, `docs/Logic.md`, and `docs/Platform.md`.

The defined square BM logo remains unchanged. Headers, titles, fields, buttons, counters, tables, placement grids and status text are editable objects. Game illustrations are raster sprite atlases with transparent backgrounds, reused through native image crops. They are not vector component libraries or finished animation sheets.

## Art direction

- Isometric district exteriors with evergreen contours, warm cream walls, turquoise windows and clear silhouettes.
- Mustard apartments, coral hotels, blue offices and mint food courts. Type labels accompany color.
- Front cutaway room modules share structural frames and materials. Apartments and hotels use room modules; offices use an open floor suite.
- Tenant roles share one character atlas. Resident idle and walking poses are references, not an animation cycle.
- Parking, stairs and both lift types share one transport atlas. Underground examples contain parking only.
- Trebuchet MS throughout. Warm ivory canvas, cream panels and evergreen controls. Controls have a restrained four-pixel base, two-pixel outline and twelve-pixel corners.

## Files

- `assets/buildings.png`: four exterior sprites.
- `assets/interiors.png`: four furnished cutaway modules.
- `assets/people.png`: six role/pose sprites.
- `assets/transport.png`: parking, standard lift, executive lift and stairs.
- `assets/district.png`: district reference scene using the same building family.
- `prompts.md`: final prompt set and generation provenance.
- `build.mjs`: shared board and component authoring.
- `optimize_pptx.py`: deduplicates identical embedded media; it does not change image pixels.
- `previews/01.png` through `16.png`: full-size page renders.
- `overview.png`: ascending board overview.
- `output/Building-Management-Tycoon-r5.pptx`: editable source transport file.

The current [production export pipeline](../production/README.md) retains these originals and supplies individual runtime sprites, modular pieces, roads, character animation sheets, icons, effects, backgrounds and audio in `assets/game/`. See [Assets.md](../../docs/Assets.md) for the complete catalog; the five original atlases are no longer bundled as large runtime sheets.

## Regeneration

Use the bundled Node executable and a fresh revision, for example `node design/tycoon/build.mjs r6`. Paths in the builder reflect this workstation's runtime. The builder renders every page, reuses identical media parts, and validates the PPTX. Review the renders before importing or replacing Canva pages. Keep private build/validation files in `.build/`.

Board balancing examples are illustrative and predate the selected economy. Follow `docs/Economy.md` for Relaxed idle (Option 1), including Sunday apartment rent and daily settlement for other income, selected starting funds/capacity/tax rules, and reserved purchases. `docs/Rules.md` and `docs/Logic.md` also require automatic roads around newly occupied building footprints. The approved boards have not been revised for these later rule updates; complete price/upkeep catalogs and road geometry/cost decisions remain open. No backend, cloud account, ad shop or online purchase flow belongs in this offline game.
