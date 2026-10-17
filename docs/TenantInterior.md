# Full-screen tenant interiors

The 2026-10-17 user request replaces the immediate room-management dialog with an interior that occupies the full application viewport. Tap/click a room or whole-floor lease, or a saved tenant in the district directory. Food courts expose their dining floor from the floor artwork and the directory's dining-activity entry. Vacant rooms can also be inspected.

## Navigation and state

`TenantActivityScreen` is an opaque Navigator route listening to the existing `DistrictViewModel`. Back returns to the same building/floor; exiting that building restores the originating directory and retained map camera. Opening or leaving an interior has no saved mutation. The game clock, admissions, turnover, upgrades and closing continue normally. Manage opens the existing confirmation and transactional removal action; the interior refreshes after successful removal or a new snapshot. A failed save displays Retry while preserving the previous saved state.

`TenantActivityViewModel` is a read-only presentation of a stable building/unit ID. Apartments and hotels retain their saved room IDs; one office lease represents its entire floor. Food courts have no invented individual tenants: the view allocates actual current parties from lower to upper floors, with the same per-floor capacity rule as the building panel. Daily sales/visits/parking and apartment pending rent are explicitly labelled building totals. Base rates, happiness, luxury, lifts and occupied parking come from existing state/catalogue; vacancy reserves zero unit bays.

## Interior and daily routines

Reuse the four registered furnished/vacant cutaways and their matching resident, guest, office and customer idle/walk sequences. The asset validator passed before adding these references. No asset bytes, BM source, dependencies, economy values, save schema or domain simulation are changed (schema 8/catalog 2).

The four six-hour windows use role-specific illustrative routines: entrance/window/lounge/bedroom for apartments; luggage/desk/window/bedroom for hotel guests; arrival/workstations/meeting/quiet office for offices; breakfast/lunch/afternoon/evening service for food courts. The activity strip shows all four windows and marks the current one. A representative actor moves between the entrance and the current zone, retaining the registered aspect ratio. Food floors show up to three representative customer figures, capped by actual parties; a figure is not a person-count statistic. Occupied offices become visually quiet at Night without terminating the lease. Vacant units and empty dining floors have no actors or active routine marker.

These routines are ambient presentation, not a newly simulated needs, staff, cooking, sleep or per-person history system. The UI labels this distinction. The available character sheets provide idle/walk poses, not bespoke seated/sleeping/cooking rigs. No inferred activity earns income or changes demand. Indoor front cutaway art remains distinct from the outdoor XYZ figures.

The cream/evergreen layout prioritizes the large interior and current activity. Wide screens place live status alongside it; narrow screens stack it below. Short landscape caps cutaway height so the entire room and its floor remain visible before scrolling. Actor frames retain their 2:3 proportions at 17% of the room width. All content scrolls inside the full-screen route, leaving Back/Manage reachable in the app bar in portrait and short landscape. Bottom clearance covers the hosted Web footer. Reduced motion freezes walking and sprite frames; opaque navigation pauses hidden-route tickers.

## Verification

`tenant_activity_test.dart` exercises all four types at 390×844, 844×390 and 1440×900, viewport coverage, saved financial data, live phase replacement, vacancy refresh, management disabling, return navigation and non-mutating inspection. It separately checks upper food-floor allocation and quiet/vacant offices. Existing directory, hotel/office and apartment-vacate tests now exercise full-screen entry followed by the original confirmation. Final build/browser/publication results are recorded below and in Deployment.md after validation.

Final source validation passes formatting of 63 Dart files, Flutter analysis, all **182 Flutter tests**, six offline-worker tests and the asset validator (**158 resources / 124 frames**). The short-landscape regression asserts that the complete interior is above the viewport's fold. Android debug compilation was attempted and reports **No Android SDK found**; no Android device run is claimed.

The final normal-entry release Web build passes (including its Wasm dry run) and packages **201 local offline resources**. No review fixture is included in the release. Browser proof files and build/test logs stay in ignored `.tools/`.

Browser review uses an isolated in-memory four-type fixture and the normal production entry point on the retained localhost QA profile, preserving its two open apartments, occupancy and six gems. Checked resident/guest/whole-floor/dining entry, live phase updates, Back restoring the floor and subsequent Exit restoring the directory, and Manage → Keep tenant. Browser error logs are empty. The existing offline pack required close/reopen before the new UI appeared; retain site data. Publication and final build receipt follow in Deployment.md.
