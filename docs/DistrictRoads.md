# Connected district streets and outdoor activity

## Tenant animation and ambient traffic — 2026-10-23

Continuous interior walk/rest transitions and varied ambient vehicles now cover the highway and open-business rings. Presentation only; five local saves, economy, artwork and schema stay unchanged. See [AmbientActivity.md](AmbientActivity.md) for behavior, implementation decisions and validation.


Implementation decisions, 2026-10-17. The user approved strict connected-network placement.

## Access rules

- The permanent highway covers two infinite x-axis rows, initially −3 and −2. A native Main road button focuses its centre without changing zoom or world geometry.
- A building keeps its automatic free one-tile perimeter. That ring must overlap or share a four-neighbour edge with the highway or streets reachable from it. Corner-only contact is insufficient. No remote auto-connector, road purchase/tool, fee or upkeep is introduced.
- Reserve highway, public streets and building rings against plot/decor placement. Domain validation is authoritative at review and transaction commit; an invalid action cannot charge the wallet.
- A canceled pre-opening building receives its full original quote and applicable pending rush-gem refund. Retain its ring as public streets only if another connected building would otherwise lose access. Removing a dead end removes the unshared ring. Public roads may depend on other rings, so every connectivity query starts at the highway.
- Road connectivity does not replace the catalog's compatible overlapping-ring synergy calculation.

## Existing saves

Schema 8/catalog 2 stores mainRow and compact horizontal/vertical street segments. Schemas 1–7 remain readable. Place the highway three rows north of the northernmost saved building/decor tile, then connect disconnected saved building networks around all occupied plots/decorations. Existing IDs, footprints, levels, queues, ledgers, balances, gems and opening status are preserved; migration itself costs nothing. Existing clock/catalog catch-up still follows its previous rules in the repository transaction.

Routes use a sparse grid of obstacle boundary coordinates; million-tile gaps do not allocate a million saved cells. Highway position is then stable across purchases, cancellation and reload. Invalid persisted street geometry or roads crossing a building are rejected; the repository preserves failed records. Older app versions reject schema 8.

## Outdoor motion

Only ConstructionStage.ready creates traffic, including open buildings with ongoing upgrades. Each visible business has two matching character sprites and one approved blue car. They follow rounded loops around its actual width/length. Pedestrians use the inner pavement; cars use lane centres. Continuous presentation seconds drive walking at 0.42 land tiles/second and cars at 1.2; character frames use catalog 8 fps. These are visual speeds, not economy coefficients. Deterministic offsets distribute actors, and one walker travels in the opposite direction.

Terrain, activity and foreground structures have separate repaint boundaries. Drawing structures after traffic uses the actual artwork alpha to occlude actors behind facades; it avoids the roof overlap found during visual self-review. Route geometry is cached per scene, and the independent activity painter repaints without rebuilding terrain each frame. Offscreen buildings are culled; at most 24 visible businesses show activity (72 sprites), protecting mobile rendering. Actors are cosmetic rather than a population/traffic simulation: no collision AI, trip destinations, highway through-traffic or income effects. They remain outside plot interiors and are occluded by neighbouring facades. Shared daylight paint tints the full scene smoothly. Reduced-motion freezes poses; hiding the map stops and preserves its animation clock. Actor sheets decode at half resolution; no additional asset bytes, network dependencies or save counters are needed.

## Validation

- Dart format check passes: 57 files, no changes. Flutter analyzer reports no issues.
- All **152 Flutter tests pass**. Added coverage includes strict/indirect/diagonal road access, isolated public streets, atomic rejection, road/decor reservations, repeated bridge cancellation/full refund, old-save routing around obstacles and million-tile gaps, persisted invalid roads, long activity routes, loop continuity, open-only/reduced/hidden ticker behavior, all four sprite contracts, blocked purchase review and compact-map pinch anchoring. Existing economy, clock, five-slot, four-type, upgrade and portrait/landscape/desktop flows remain covered.
- The **158-resource/124-frame asset validator** passes. Ten archived originals were matched by recorded provenance; their remote source bytes were not fetched in this pass. No runtime art or BM master bytes changed.
- All **six offline worker tests** pass. They exercise cache installation/failure, offline navigation/assets, activation and request boundaries in a controlled harness; this pass does not certify a disconnected physical device.
- Browser review used a disposable, in-memory four-type district in desktop, portrait and landscape layouts. Walkers/cars move between observed frames; facades occlude traffic, the daylight tint remains continuous, the highway is visible and Main road focuses it. No browser console errors were observed. The review fixture is ignored and must not be published.
- Android debug build was attempted and blocked with **No Android SDK found**. No Android device test was performed.

## Production receipt

Source **536b967bd4bf5e4cb6da478b9bab7126c745d7b9** is committed and pushed to GitHub main. The normal `lib/main.dart` release build passes with **201 local offline resources**. Netlify deploy **6ad2d6e98259b8bde2676b0a** is ready/current, published **2026-10-17 09:01:18 WIB**, at [bmt.niceblue.biz.id](https://bmt.niceblue.biz.id). Primary JavaScript, worker and offline manifest each return HTTP 200 and match the local release hashes. See [Deployment.md](Deployment.md) for hashes.

The normal production bundle also loaded the existing local Tycoon QA profile after closing/reopening its old offline-worker tab. Its two previously open apartments, room progress and six gems survive; a free access street joins the formerly separate buildings to the highway. Ordinary chronological offline income is applied once. Traffic is visible around the opened buildings and no console errors were observed. The public domain opens successfully with five slots; no public-domain profile was created for this review. This browser evidence supplements the transactional migration tests, not a claim of Android/device or live Figma verification. GitHub combined status returned no reported checks, so remote CI success is not certified.
