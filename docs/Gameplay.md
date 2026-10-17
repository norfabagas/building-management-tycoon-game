# Game gameplay

## Volumetric figures and visible floors — 2026-10-17

The exterior now exposes actual completed above-ground storeys, including existing saves and 1–10 initial floors. Completing an upward upgrade raises the roof and expands the clickable upper facade without moving land, roads or the bottom anchor. Outdoor people/cars have rotating shaded XYZ bodies; front-side walkers are no longer clipped by their own facade. See [VolumeAndHeight.md](VolumeAndHeight.md).


## Connected streets and activity — 2026-10-17

Build beside the highway or extend an existing connected ring. The Road access review line and red/green preview use the domain placement rule; disconnected construction is rejected before payment. Main road brings the highway back into view. Existing saves receive free access around occupied plots; bridge cancellation retains streets needed by neighbours and still refunds the full building quote. Open businesses display walkers and vehicles, with no activity at unfinished or ready-to-open sites. Full details and validation are recorded in [DistrictRoads.md](DistrictRoads.md).


## Acceleration review safety — 2026-10-17

An acceleration review applies to the displayed work only. If time advances and another job replaces it, confirmation displays “The job changed. Review acceleration again.” without spending gems, even when both jobs have the same price. Use Retry to synchronize and review the current job. The dialog scrolls in short viewports. Existing costs, next-Morning completion, manual business opening and refunds remain as defined in the approved catalog.

## Gameplay quality audit — 2026-10-16

Type cards now explain base income and B1 cost. Purchase review shows the remaining cash and how much of the completed capacity B1 can actually support; demand, bonuses and tax remain separate. Completed unopened businesses have a map shortcut to the explicit opening review. Selected-floor rooms/facilities precede generic building accounting, with larger room cutaways and expandable Building details. Short landscape uses a compact HUD and side-by-side overview/floor where width allows; fixed floor navigation/footer clearance remain. Closing coins animate over the Balance icon without moving the map. See [GameplayValidation.md](GameplayValidation.md) for findings, the preserved economic contract, offline performance, tests and remaining limits.

## Four-type Figma implementation — 2026-10-16

The user approved [catalog 2](FigmaCatalogProposal.md) and requested GitHub push and Netlify publication. Earlier starter-only boundaries below are historical. Build now offers Apartment, Hotel, Office tower and Food court, with four canonical cards on wide screens and responsive cards on narrow screens. Select 1–10 initial floors after drawing land; review type-specific rooms/whole-floor leases/party capacity, B1, cost, upkeep and duration. Permanent land, surrounding roads, immediate charging, full unfinished refunds and manual opening remain intact.

Hotel guests refresh each Morning and pay daily; offices lease whole floors with weighted bay reservations; Food Court parties turn over in four windows, storing daily visits/sales/parking for midnight. Each uses the correct room, vacant shell and actor family. Apartment Sunday rent and old pending ledgers are preserved. Tenant/guest/lease contexts show their actual rate, bay reservation and happiness. Luxury, lift access and capped neighbor synergy affect only approved new demand/revenue. All-type floor/basement/lift/luxury upgrades use their own costs/durations and saved limits. Acceleration reviews the active job and gem cost, activates next Morning and never skips manual opening.

Build, Tenants, Upgrades and Finances are reachable from the map; District activities opens Achievements and Decorations. Saved one-time achievements award gems automatically. Decoration review/cancel is free; confirmation spends the specified gems; moving is free and cannot overlap plots, roads or other decorations. Finances separates receivables, daily Hotel/Office/Food Court income, parking, expenses/tax and purchase/refund history. A copy of the simulation estimates the next closing without advancing the real save or granting rewards. Loss states use red feedback; offline net is already applied and has no duplicate claim action.

All five role animation sheets, stair/walk poses, lift carriages/doors, construction dust, cash-closing coins and arrival effects are integrated. Reduced motion holds neutral frames and omits optional effects. Local music evolves at two/four open businesses; ambience, construction, closing, lift and UI effects use bundled WAVs. Sound starts muted, uses an explicit gesture and stores its preference per profile. After reload or lifecycle pause, Resume sound requires a new gesture; playback failure does not affect saving. No remote audio, accounts, analytics, ads, payments or services were added.

