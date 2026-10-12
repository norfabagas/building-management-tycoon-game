# Apartment starter gameplay

The user approved this starter implementation on 2026-10-12. Follow [Economy.md](Economy.md) for the explicit starter catalog and original weekly apartment billing contract. The empty-canvas bootstrap is replaced with a buildable district.

## Player flow

Load an existing district or create one of the five local slots. Existing metadata-only profiles receive an empty game snapshot with $40,000 at first gameplay load; their names and slots are preserved. Choose Build, select Apartment, draw a footprint on the map, review its derived rooms, B1 bays and costs, then confirm. Roads and the occupied construction plot are saved together. Unpaid orders can be canceled; paid orders have no refund action.

Payment waits for Noon, construction starts next Morning, shell construction lasts two game days and B1 lasts one. Occupancy starts at the next Morning after B1 completion. Apartments accumulate rent for actual occupied days and pay at in-game Sunday Noon. Parking, expenses and taxes settle daily. The finance panel shows available dollars, reservations, pending apartment rent, next Sunday payment and the last closing. Select a building to view rooms and parking; vacating a room preserves accrued rent.

## Local persistence

Full snapshots use Sembast transactions with SQLite on Android (`sembast_sqflite`/`sqflite`) and IndexedDB on Web (`sembast_web`). One versioned record per profile stores the wallet, buildings/orders, road layout derived from occupied plots, clock/watermark, rent ledger and closing ID together. Read latest state inside each transaction, advance elapsed time, validate the requested mutation and commit before publishing it. Preserve unsupported/corrupt records and show a retryable error. SharedPreferences continues to hold only legacy/profile metadata.

The game watermark starts at first snapshot creation, not the old metadata creation time. Never recreate a failed/unsupported snapshot as a new wallet. Catch up missed phase boundaries without an earnings cap. Backward clock movement retains the previous watermark. Repeated reads cannot pay the same closing twice. Browser storage remains tied to the origin and can be cleared/evicted by the browser; transaction support does not constitute cloud backup.

This fixed-price catalog is versioned as `catalog: 1`. Occupied room IDs determine daily accrual; earned cents are retained in an aggregate pending ledger per building, including vacated rooms' past accruals. Future catalog changes need an explicit migration rather than silently repricing the current save. The view model persists every ten seconds, at phase boundaries and on player actions; any elapsed remainder since the last save is recovered from the watermark on reload. Fast drags use pointer-down/move/up positions, including the final release cell.

Map drawing remains available while a background snapshot commits; saved mutations still wait for an available transaction. The canvas retains its descriptive semantic label but excludes automatic gesture-button semantics, which otherwise intercept pointer events on Flutter Web. Building selection and room actions remain available as accessible native panel controls.

References: [Sembast transactions](https://pub.dev/packages/sembast), [SQLite adapter](https://pub.dev/packages/sembast_sqflite), [IndexedDB adapter](https://pub.dev/packages/sembast_web).

## Validation status

On 2026-10-12, formatting, Flutter analysis and all **28 tests** passed. Coverage includes Noon-only payments, shell/B1 timing, Morning admissions, Sunday rent with Sunday accrual, departing-tenant ledger retention, daily tax/upkeep, negative balances, shared-road cancellation, concurrent reservations, failed-transaction preservation, unsupported saves, multi-week offline parity and portrait/landscape/desktop construction and room flows. The four gameplay UI tests were repeated after the final drawing/rendering fixes. Android debug and release Web builds passed; Web still includes all 201 offline resources and the unchanged 158-asset catalog.

Browser review on the local Web build confirmed saved-profile reload, elapsed-time catch-up, the running calendar, fast-drag 2 × 4 planning, six derived rooms, sixteen B1 bays, the $20,000 quote, complete-quote reservation and automatic roads. The original fast-drag selection issue was corrected using pointer release coordinates. Construction markers retain their source aspect ratio, and the selected ground outline renders beneath the actual one-floor exterior. A prepared in-memory operational fixture was inspected for geometry/room composition; it is not seeded into real games. No Android device was available for execution.

Production publication and hosting checks are recorded in [Deployment.md](Deployment.md). The complete hotel/office/F&B and upgrade systems remain outside this explicitly approved starter release. Audio integration is still pending.
