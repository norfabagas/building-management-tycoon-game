# Game component design kit

The user approved [catalog 2](FigmaCatalogProposal.md) on 2026-10-16. All four types and associated progression now have runtime implementations; [FigmaAssessment.md](FigmaAssessment.md) records evidence and verification limits. Starter-only deferrals below are historical. The original Figma archive remains raster boards/source SVGs; native atomization is still blocked by the Starter MCP quota and is not implied by reusable Flutter widgets.

The 2026-10-16 user override extends approved facade bays along rectangular footprint axes instead of scaling a square symbol on those plots. Square plots retain the original sprite. Roof geometry uses the same palette with a grey surface and cream trim. The clock now shows 24 hours at one hour per second, closes at 24:00 and interpolates daylight gradients. Earlier uniform-sprite and five-phase clock notes are historical; see Design.md and Logic.md.

## Figma archive — 2026-10-16

All repository graphics have been copied into the new [Building Management Tycoon — Game Design](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ). See [DesignArchive.md](DesignArchive.md) for the three-page organization, 348-file inventory, cleanup and restoration. This preserves original PNG boards and editable source SVGs. The native component/Auto Layout/prototype setup proposed later in this document remains future work; archive captions and asset collections use Auto Layout, but the board controls remain raster images. The approved Canva art and current game-contract documents remain authoritative for visuals and mechanics respectively.

## Status and sources

The user approved this latest artwork and design on **2026-10-11**. Treat it as the visual source for the Flutter application. Project bootstrap status, runtime font fallback and feature boundaries are in [Setup.md](Setup.md).

The user approved the apartment starter catalog on 2026-10-12. Runtime build/finance/room screens now use these controls and assets, with weekly Sunday rent and automatic roads. See [Gameplay.md](Gameplay.md) and [Economy.md](Economy.md). The Canva boards remain design references; their illustrative numbers do not override the new catalog.

Rebuilt from page 01 on 2026-10-11. Sources: Project.md, Design.md, Platform.md, Rules.md and Logic.md. The user rejected the previous asset quality and requested deleting the current Canva pages before rebuilding every board. The replacement follows the documented colorful, structured 2D tycoon art direction.

