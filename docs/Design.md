# Design Document

## Visual Style
- **Perspective:** Strictly 2D view. 
  - *Macro View:* Top-down or isometric 2D view of the entire CBD area grid (showing empty land and building exteriors).
  - *Micro View:* Side-view (cross-section) of a selected building to see floors (underground and above ground) along the Y-axis.
- **Art Direction:** Clean, colorful, and slightly stylized (cartoony but structured). Easy to distinguish different building types and luxury levels at a glance.
- **Animations:** 
  - Idle animations for tenants walking on floors or climbing stairs.
  - Lift carriages moving vertically up and down shafts (if purchased).
  - Construction dust for building new rooms/floors, coin pop-ups for revenue collection.
- **Orientation:** UI and gameplay must gracefully adapt to both Portrait and Landscape orientations on mobile devices and web browsers.

## Controls & Interaction
- **Input Method:** Strictly touch/click-based (Tapping and Dragging).
- **Navigation:** Map-like behavior. Players pan around the CBD area or scroll up/down building floors by dragging/swiping across the screen. 
- **Map zoom:** Place native **− / +** buttons at the map's bottom-right, with a percentage between them. Each click moves to the next lower/higher 25% mark between 50% and 200%, starting at 100%. Keep the world point under the viewport centre fixed. Zoom applies to artwork and pointer hit testing; it does not change footprint dimensions or capacity. The controls sit outside map drawing/panning gesture handling and above the page footer.
- **Pinch zoom:** Two fingers zoom continuously between 50% and 200%, anchored at their focal point; moving both fingers pans the map. After a pinch, −/+ moves to the next lower/higher 25% step. A pinch during land selection restores the previous preview and suppresses drawing until all fingers are lifted. Pinching never selects a building. Single-finger panning and mouse land selection remain supported.
- **Timing and copy:** Phases change every 5 seconds (25 seconds per day). Use short player-facing labels such as Queued, Building apartments, Building parking and Ready to open. Keep phase order and financial scheduling in the rules; avoid verbose settlement/construction explanations in status labels. Deferred building types/upgrades use Coming soon.
- **Selection:** Tapping on a plot of land, building, or room selects it and opens relevant context menus.
- **Drag & Drop:** Used specifically during the building planning phase to draw and estimate the land area footprint (width and length) on the grid.
- **Automatic roads:** Preview a road around the drawn building footprint. After successful placement occupies the empty plot, create the surrounding road automatically. Use the approved district artwork/style, distinguish road space from usable building land and show road conflicts in placement feedback. The player does not manually draw these roads.
- **Restriction:** No virtual analog sticks or on-screen directional pads are used.

## User Interface (UI)
- **Main Menu / Profile Selection:** Upon launching the game, the player is presented with up to 5 profile save slots. They can load an existing CBD or start a new one.
- **Start Screen (New Profile):** A prompt for the user to enter the name of their new CBD Area.
- **Navigation Flow:**
  1. **Area Map:** View the CBD, pan the camera, or tap existing buildings.
  2. **Construction Wizard:** Triggered when building on empty land. Prompts for Building Type -> Drag & Drop Land Area -> Input Above-Ground Floors & Review Calculated Room Capacity -> Confirm Cost. Rooms per floor are derived from the footprint, as defined in Rules.md and Logic.md; they are not manually entered.
  3. **Building View:** Selecting a building replaces the area map with that building's selected floor detail. Enter at Floor 1, showing front cutaway room modules. Keep **Exit building | Go up | Go down** at the bottom with a persistent **Current floor: Floor 1/B1** label. The starter connects Floor 1 directly to completed B1 parking, skipping floor zero; disable movement beyond available floors. B1 contains parking only. Exit restores the map camera. Content scrolls independently of navigation in portrait and landscape. Future floors/upgrades remain subject to their catalog gates.
  4. **Floor/Tenant View:** Manage specific rooms and tenants on a selected floor via tap menus.
- **Hosted footer clearance:** On Web building detail, reserve 64 px beneath the bottom navigation so the hosting badge cannot cover Go down on narrow screens. Android uses normal safe-area spacing.
- **HUD:**
  - Top bar: Area Name, Current funds, premium currency.
  - Bottom/Side bar: Build menu, Tenant menu, Upgrades menu.

## Component Design Kit

### Identity

Use the square **BM tower** mark beside **Building Management Tycoon**. The B has two inset window openings and joins the M's upright and tower crown. The master SVG is [`../design/brand/bm-tower.svg`](../design/brand/bm-tower.svg); usage and regeneration instructions are in [`../design/brand/README.md`](../design/brand/README.md). Colors are evergreen `#203B3A` and ivory `#F5F3EB`. Keep the artwork square with flat colors and clear spacing from the title.

See [DesignKit.md](DesignKit.md) for the current Canva workspace, shared component rules, states, responsive layouts, artwork requirements, and unresolved mechanics. All 16 boards use one canvas size, Trebuchet MS typography, shared spacing and tactile control styles, the same illustrated asset family, and the defined square BM title lockup. Exteriors and placement use an isometric view; room and transport modules use a front cutaway view. Mustard apartments, coral hotels, blue offices and mint food courts share cream structures and evergreen contours. The builder, artwork, prompt set and previews are in `../design/tycoon/`. Native Figma component variants, Auto Layout, and prototype connections would require a later Figma setup.

The user approved this latest design on 2026-10-11. The Flutter app reuses the defined BM mark for app branding, launcher/splash and Web icons. The runtime pack supplies approved sprites, modules and sequences; see [Assets.md](Assets.md). The apartment starter adds a responsive HUD, manually drawn footprint with road preview, cost review, finance statement, building/room/parking controls, phase overlays and catalog-driven resident idle animation. Its one-floor exterior maps approved roof/facade textures onto saved footprint geometry rather than displaying a canonical multi-floor preview as the built structure. Other character/lift/effect playback and audio remain pending. Trebuchet remains the reference target, with packaged Roboto/Noto Sans Thai as the offline fallback. See [Gameplay.md](Gameplay.md) and [Setup.md](Setup.md).

## Audio & Music
- **BGM:** Upbeat, relaxing elevator/bossa nova style music that evolves as the CBD grows.
- **SFX:** 
  - Lift ding sound when elevators arrive at a floor.
  - Cash register 'ka-ching' for money collection.
  - Construction sounds (hammering, drilling) when building.
  - Murmurs and ambient city noises.
