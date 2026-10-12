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
  3. **Building View:** Zoom into a building to view its floors (drag up for high levels, drag down for underground). Tap a floor to manage it or trigger Luxury Upgrades (including purchasing Lifts and Underground Expansion).
  4. **Floor/Tenant View:** Manage specific rooms and tenants on a selected floor via tap menus.
- **HUD:** 
  - Top bar: Area Name, Current funds, premium currency.
  - Bottom/Side bar: Build menu, Tenant menu, Upgrades menu.

## Component Design Kit

### Identity

Use the square **BM tower** mark beside **Building Management Tycoon**. The B has two inset window openings and joins the M's upright and tower crown. The master SVG is [`../design/brand/bm-tower.svg`](../design/brand/bm-tower.svg); usage and regeneration instructions are in [`../design/brand/README.md`](../design/brand/README.md). Colors are evergreen `#203B3A` and ivory `#F5F3EB`. Keep the artwork square with flat colors and clear spacing from the title.

See [DesignKit.md](DesignKit.md) for the current Canva workspace, shared component rules, states, responsive layouts, artwork requirements, and unresolved mechanics. All 16 boards use one canvas size, Trebuchet MS typography, shared spacing and tactile control styles, the same illustrated asset family, and the defined square BM title lockup. Exteriors and placement use an isometric view; room and transport modules use a front cutaway view. Mustard apartments, coral hotels, blue offices and mint food courts share cream structures and evergreen contours. The builder, artwork, prompt set and previews are in `../design/tycoon/`. Native Figma component variants, Auto Layout, and prototype connections would require a later Figma setup.

The user approved this latest design on 2026-10-11. The Flutter bootstrap reuses the defined BM mark for app branding, launcher/splash and Web icons, and bundles the approved artwork. The responsive profile screen and initial empty district canvas follow the shared palette and controls. The Trebuchet reference remains the typography target; packaged Roboto/Noto Sans Thai provide an offline runtime fallback until a distribution-ready reference font is supplied. See [Setup.md](Setup.md) for that implementation boundary.

## Audio & Music
- **BGM:** Upbeat, relaxing elevator/bossa nova style music that evolves as the CBD grows.
- **SFX:** 
  - Lift ding sound when elevators arrive at a floor.
  - Cash register 'ka-ching' for money collection.
  - Construction sounds (hammering, drilling) when building.
  - Murmurs and ambient city noises.
