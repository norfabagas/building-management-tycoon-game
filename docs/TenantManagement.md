# Tenant release design

The 2026-10-17 user request replaces the default vacant/release pop-up with a designed game experience. **Manage now opens a full application page**, with no AlertDialog, SimpleDialog, floating modal or second pop-up confirmation. The reviewed action itself is explicit confirmation. Profile deletion, construction and other unrelated dialogs remain separate flows.

## Composition

- **Context:** Back, Tenant management, the saved building/floor/unit identity and live day/time. Headings explain the actual action: Set this room vacant, Check out this guest, or Release this floor lease.
- **Current unit:** approved furnished cutaway in a cream card with an evergreen outline, 18-pixel corners and a restrained bottom shadow. A saved Occupied/Vacant pill and the matching indoor idle actor identify current state; quiet offices and vacant units have no actor. Cap artwork width at 420 pixels without distorting its aspect ratio.
- **After release:** smaller matching vacant-shell artwork with a Vacant label and a room/whole-floor explanation. It is explicitly a preview; it never changes the current unit before confirmation.
- **Release summary:** native icons introduce parking bays freed, retained apartment rent or the existing daily base hotel/office rate, and next-Morning admission subject to demand and parking. The apartment amount is clearly the building's uncollected rent. No release charge, fee, refund, demand or income mechanic is added.
- **Pinned actions:** a red tactile release action and cream Keep tenant button, both with 52-pixel minimum targets, ink outlines and 4-pixel bases. Wide screens place the artwork and summary alongside one another at 820 pixels; narrower screens stack them. The body scrolls independently of the footer. Below 560 pixels, actions stack at full width; short landscape keeps them in one row. The footer reserves the existing hosted Web badge clearance.

Colors, artwork, typography fallback and spacing follow DesignKit.md. Native text stays outside raster art. The BM master and runtime pack are unchanged; asset validation passed before reusing the registered room/actor paths. Screenshots are review evidence outside Git, not new runtime bitmaps.

## Behavior and states

`TenantManagementScreen` reads the existing DistrictViewModel snapshot by stable building/unit IDs, using TenantActivityViewModel for role/floor/occupancy. It stays within the interior's Navigator stack, preserving the building floor and map camera. **Keep tenant / Back** returns to the interior without a mutation. **Vacate room / Check out guest / End floor lease** performs the existing `DistrictSimulation.vacate` through `model.save` and the repository transaction. After success the route returns to the live interior, whose vacant art, actor visibility and reserved-bay count refresh from saved state. Food courts continue to expose parties rather than invented individual leases and have no release action.

During a release request, disable duplicate actions and route dismissal. Failure keeps the page open and shows the saved error inline, with Retry release and Refresh unit. Retry repeats the explicit release transaction; Refresh unit loads current state without a release action. If an already-vacant snapshot arrives, show that state and only Back to interior. Missing, unfinished, invalid or food units show unavailable state with no destructive action. Domain checks still reject a room that is already vacant.

The clock and ordinary business progression continue while reviewing. The review addresses the current occupant of the selected unit; the game has no persistent named resident/guest identity or per-person departure simulation. Do not infer a new tenant-history system from the illustration. Existing rates, morning admissions, daily/weekly settlement, parking allocation, pending rent, save schema 8/catalog 2 and profile lifecycle guards are unchanged. No dependency, network service, account or new runtime asset is introduced.

## Verification

`tenant_management_test.dart` covers apartment/hotel/office review, cancel and commit at 390×844, 844×390 and 1440×900, absence of default dialogs, matching current/vacant art, visible pinned controls, unchanged balance/pending rent, released parking, busy/back protection, failed-write retry and live vacancy refresh. Existing directory, hotel/office and apartment-release integration tests also exercise the new route. Production browser review and final check/publication results are recorded after validation in Deployment.md.

Final checks pass formatting of **66 Dart files**, Flutter analysis, all **203 Flutter tests** (including 11 new release-review tests), six offline-worker tests and the **158-asset / 124-frame** validator. The normal `lib/main.dart` Web build passes its Wasm dry run and packages **201 offline resources**. Android debug compilation was attempted and reports **No Android SDK found**; no Android/device run is claimed.

Browser review uses the normal production build on the retained localhost QA profile. Manage opens a full page at 1000×800, 390×844 and 844×390; current/vacant artwork loads, the portrait body scrolls independently of pinned actions, and Keep tenant returns to the occupied interior with one reserved unit bay and 8/12 building bays unchanged. Browser errors are empty. No real tenant is released during browser QA; destructive release, retry and refreshed vacancy are verified in isolated automated tests. Screenshots stay ignored in `.tools/tenant-management-desktop.png` and `.tools/tenant-management-portrait.png`.