Two fingers zoom/pan around their moving focal point between 50% and 200%; buttons retain 25% steps. Pinching restores the previous construction/decoration preview and suppresses trailing-finger placement/selection. The camera belongs to the screen session so resizing preserves zoom/pan; selected floors and plans also survive layout changes. Portrait panels and landscape floor content scroll beneath fixed navigation, with the existing Web footer clearance retained.

See [FigmaAssessment.md](FigmaAssessment.md) for the 16-board assessment, tests/builds, visual checks and limits. Current live Figma inspection/native component editing remains quota-blocked; implementation follows the verified archive and approved overrides. Large originals, review fixtures and screenshots remain ignored rather than reintroduced into Git.

## Current clock and exterior override — 2026-10-16

The day is now 24 game hours at 1 hour per real second. The HUD shows HH:mm; 24:00 closes the completed day exactly once, then advances the weekday and starts the next Morning's actions. Sunday rent still includes Sunday's accrual, and purchases/refunds remain immediate. Legacy clock saves migrate atomically to schema 6 after catch-up at their previous speed; completed closing IDs and all saved progress are preserved. Earlier Noon/25-second descriptions below are historical.

Rectangular apartment exteriors follow saved width/length on the two projected land axes, using repeated approved facade textures and a proportional grey roof. Square plots retain the original illustration. The source sprite's storey count is still illustrative and does not grant capacity. A cyclic directional gradient smoothly interpolates changing daylight rather than swapping phase PNGs. None of these changes add online play or change economy coefficients.

The user approved this starter implementation on 2026-10-12. Follow [Economy.md](Economy.md) for the explicit starter catalog and original weekly apartment billing contract. The empty-canvas bootstrap is replaced with a buildable district.

## Apartment upgrades — 2026-10-14

Current money behavior: the HUD has one **Balance**. Confirming a building or upgrade deducts its full price immediately. Cancel a building before opening or an unfinished upgrade to receive the full purchase refund immediately. Already-incurred expenses remain charged; open buildings/completed upgrades cannot be canceled. Closings only settle operating income/costs, with purchase/refund amounts shown as history. The old reservation screenshots below are retained as earlier evidence.

Schema 5 stores purchase/refund history and migrates schemas 1–4 atomically before catch-up: deduct only old queued orders, never already-paid work. Migration/refund tests cover retry/rollback and no duplicate charges or taxable refunds. All 75 tests pass, including single-balance confirmations and refunds at portrait, landscape and desktop sizes; the final money/UI subset passes all 23 tests. Formatting, analysis, asset validation and release Web build pass. Android compilation remains blocked by the missing SDK. PROJECTS.md records deployment.

Browser review of an ignored in-memory fixture verifies $40,000 → $30,000 immediately for a $10,000 building, then $30,000 → $40,000 when canceled during construction. The next closing retains that balance and lists the refund as history with zero income/tax. The temporary tab/server are closed; no production saves were changed.

[Single Balance after the immediate building charge](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-158)

[Immediate cancellation refund and removed plot](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-159)

[Refund history without a second wallet](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-172)

Select a building, then **Upgrade building** beside its title. The menu shows Add floor (10 total), Add basement (3 total), Standard lift (3) and Executive lift (1), with counts, price, time and added upkeep. Review and confirm each purchase. Initial construction must be open first. One upgrade can run per building; an unfinished upgrade can be canceled for an immediate full refund. Existing business continues during work. The map and building detail display the active job's progress.

The user approved the [upgrade catalog](Economy.md): reuse existing floor/basement rates and times; standard lifts cost 1/4 of the original floor+B1 price, executive lifts 1/2, both take 1 game day and add $40/day upkeep. Lift rent/happiness effects are deferred. Deduct the price from the single Balance immediately; queue through the next Noon, start the following Morning and complete at the final Noon. Completed work adds upkeep/valuation and available capacity; admissions continue next Morning under total parking capacity. Initial manual opening remains required; upgrades keep already-open buildings open.

