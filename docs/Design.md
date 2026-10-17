# Design Document

## Delete saved profiles — 2026-10-17

Add a labelled red Delete control beneath Load on occupied profile cards. Confirm the full district name and slot with a permanent-progress warning, Cancel and Delete permanently. Keep the dialog open with retryable errors, disable duplicate actions/back during commit and show the freed New slot after success. Preserve responsive scrolling and the approved BM artwork. See [DeleteProfiles.md](DeleteProfiles.md).

## Full-screen tenant activity — 2026-10-17

Room/lease cards and tenant-directory rows now open a full-screen illustrated interior instead of immediately showing a management dialog. Show live time, current routine and all four daily activity windows, plus actual unit/building status. Food floor artwork opens dining activity. Back retains the floor; Manage opens the existing confirmation. See [TenantInterior.md](TenantInterior.md) for responsive, artwork and ambient-animation limits.

## Volumetric figures and visible floors — 2026-10-17

The user requests volumetric outdoor characters and exteriors that grow when above-ground floors finish. Replace side-view map billboards with articulated XYZ people and cars, depth-shaded and rotated with their world heading. Preserve the isometric map, role colors and approved facade artwork. Build every square/rectangular exterior from one ground-storey strip plus repeated upper-storey strips, with one roof at the completed floor height. Actors passing in front remain whole; only nearer buildings occlude them. This supersedes the fixed square-sprite/height contract below. See [VolumeAndHeight.md](VolumeAndHeight.md).


## District streets and ambient activity — 2026-10-17

A broad two-lane highway with a dashed centre line provides a visible starting edge for expansion. Existing approved road tiles connect building rings and public access streets to it. **Main road** focuses the camera on the highway; pinch and zoom retain their existing projection. Planning explains adjacency and shows Road access in the cost panel. Invalid/disconnected previews remain red and cannot be confirmed.

Open buildings gain two small walkers from their matching resident/guest/office/customer family and a blue car. Paths follow rounded sidewalk/lane loops around the actual footprint, including long rectangles. Faces occlude actors passing behind them; movement is continuously interpolated and tinted by the existing daylight gradient. Respect reduced motion and stop hidden-map activity. Reuse catalog artwork; no new generated art or changes to the BM master. See [DistrictRoads.md](DistrictRoads.md).


## Current override — 2026-10-16

The follow-up [gameplay audit](GameplayValidation.md) prioritizes the selected-floor artwork over generic metadata, retains building-wide information in Building details, uses a compact short-landscape HUD with overview beside floor content when width permits, and keeps coin feedback inside the Balance icon without layout shifts. Build cards explain actual base revenue and B1 cost; cost review exposes remaining cash and B1-supported versus total units. A completed-building map shortcut leads to explicit opening review, including in portrait. These are information hierarchy and feedback changes within the approved artwork and economy.

The full-Figma audit is tracked in [FigmaAssessment.md](FigmaAssessment.md). The user approved [catalog 2](FigmaCatalogProposal.md); four types, initial-floor input, luxury, needs, synergy, achievements/gems, decorations, local audio and motion now have domain behavior and reachable controls. Directories open the actual saved floor/catalog and return to their originating directory on exit. Wide build selection uses four cards; narrow selection stacks them. Use the correct exterior/interior/vacancy/actor family, whole-office leases and F&B facilities. Colors, BM identity and bundled fallback fonts remain unchanged. The 24-hour single-Balance HUD and selected-floor view override older board examples. Camera, plans and selected floors survive resizing; two-finger pinch/pan and the existing footer clearance remain supported.

The 2026-10-16 request overrides square exterior scaling on rectangular plots. Rectangular buildings follow both projected footprint axes: repeat approved facade texture bays along long walls and shape the grey roof and cream trim to the actual roof polygon. Keep a stable height based on the short side; square plots retain the original approved sprite. Drawing, bounds and picking share geometry. No new building capacity or price comes from the exterior. The HUD shows 24-hour HH:mm time, 1 hour per real second, and closing at 24:00. Replace abrupt phase PNG changes with continuously interpolated directional daylight gradients, including a continuous midnight wrap; keep overlays below controls.

Long offline/resume time jumps now choose a short cyclic daylight transition instead of animating through every missed day. Normal clock updates still move forward across midnight; reduced motion applies lighting immediately. This avoids strobing during catch-up without changing simulation time or settlement.

