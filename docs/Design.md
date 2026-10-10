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
- **Restriction:** No virtual analog sticks or on-screen directional pads are used.

## User Interface (UI)
- **Main Menu / Profile Selection:** Upon launching the game, the player is presented with up to 5 profile save slots. They can load an existing CBD or start a new one.
- **Start Screen (New Profile):** A prompt for the user to enter the name of their new CBD Area.
- **Navigation Flow:**
  1. **Area Map:** View the CBD, pan the camera, or tap existing buildings.
  2. **Construction Wizard:** Triggered when building on empty land. Prompts for Building Type -> Drag & Drop Land Area -> Input Floors & Rooms -> Confirm Cost.
  3. **Building View:** Zoom into a building to view its floors (drag up for high levels, drag down for underground). Tap a floor to manage it or trigger Luxury Upgrades (including purchasing Lifts and Underground Expansion).
  4. **Floor/Tenant View:** Manage specific rooms and tenants on a selected floor via tap menus.
- **HUD:** 
  - Top bar: Area Name, Current funds, premium currency.
  - Bottom/Side bar: Build menu, Tenant menu, Upgrades menu.

## Audio & Music
- **BGM:** Upbeat, relaxing elevator/bossa nova style music that evolves as the CBD grows.
- **SFX:** 
  - Lift ding sound when elevators arrive at a floor.
  - Cash register 'ka-ching' for money collection.
  - Construction sounds (hammering, drilling) when building.
  - Murmurs and ambient city noises.