Above-ground floors now expand after initial construction, superseding the earlier one-floor restriction and permanent-floor rule. Footprint/roads/rooms-per-floor remain fixed. Floor detail and the fixed toolbar reach all completed floors and B1–B3, skipping zero. Each floor has its own stable room IDs; each basement shows its portion of occupied parking bays. Installed lift modules/counts appear inside the building; exterior artwork remains the approved visual symbol.

Schema 4 adds completed level/lift counts and one upgrade order. Schemas 1/2/3 retain their original one floor/B1, zero lifts, rooms, rent and initial manual-opening state on migration. Limits, room/bay bounds and job state are validated, and transactions protect purchases/catch-up from failed writes and competing requests. Old clients reject schema 4; close older game tabs before reopening the update.

Validation: formatting, analysis, all 68 tests and release Web build pass, including queued completion through every maximum, tax/upkeep, parking-limited admissions across floors, fixed lift quotes, migration, offline parity and rollback/concurrent reservations. UI tests cover phone portrait, landscape and desktop review/cancel/confirm, upper-floor room IDs, B3 navigation and disabled maximums. Asset validation passes 158 resources/124 frames. Android debug compilation is blocked by the missing Android SDK. An isolated ignored in-memory browser fixture verifies actual review/reservation/progress/completion, Floor 2 admissions and portrait/landscape controls without editing production saves.

[Upgrade building beside the apartment title](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-170)

[Upgrade cost, construction time and added upkeep review](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-171)

[Standard and executive lift cards with original-price quotes](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-173)

Browser review also confirms standard lift completion, unchanged original-price quotes after adding Floor 2, and the installed lift module/count beside the stairs. The temporary review tab and server are closed; the fixture is not shipped.

[Completed standard lift beside the stairs](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-162)

## Player flow

Feedback update on 2026-10-14: phases now last **5 seconds**, giving a **25-second game day**. Construction status labels are short (Queued, Starts tomorrow, Building apartments, Parking queued, Building parking, Ready to open, Open); finance/build/tenant text uses direct player wording. Phase names and the per-game-day economy still follow Rules.md.

Validation: formatting, analysis and all 43 tests pass. Browser review on an isolated localhost origin confirms the faster calendar, short statuses and mouse construction flow. Synthetic two-finger tests cover both zoom limits, existing/empty preview restoration, trailing-finger suppression and building picking after pinch. Migration tests cover old-speed catch-up, fractional progress, rollback and unchanged/backward clock handling. Physical mobile gestures remain unverified without a device.

[Short construction status and five-second phase countdown](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-164)

Load an existing district or create one of the five local slots. Existing metadata-only profiles receive an empty game snapshot with $40,000 at first gameplay load; their names and slots are preserved. Choose Build, select Apartment, draw a footprint on the map, review its derived rooms, B1 bays and costs, then confirm. Roads and the occupied construction plot are saved together. Buildings can be canceled for an immediate full purchase refund until they are opened; unfinished upgrades can also be canceled for a full refund.

Payment is immediate, the queue transitions at the next Noon and construction starts the following Morning, shell construction lasts two game days and B1 lasts one. Once both jobs complete, the building waits at 100% for **Open to Business**. Tenant admissions begin at the next Morning after opening. Apartments accumulate rent for actual occupied days and pay at in-game Sunday Noon. Parking, expenses and taxes settle daily. Completed upkeep/valuation taxes continue while closed. The HUD shows one Balance. Financial detail shows uncollected rent, next Sunday payment and the last closing, with purchases/refunds recorded as history. Select a building to view rooms and parking; vacating a room preserves accrued rent.

The map uses the approved apartment exterior image directly, preserving its square aspect ratio and anchoring it to the plot's projected bottom. Its illustrated storeys do not change the one-floor starter or saved capacity. Both the facade and plot are clickable, using the same drawing/picking depth order. Construction bars/percentages appear on the map and building detail. The shell contributes 2/3 of progress; B1 contributes 1/3. Progress follows saved phases and the current phase's elapsed time, holds across job waits, and reaches 100% only after completion is committed.