Current Canva kit: [Building Management Tycoon — Artwork and Game Design](https://www.canva.com/d/51ESDDCqVSdEOVT). [View the kit](https://www.canva.com/d/mhgdvu1vWz5pQbO). Design ID: `DAHXnq3BVcM`. Canva confirms **16 pages**, all **1600 × 1000**, with **320 editable text elements** and **74 image instances**. All header logos resolve to the same BM asset, `MAHXtwLStL4`.

Canva requires at least one page. Pages 2–16 were deleted first. The reviewed replacement pages were inserted in ascending order, then the remaining old page was deleted. No old board content remains in this current kit. Earlier separate generated designs and staging imports are historical drafts, not the current kit.

## BM tower identity

Reuse the defined square BM tower mark unchanged. Master: [`../design/brand/bm-tower.svg`](../design/brand/bm-tower.svg). Preview export: [`../design/brand/bm-tower.png`](../design/brand/bm-tower.png). Usage: [`../design/brand/README.md`](../design/brand/README.md).

Every board places the same 48 × 48 square beside the editable **Building Management Tycoon** title. Main-menu and HUD examples reuse the mark. Illustration generation never creates or replaces the logo. Old title strips and the rejected `design/system/` assets are historical sources.

## Shared visual rules

The 2026-10-14 feedback explicitly requests the approved apartment image as the map exterior. The starter now uses that image directly with uniform scaling/bottom anchoring, superseding its earlier facade/roof composition. The illustrated storeys remain a visual symbol; playable floors/capacity still follow the saved game rules. See Design.md and Assets.md for the current runtime contract.

- Canvas: 1600 × 1000 with 48 px outside margins. Pages ascend from 01 to 16; both headings and counters include the page number.
- Header: logo at (48, 28), title at (112, 32), divider at y=96, section heading at y=120. Shared footer at y=950 marks economy values as illustrative.
- Type: Trebuchet MS throughout, 39 px board headings, 26–30 px panel headings, 21–23 px body/actions, 16–18 px captions. Cover title and net totals use larger type.
- Palette: warm ivory canvas, cream surfaces, evergreen outlines and actions. Mustard apartments, coral hotels, blue offices and mint food courts retain labels as well as colors.
- Controls: 52 px buttons with a 4 px base, 2 px outline and 12 px corners. Panels use 18 px corners. Focus, pressed, disabled, selected and error examples reuse the same helpers.
- Artwork: one exterior atlas, one room atlas, one character atlas, one transport atlas and one district scene. Shared assets repeat across screens using native image crops. Native UI text and controls remain separate from images.
- Projection: isometric exteriors, district scene and placement grid. Room, parking, stair and lift modules use a front cutaway view for building management.
- Apartments/hotels use separate room modules; an office suite represents a whole-floor lease. Underground examples contain parking only.

## Board coverage

| Order | Board |
| --- | --- |
| 01 | Game identity, defined logo and district artwork |
| 02 | Apartment, hotel, office and food-court exterior sprites |
| 03 | District scene, isometric placement tiles and adjacency example |
| 04 | Furnished room modules, parking, standard/executive lifts and stairs |
| 05 | Resident, guest, corporate tenant, customer, maintenance and walking sprites |
| 06 | HUD, action/field states, phase order, achievements and decoration entry |
| 07 | Exactly five local profile slots |
| 08 | CBD map with context panel and navigation |
| 09 | Construction building-type selection |
| 10 | Manually drawn 3 × 2 footprint and placement review |
| 11 | Above-ground floors, calculated capacity, permanent sizing and cost review |
| 12 | Building cutaway, selected room, tenant context and basement parking |
| 13 | Tenant happiness and the parking occupancy gate |
| 14 | Luxury, parking, standard lifts and executive-lift limits |
| 15 | Noon closing, offline return and loss statements |
| 16 | Portrait bottom sheet, landscape and web side panels |

## Review findings and limits

- Rendered all 16 boards and inspected them individually. Corrected sprite crops and the building-view text overlap, and aligned the placement grid projection with the district scene.
- Verified the saved Canva page headings ascend 01–16 and the same BM header logo appears on all pages. Checked an actual Canva exterior thumbnail after import and retrieved the saved current map preview.
- The editable PPTX passes package, geometry, heading-fit, font and first-party import checks. Trebuchet MS is installed on this workstation. These checks do not imply native PowerPoint execution.
- Five PNG artwork sources and the unchanged BM logo remain separate from native labels and controls. Identical image bytes are deduplicated in the PPTX without changing the artwork.
- Daily +$600, two offline days +$1,200 and a loss of -$200 are illustrative examples that predate the economy selection. Apartment rent now pays only on in-game Sunday Noon; do not infer a fixed offline payout from days alone. Offline net is already applied and has no second claim action.
- The Canva game kit is a reference, not a playable prototype. Its original character atlas has a walking pose; the later [runtime asset pack](Assets.md) adds five registered idle/walk/stair sheets, vector structural pieces and other missing resources. Exteriors in the kit remain canonical silhouettes; gameplay must compose the supplied structural modules from saved dimensions and animate the supplied frames.
- The user selected the relaxed-idle model on 2026-10-12. Starting funds, capacity formulas, spending timing, billing calendar, tax rates and other selected parameters are in [Economy.md](Economy.md). Board prices/upkeep remain illustrative; the full catalogs and unlock thresholds are unfinished. The user also confirmed automatic roads surrounding newly occupied building plots; roads are now a required mechanic, while landscaping remains a decorative proposal. The Canva boards have not been revised for weekly apartment billing or automatic-road placement states.

## Canva workspace and future Figma setup

Canva boards group foundations, artwork, components, screens, and responsive layouts. For a future Figma implementation, use file name **Building Management Tycoon — Game Design** and the page structure below.

| Page | Contents |
| --- | --- |
| 00 · Read me | Sources, scope, illustrative data, open mechanics, flow map |
| 01 · Foundations | Color variables, type styles, spacing, radii, semantic icons |
| 02 · Components | Native reusable components and documented variants |
| 03 · Game artwork | Map tiles, buildings, rooms, parking, lifts, tenants, effects |
| 04 · Portrait screens | 390 × 844 frames, scroll regions and bottom panels |
| 05 · Landscape & web | 844 × 390 and 1440 × 900 frames; side panels |
| 06 · Prototype | Profile → naming → map → construction → building → floor → tenant; upgrades and reports |

Canva layouts do not provide native Figma component variants, Auto Layout, or prototype connections. If moved to Figma later, use the boards as visual references, create reusable native components with properties and variants, configure Auto Layout, bind variables, and connect prototype interactions. Do not publish a shared library without a separate request.

## Foundations

Warm ivory background, cream surfaces, evergreen outlines/actions and turquoise windows. Mustard apartments, coral hotels, blue offices and mint food courts share one illustrated architecture family. Labels and silhouettes distinguish building types alongside color.

| Token | Value / purpose |
| --- | --- |
| color/canvas | #F5F3EB |
| color/surface | #FFFCF1 |
| color/ink | #203B3A |
| color/muted | #66766D |
| color/primary | #237563 |
| color/land | #BBD995 |
| color/warning | #E9B754 |
| color/danger | #AF443F |
| color/office | #65B1C5 |
| color/apartment | #E9B754 |
| color/hotel | #E98D70 |
| color/food | #DBEBDD |
| type | Trebuchet MS; 39 board heading, 26–30 panel heading, 21–23 body/action, 16–18 caption |
| spacing | 4, 8, 12, 16, 24, 32 |
| radius | 12 controls, 18 panels, 8 status tags |
| interaction | Minimum proposed hit area 48 × 48; visible focus, pressed and disabled states |

All numbers, district names, prices, rates, capacities, unlock conditions, and tenant names in the boards are illustrative. They are not game balancing decisions.

## Component inventory

Every interactive component needs default, pressed, focus, disabled, and selected states where meaningful. Document properties and use instance text overrides instead of detached copies.

| Family / component | Properties and variants | Required behavior / source |
| --- | --- | --- |
| Action/Button | primary, secondary, destructive, icon; enabled/disabled | Clear action labels; touch/click only (Design) |
| Input/Field | empty, filled, focused, error | CBD name; floors input; validation values remain TBD |
| Input/Stepper | min, value, max, disabled | Above-ground floors; maximum not defined in rules |
| Feedback/Banner | info, warning, error, success | Explain blocked actions with a remedy |
| Panel/Context | bottom sheet, side panel, dialog | Plot, building, room selections; keep map visible |
| Navigation/Tab | map, tenants, upgrades; selected | Bottom in portrait, side in landscape |
| HUD/Area | district label, dollars, gems | Gems earned through achievements (Rules) |
| HUD/Time | day, weekday, Morning, Day, Afternoon, Night, Noon | Preserve phase order; show the in-game weekday and label Noon as closing |
| HUD/Currency | dollars, gems, reserved purchases, pending rent | Separate available funds, daily projection and next Sunday rent payment |
| Profile/Slot | empty, occupied, loading, load error | Exactly five local slots; no cloud/login (Platform) |
| Profile/Create | name field, continue action, error | Create in an empty selected slot |
| Map/Plot | empty, selected, occupied construction site, valid footprint/road surround, collision, boundary error | Drag defines the footprint; occupied plots automatically receive surrounding roads (Rules/Logic) |
| Map/Building | apartment, hotel, office, F&B, mall concept | Tap opens cross-section; malls are future scope |
| Map/Synergy | highlighted neighbors, bonus chip, no bonus | Show selected bonuses within the 15% cap; individual values remain catalog work (Logic) |
| Build/TypeCard | available, selected, locked | MVP availability and unlock thresholds are TBD |
| Build/StepHeader | type, footprint, floors/capacity, review | Back preserves entered plan; cancel returns to map |
| Build/Footprint | dimensions, selected grid area, surrounding-road preview, valid/invalid | Manually draw the footprint; roads are outside usable building land and generate on successful placement |
| Build/Capacity | residential rooms, office floor lease, F&B facility | Rooms calculated for hotels/apartments; don't apply room rules universally |
| Build/Cost | estimate, unaffordable, ready | Deduct the approved apartment quote immediately from Balance; cancellation refunds it immediately before opening |
| Build/PermanentSize | notice and review summary | Footprint and rooms per floor fixed; 2026-10-14 override permits floor upgrades up to 10 |
| Building/Summary | type, luxury, occupancy, parking | Parking quota limits occupancy |
| Building/CrossSection | selected floor, above ground, B1/B2/B3 | Pan vertically; underground strictly parking |
| Building/Stairs | idle, moving tenant | Stairs exist by default |
| Building/LiftShaft | standard/executive, none, moving carriage | Standard max 3, executive max 1 |
| Floor/Row | rooms, leased office, F&B, underground parking | Negative floor indices for basements (Logic) |
| Room/Tile | vacant, occupied, selected, blocked | Capacity gate includes parking; exact tenant assignment rules TBD |
| Tenant/Card | apartment resident, hotel guest, corporate lease | Office tenancy is by whole floor, hotel occupancy is daily |
| Tenant/Needs | happy, lift concern, parking capacity issue | Explain needs and link to relevant upgrade |
| Traffic/Summary | F&B customers, parking visitors, occupancy cap | Daily sales and parking demand differ from residential rentals |
| Upgrade/Card | available, unaffordable, maximum, unavailable, in progress | Apartment floors (10 total), parking (3), standard lift (3), executive lift (1); luxury deferred |
| Upgrade/Review | price, benefit, added daily maintenance, duration | Show the approved $40/day added upkeep for each apartment upgrade; don't hide recurring cost |
| Parking/Quota | current, near cap, full; B0–B3 | Max three basements; no non-parking rooms underground |
| Finance/Statement | profit/loss, cash gross, maintenance, tax, net, pending apartment rent | Net = cash gross − maintenance − tax; apartment rent received only at Sunday Noon, others daily |
| Finance/OfflineSummary | positive, negative, zero elapsed | Batch net after away time; already applied, no second claim |
| Achievement/Card | locked, progress, earned | Grant offline gem rewards once with saved completion; achievement definitions remain TBD |
| Decoration/Card | preview, affordable, unaffordable | Gem decorations in rules; catalog TBD |
| Effect/Feedback | dust, coin, lift arrival | Coin effect must not imply per-tap revenue collection |

## Game artwork inventory

Use the shared PNG sprite atlases in `design/tycoon/assets/` and the district scene as the approved artwork sources. Runtime exports are in `assets/game/`; [Assets.md](Assets.md) describes all 158 resources, generation sources, animation contracts and coverage. Keep UI labels and controls native and editable. Supplied structural modules retain the shared view angles and palette; engine composition and playback remain gameplay work.

| Asset | Variants / states |
| --- | --- |
| Grid land | empty, selected, footprint/road-space valid/invalid, occupied plot with automatic surrounding road; greenery remains decorative |
| Exteriors | apartment, hotel, office, food court/restaurant; repeatable lobby/floor/roof pieces and three luxury previews; mall reserved for future |
| Room interiors | apartment, hotel, corporate office, food facility; vacant/occupied/selected |
| Transport | stairs, standard lift, executive lift, shaft, carriage |
| Basement parking | B1/B2/B3 floor label, bay, occupied bay, capacity indicator |
| People | resident, guest, office tenant, customer, maintenance; four idle, eight walk and four stair frames per actor; leftward mirror |
| Currency and symbols | dollar, gem, parking, luxury, happiness, maintenance, tax, synergy |
| Effects | eight-frame construction dust, financial-closing coin feedback and lift arrival sheets |
| Phase ambience | Morning, Day, Afternoon, Night, Noon/closing overlays; keep labels legible |

Animation frame order, pivots and timing are supplied in the runtime manifest. Hold neutral frames and omit optional effects for reduced motion; engine integration must preserve these contracts.

## Screens and prototype flow

The saved Canva kit contains 16 visual boards covering the families listed above. The component inventory specifies full desired state coverage; the first visual kit does not draw every variant or animation frame.

1. Profile selection → empty slot → name CBD → empty map; occupied slot → local load → offline summary if applicable → map.
2. Empty plot → building type → draw footprint with surrounding-road preview → floors and computed capacity → review permanent sizing/cost and road space → confirm → occupied construction site with automatically generated road → map. Block footprint/road conflicts, invalid boundary placements and unaffordable estimates. Failed/canceled placement leaves no generated road.
3. Map building → cross-section → floor → room/tenant panel. Offices lease whole floors; F&B shows sales/traffic; parking shows bays/quota.
4. Building → upgrades → review purchase plus recurring costs → apply → cross-section. At B3, three standard lifts or one executive lift, show maximum state.
5. Daily closing → cash gross/maintenance/tax/net breakdown → return to map. Show apartment pending rent and the next Sunday payment separately; hotel, office, F&B and parking receipts settle daily. During phases, display projections without claiming they have entered the wallet.
6. Achievement → progress/earned → gem balance; decoration path uses gems and remains a concept until catalog/rules exist.

Prototype acceptance: drag pans map and building; taps open context panels; no virtual joystick or D-pad. Wrong/blocked actions retain context and show an actionable explanation. Five profile slots save locally; no account, cloud sync, ad store, or online payment flows.

## Responsive constraints

- Portrait: compact HUD, bottom navigation, bottom context sheet; allow underlying map/building pan when sheet permits.
- Landscape: HUD at top, map/cross-section expands horizontally, context panel on right, navigation on left or beneath HUD. Use scroll for long panel contents.
- Wide web/tablet: canvas fills available area; constrain panel width to a proposed 320–400 px; do not scale mobile UI to fill the screen.
- Preserve selection and wizard state when orientation changes. Keep floors/rooms readable while panning and keep controls outside safe areas.
- Keyboard focus is proposed for web usability; drag/click remains the primary documented input.

## Economy selection and remaining mechanics

**Option 1: Relaxed idle is selected**, with weekly apartment rent at in-game Sunday Noon and other income daily at Noon. [Economy.md](Economy.md) records the decisions and billing conventions. [EconomyOptions.md](EconomyOptions.md) retains the original comparison.

1. Selected spending: reserve purchase prices immediately and settle them once at the next Noon. Show available funds separately; pending apartment rent cannot fund reservations.
2. Selected initial parking: the starter quote includes a separate B1 job, with occupancy blocked until it finishes. Underground starts at zero; no external-parking rule is introduced.
3. Selected: $40,000 starting funds, five-minute days, two-day starter shell plus one-day B1, footprint-derived rooms/parking, three luxury tiers, 15% synergy cap and daily 0.05% valuation + 2% received-revenue tax. Finalize catalog prices, weekly apartment rents, upkeep coefficients, happiness, turnover, bonus tables, unlock thresholds and non-starter build durations.
4. Confirm initial playable building catalog. Malls are explicitly future; hotel/office MVP availability is not fixed.
5. Selected: achievements grant gems once, acceleration costs one gem per remaining game day rounded up, offline simulation is uncapped and preserves Sunday rent, and backward device-clock changes add no elapsed time. Finalize achievement/decoration catalogs, durable save-error recovery, tenant actions and paid-order refunds.
6. Selected: newly occupied plots automatically receive roads around the building footprint. Finalize road width/corners, district-edge policy and any road costs/upkeep before implementing placement; reuse compatible road segments and preserve existing buildings.

## Source and review

Builder: [`../design/tycoon/build.mjs`](../design/tycoon/build.mjs). Source export: [`../design/tycoon/output/Building-Management-Tycoon-r5.pptx`](https://github.com/norfabagas/building-management-tycoon-game/blob/bbd6d283bd6b623682841af63e74215c454fee8a/design/tycoon/output/Building-Management-Tycoon-r5.pptx). Full-size previews: `design/tycoon/previews/`. Overview: [`../design/tycoon/overview.png`](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=2-19). Assets and regeneration: [`../design/tycoon/README.md`](../design/tycoon/README.md). Built-in Imagegen prompt set: [`../design/tycoon/prompts.md`](../design/tycoon/prompts.md).

Review Canva page thumbnails and actual content against the documented rules. Check text readability, clipping, parking/occupancy consistency, five profile slots, calculated room capacity, upgrade limits, and financial-closing wording. Record the design URL, generated page count, and material gaps here. Native Figma setup, interactive prototype behaviors, and final animation artwork are separate steps.
