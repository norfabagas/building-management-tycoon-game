# Design Document

## Visual Style
- **Perspective:** Strictly 2D view (X and Y axis only). E.g., a cross-section or side-view of a building.
- **Art Direction:** Clean, colorful, and slightly stylized (cartoony but structured). Easy to distinguish different room types at a glance.
- **Animations:** Idle animations for tenants, construction dust for building new rooms, coin pop-ups for revenue collection.
- **Orientation:** UI and gameplay must gracefully adapt to both Portrait and Landscape orientations on mobile devices and web browsers.

## User Interface (UI)
- **Responsive Layout:**
  - *Portrait:* Menus stacked at the bottom or collapsible from the side.
  - *Landscape / Web:* Wider viewing area, with menus potentially docked on the left/right edges or horizontally across the bottom.
- **HUD:** 
  - Top bar: Current funds, premium currency, building level.
  - Bottom/Side bar: Build menu, Staff menu, Upgrades menu.
- **Pop-ups:** Detail screens for individual rooms or tenants when tapped.

## Audio & Music
- **BGM:** Upbeat, relaxing elevator/bossa nova style music that evolves as the building grows.
- **SFX:** 
  - Cash register 'ka-ching' for money collection.
  - Construction sounds (hammering, drilling) when building.
  - Murmurs and ambient city noises.