The exterior/progress/opening update passes formatting, analysis and all 50 tests. Browser review used a separate in-memory fixture and verified the approved map art, moving progress, completion remaining closed through several game days, manual opening, and the portrait button layout. The fixture is ignored and not shipped. Android build remains blocked by the missing SDK.

[Approved apartment image and construction progress on the map](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-151)

[Completed construction waiting for Open to Business](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-166)

## Map navigation

Two fingers now zoom continuously from 50% to 200%, keeping the world point under the moving midpoint anchored. A one-finger drag pans outside placement mode. Pinching during placement restores the previous preview and blocks further drawing until every finger is released. Pinch gestures never pick buildings. The −/+ controls move to the next 25% step from a continuous pinch scale; their original behavior at exact steps is unchanged.

Selecting a building opens a full floor detail in place of the map and its side/bottom panel. Each above-ground floor shows its room modules and tenant actions; basements show only parking with per-level capacity/used/free bays. The fixed bottom toolbar orders Exit building, Go up and Go down beneath a live current-floor label. Floor 1 and B1 connect directly; unavailable directions are disabled. Construction detail remains visible for unfinished buildings. Selection and floor position belong to `DistrictViewModel`; each entry starts at Floor 1 and exit restores the mounted map's zoom/pan. Completed upgrades extend available navigation. `PROJECTS.md` tracks this iteration and verification.

Map navigation includes bottom-right **− / +** controls for mouse/touch users. Start at 100%, step by 25 percentage points and disable the relevant button at 50%/200%. The viewport centre remains on the same world point after zooming. Terrain, roads, buildings, previews and picking share one scaled projection. Button clicks never draw land or select a building. Camera zoom/pan belong to a presentation view model and last for the current district screen session; they are not game-save data. Center map clears panning while keeping the chosen zoom.

Zoom validation on 2026-10-12: formatting, analysis, all **32 tests**, Android debug and offline Web builds passed. Tests cover focal-point preservation after panning, both zoom limits/disabled buttons, mouse footprint selection at 125%, building picking at 75%, and control clicks that do not create selections. Portrait, landscape and desktop construction flows now run at 125% with semantics enabled. Zoom controls are 48-pixel native button targets in a separate overlay, twelve pixels from the map's bottom/right edges, above the page toolbar/hosting footer.

The deployed browser review confirmed both scale directions and a correct 2 × 4 footprint at 125%, without a selection from button clicks.

[Bottom-right zoom controls at 125% during footprint planning](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-165)

## Local persistence

Schema 3 snapshots preserve the phase interval introduced in schema 2 and protect the manual-opening rule from older clients. Schemas 1/2 remain readable. Already-open buildings retain their stage and tenants; completed-but-closed buildings stay `parkingDone` through offline catch-up until the opening action commits. On first load of a schema 1 save, simulate elapsed offline time with the original 60-second phases, then scale the fractional phase remainder into the new 5-second interval. The watermark never moves backward. Migration and the user's action commit in one existing repository transaction, so failure leaves the old save intact. Opening is free, requires completion, and repeated requests do not duplicate money or admissions. Schema/catalog/interval validation continues to preserve unsupported data. Older app tabs cannot read schema 3 and must be closed to load the new release.

Full snapshots use Sembast transactions with SQLite on Android (`sembast_sqflite`/`sqflite`) and IndexedDB on Web (`sembast_web`). One versioned record per profile stores the wallet, buildings/orders, road layout derived from occupied plots, clock/watermark, rent ledger and closing ID together. Read latest state inside each transaction, advance elapsed time, validate the requested mutation and commit before publishing it. Preserve unsupported/corrupt records and show a retryable error. SharedPreferences continues to hold only legacy/profile metadata.

The game watermark starts at first snapshot creation, not the old metadata creation time. Never recreate a failed/unsupported snapshot as a new wallet. Catch up missed phase boundaries without an earnings cap. Backward clock movement retains the previous watermark. Repeated reads cannot pay the same closing twice. Browser storage remains tied to the origin and can be cleared/evicted by the browser; transaction support does not constitute cloud backup.

