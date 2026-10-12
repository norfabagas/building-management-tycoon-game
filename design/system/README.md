> Historical rejected kit. The current artwork and game boards are in [`../tycoon/README.md`](../tycoon/README.md).

# Game component design system

Historical Canva revision (the same design ID now contains the rebuilt kit): [Building Management Tycoon — Design System](https://www.canva.com/d/CL70GLWxm7fQ5G8).

All 16 boards use a 1600 × 1000 canvas, Arial typography, fixed colors and spacing, shared button/field/panel helpers, and the BM tower icon. The source authors native shapes and editable text instead of generated illustrations. `previews/` contains full-size PNGs; `overview.png` shows all boards together. The final editable transport file is `output/Building-Management-Tycoon-v5.pptx`.

`build.mjs` uses the bundled Codex Artifact Tool and presentation finalizer. Run it with the bundled Node runtime and a new revision argument, for example `node design/system/build.mjs v6`. The configured dependency locations reflect this workstation. It renders every board and validates the native export; it refuses to replace an existing finalized output. Keep validation artifacts in `.build/`, then inspect the previews before importing the new PPTX into Canva.

Changing a shared helper changes every instance. Keep content coverage and mechanics aligned with `docs/Rules.md`, `docs/Logic.md`, and `docs/DesignKit.md`. Prices, capacities, names, and progress values in previews are illustrative; open economy decisions remain documented rather than asserted in game UI.