The 2026-10-16 [Figma design archive](DesignArchive.md) now hosts repository design references and large originals. Use its manifest links and restore exact sources when regenerating assets; the BM master and all runtime exports remain in Git. Native interactive board components/prototypes are outside this archival migration.

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
- **Upgrades (2026-10-14):** Place **Upgrade building** beside the building title, accessible from any floor. Show four cards with approved apartment/parking/standard/executive lift artwork, current/maximum counts (10 floors, 3 basements, 3 lifts, 1 executive lift), price, added daily upkeep and construction time. Review before confirming. Support maximum, unaffordable, unopened and active-job disabled states; allow cancellation with a full immediate refund before an upgrade completes. Show active upgrade progress on the map and detail. Keep business open during upgrades. Floor controls cover completed Floor 1–10 and B1–B3, skipping zero; use separate room IDs/content per floor and per-basement parking usage. Render installed lift modules with their counts. Lift happiness/rent effects remain deferred.
- **Building artwork:** As requested on 2026-10-14, render the approved apartment exterior (`assets/game/buildings/apartment.png`) directly on the map, uniformly scaled to the plot's projected width and bottom anchored. Do not replace it with the former remapped facade/roof box. The design image is a visual symbol, not a source of extra playable floors/capacity. Both its visible facade rectangle and ground footprint select the building; use the same visual depth order for drawing and picking.
- **Construction and opening:** Show a progress bar and percentage on the map and building detail. The apartment job contributes 2/3 and B1 contributes 1/3, based on game-time progress. At completion show 100% and **Open to Business** in the building detail. The building remains closed until that button is pressed. Admissions begin at the following Morning; already open saved buildings stay open.
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
  - Top bar: Area Name, one **Balance** chip and the day/phase countdown. Remove Dollars/Available duplicates and the pending-rent HUD chip. Uncollected rent remains in financial/building detail as a receivable, never a second spendable wallet.
  - Bottom/Side bar: Build menu, Tenant menu, Upgrades menu.

## Component Design Kit

### Identity

Use the square **BM tower** mark beside **Building Management Tycoon**. The B has two inset window openings and joins the M's upright and tower crown. The master SVG is [`../design/brand/bm-tower.svg`](../design/brand/bm-tower.svg); usage and regeneration instructions are in [`../design/brand/README.md`](../design/brand/README.md). Colors are evergreen `#203B3A` and ivory `#F5F3EB`. Keep the artwork square with flat colors and clear spacing from the title.

See [DesignKit.md](DesignKit.md) for the current Canva workspace, shared component rules, states, responsive layouts, artwork requirements, and unresolved mechanics. All 16 boards use one canvas size, Trebuchet MS typography, shared spacing and tactile control styles, the same illustrated asset family, and the defined square BM title lockup. Exteriors and placement use an isometric view; room and transport modules use a front cutaway view. Mustard apartments, coral hotels, blue offices and mint food courts share cream structures and evergreen contours. The builder, artwork, prompt set and previews are in `../design/tycoon/`. Native Figma component variants, Auto Layout, and prototype connections would require a later Figma setup.

The user approved this latest design on 2026-10-11. The Flutter app reuses the defined BM mark for app branding, launcher/splash and Web icons. The runtime pack supplies approved sprites, modules and sequences; see [Assets.md](Assets.md). The apartment starter adds a responsive HUD, manually drawn footprint with road preview, cost review, finance statement, building/room/parking controls, phase overlays and catalog-driven resident idle animation. The 2026-10-14 feedback replaces the remapped exterior with the approved apartment image and adds construction progress/manual opening. One playable floor and capacity still come from the game rules and saved footprint. Other character/lift/effect playback and audio remain pending. Trebuchet remains the reference target, with packaged Roboto/Noto Sans Thai as the offline fallback. See [Gameplay.md](Gameplay.md) and [Setup.md](Setup.md).

## Audio & Music
- **BGM:** Upbeat, relaxing elevator/bossa nova style music that evolves as the CBD grows.
- **SFX:** 
  - Lift ding sound when elevators arrive at a floor.
  - Cash register 'ka-ching' for money collection.
  - Construction sounds (hammering, drilling) when building.
  - Murmurs and ambient city noises.