This fixed-price catalog is versioned as `catalog: 1`. Occupied room IDs determine daily accrual; earned cents are retained in an aggregate pending ledger per building, including vacated rooms' past accruals. Future catalog changes need an explicit migration rather than silently repricing the current save. The view model persists every ten seconds, at phase boundaries and on player actions; any elapsed remainder since the last save is recovered from the watermark on reload. Fast drags use pointer-down/move/up positions, including the final release cell.

Map drawing remains available while a background snapshot commits; saved mutations still wait for an available transaction. The canvas retains its descriptive semantic label but excludes automatic gesture-button semantics, which otherwise intercept pointer events on Flutter Web. Building selection and room actions remain available as accessible native panel controls.

References: [Sembast transactions](https://pub.dev/packages/sembast), [SQLite adapter](https://pub.dev/packages/sembast_sqflite), [IndexedDB adapter](https://pub.dev/packages/sembast_web).

## Validation status

On 2026-10-14, the floor-navigation change passed formatting, Flutter analysis and all **35 tests**. New responsive tests click an actual map building, assert that the map is hidden, navigate Floor 1/B1 with disabled boundaries, return at 125% zoom, and select a different unfinished building. Existing room-vacancy/pending-rent and construction tests still pass. The asset validator passes all 158 resources/124 frames. The final release Web build includes 201 offline resources. Local Android debug compilation was attempted but blocked by the missing Android SDK.

An isolated in-memory browser fixture verified desktop, portrait and landscape floor layouts, parking-only B1, live current-floor labels, scrolling beneath fixed navigation, and restored map zoom. The fixture is ignored and never included in the production entry point or player saves.

The hosted Web check exposed the bottom-right Netlify badge's overlap with navigation. Web floor detail now reserves 64 pixels beneath its toolbar; Android retains normal safe-area spacing. Analysis and all 35 tests were repeated successfully for this adjustment.

[Floor 1 detail with bottom navigation](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-157)

[B1 parking detail](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-150)

On 2026-10-12, formatting, Flutter analysis and all **28 tests** passed. Coverage includes Noon-only payments, shell/B1 timing, Morning admissions, Sunday rent with Sunday accrual, departing-tenant ledger retention, daily tax/upkeep, negative balances, shared-road cancellation, concurrent reservations, failed-transaction preservation, unsupported saves, multi-week offline parity and portrait/landscape/desktop construction and room flows. The four gameplay UI tests were repeated after the final drawing/rendering fixes. Android debug and release Web builds passed; Web still includes all 201 offline resources and the unchanged 158-asset catalog.

Browser review on the local Web build confirmed saved-profile reload, elapsed-time catch-up, the running calendar, fast-drag 2 × 4 planning, six derived rooms, sixteen B1 bays, the $20,000 quote, complete-quote reservation and automatic roads. The original fast-drag selection issue was corrected using pointer release coordinates. Construction markers retain their source aspect ratio, and the selected ground outline renders beneath the actual one-floor exterior. A prepared in-memory operational fixture was inspected for geometry/room composition; it is not seeded into real games. No Android device was available for execution.

Production publication and hosting checks are recorded in [Deployment.md](Deployment.md). Hotel/office/F&B, luxury and lift happiness effects remain future work. Apartment floor/basement/lift upgrades are now implemented. Audio integration is still pending.

[Deployed apartment starter after confirming the occupied plot and road ring](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ?node-id=3-161)

## Initial audit checkpoint before catalog approval — 2026-10-16

The first audit found three unplayable types and missing systems. The catalog required a decision under AGENTS.md's prohibition on silently choosing economy values. The user subsequently approved it; the current implementation at the top of this document and [updated assessment](FigmaAssessment.md) supersede that initial checkpoint. Live Figma inspection remains blocked by the Starter MCP quota.

Tenants and Upgrades now open district directories from the native toolbar. A tenant entry navigates to the floor containing that saved room; its context shows weekly rent, reserved parking and the existing keep/vacate actions. Upgrades opens the chosen building's existing review panel. Exit restores the originating directory and the mounted map camera. Controls wrap on narrow screens. These changes add presentation navigation only and preserve the save schema, money, pending rent and occupancy rules.
