# Project setup

## Approved source

The user approved the current [Canva artwork and game kit](https://www.canva.com/d/51ESDDCqVSdEOVT) on 2026-10-11. Follow [DesignKit.md](DesignKit.md) and preserve the BM mark from `design/brand/`. The game contract remains [Project.md](Project.md), [Platform.md](Platform.md), [Rules.md](Rules.md), [Logic.md](Logic.md) and [Design.md](Design.md).

## Toolchain

- Flutter 3.47.7, revision `abaf9c523780a608bd46686fd5e53740a07077f8`.
- Dart 3.13.5. The SDK pin is in `toolchain.json`; `pubspec.lock` pins resolved package versions.
- Android and Web only. Android application ID: `com.norfabagas.building_management_tycoon`. Android minimum API 24; compile/target values follow the pinned Flutter template.
- Java 21 for Android builds. Android SDK platform 36, build tools and the Flutter-selected NDK are development prerequisites.

This Windows workspace installs Flutter under ignored `.tools/flutter/`, without adding it to the user's PATH. The wrapper, bootstrap and Web build use a project-local `.tools/pub-cache/`. This keeps Kotlin plugin source files on the same drive as the project: the initial Android build failed when Kotlin tried to relativize C: dependency paths against the D: workspace. The generated failed Kotlin cache was moved to an ignored backup before retrying; no user save data was removed.

The existing Android Studio configuration pointed to a missing folder. Setup corrected the Flutter tool's local configuration to the installed Studio at `D:/Work/Android`, SDK at `D:/Work/Android-Sdk`, and JDK 21 at `C:/Users/bgsno/.jdks/openjdk-21.0.1`. These machine paths are not checked into Gradle properties.

Android command-line tools 23.0.0 were installed from Google's SDK repository, with the ZIP checked against its published checksum. Flutter installed NDK 28.2.13676358 using the existing accepted Android SDK license. `flutter doctor -v` confirms Android and Chrome toolchains are ready.

The project also sets `kotlin.incremental=false` and `kotlin.compiler.execution.strategy=in-process` in `android/gradle.properties`. A second build retained failed registrations in the old Kotlin daemon after the cache move. The project-local compiler settings fixed that failure; ordinary Gradle task caching still applies. See [Kotlin compilation settings](https://kotlinlang.org/docs/gradle-compilation-and-caches.html).

Installation follows [Flutter's manual setup](https://docs.flutter.dev/install/manual). Fresh dependency and SDK installation requires connectivity; running the packaged game does not require a backend.

## Bootstrap and run

From the repository root on Windows:

```powershell
./tool/bootstrap.ps1
./tool/flutter.ps1 run -d chrome
./tool/flutter.ps1 devices
./tool/flutter.ps1 run -d <android-device-id>
```

On another workstation, use the version in `toolchain.json`, install the Android SDK/JDK, and run `flutter doctor -v`. A globally installed matching Flutter SDK also works. Do not run `flutter create --overwrite` over the authored application or documentation.

## Checks and builds

```powershell
./.tools/flutter/bin/cache/dart-sdk/bin/dart.exe format --output=none --set-exit-if-changed lib test tool
./tool/flutter.ps1 analyze
./tool/flutter.ps1 test
./tool/flutter.ps1 build apk --debug
./.tools/flutter/bin/cache/dart-sdk/bin/dart.exe run tool/build_web.dart
```

For a global SDK, use `dart` and `flutter` in the equivalent commands. GitHub Actions runs format, analyze, tests, the offline Web build, and an Android debug build. Store signing and deployment are not configured.

Web output is `build/web/`. Serve that entire directory from HTTPS, or localhost during development. `tool/build_web.dart` disables the Flutter resource CDN, generates a versioned offline asset manifest, and includes a service worker. After the initial load and cache installation, the app can reload without the host being reachable. Updates wait for the previous service worker's clients to close. Direct `flutter build web` omits this offline packaging step. Local profiles are tied to the browser origin and can be removed by browser storage clearing.

The native Android app bundles its assets and fonts. Release application permissions contain no Internet permission. Flutter's debug/profile manifests allow network access for development tools. Android backup and transfer exclusions keep profile metadata local.

## Architecture

The setup uses MVVM with Flutter `ChangeNotifier`, without an extra state-management package.

| Location | Responsibility |
| --- | --- |
| `lib/app/` | App composition, approved asset paths and shared theme |
| `lib/domain/` | Profile metadata, building-type identifiers, documented limits and phase order |
| `lib/data/` | Versioned local storage and `SaveManager` |
| `lib/features/profiles/` | Five-slot view model, profile selection and naming |
| `lib/features/district/` | Empty isometric canvas with drag-to-pan |
| `lib/shared/widgets/` | Defined BM title lockup and shared actions |
| `test/` | Save safety, concurrency, phase order and responsive profile flow |

`PreferencesSaveStore` uses `SharedPreferencesAsync`, one JSON key and schema version 1. It currently stores **profile metadata only**: slot, trimmed district name and creation time. Read-modify-write operations serialize, occupied slots reject replacement, and failed writes never publish success in the view model. Unreadable or unsupported saves remain untouched and block creation until a successful read. No reset/delete operation exists in this setup. Before storing complete game progress, choose and document a durable snapshot/transaction strategy; the [package documentation](https://pub.dev/packages/shared_preferences) does not guarantee durable writes for critical data.

## Current application scope

Implemented: branded responsive launch/profile screen, approved illustration and BM icons, exactly five local slots, name validation, metadata persistence, loading an existing slot, retryable save/read failures and an empty district canvas that pans by dragging. A new district contains no sample buildings. The launch illustration is promotional artwork and is never loaded as saved game state.

The canvas is a visual bootstrap, not a construction system. Its eight-by-eight drawing is an illustrative viewport, not a decided district size. It has no placement, wallet, occupancy, upgrades, financial simulation or offline income calculation yet. The clock object preserves Morning, Day, Afternoon, Night and Noon; it does not run a timer or commit dollars.

## Fonts and artwork

Colors, corners, title lockup and controls derive from the approved kit. All five original artwork PNGs are bundled through `pubspec.yaml`; the app references their source paths directly. Android launcher icons, splash logo and Web icons derive from the defined BM PNG. `design/brand/export-app-icons.mjs` regenerates these exports with Sharp available, optionally through `RUNTIME_NODE_MODULES`.

The reference uses Trebuchet MS. No redistributable application font file was supplied. The theme keeps that requested family and uses bundled Roboto as its offline fallback, with Noto Sans Thai for Thai district names. Android and Web share these fallback files. Exact reference typography requires a distribution-ready Trebuchet source or an approved font substitution. Source links and included font licenses are in `assets/fonts/README.md`. Web automatic fallback requests use the app's own origin. Additional writing systems need bundled glyph coverage.

## Next implementation gates

The user selected **Option 1: Relaxed idle** on 2026-10-12, with apartment rent paid weekly at in-game Sunday Noon and other income daily at Noon. Follow [Economy.md](Economy.md) for starting funds, time/capacity formulas, reservations, initial parking, taxes and offline billing. These rules are documented but not implemented. Before gameplay implementation, finalize prices/weekly rents, upkeep coefficients, happiness/demand tuning, unlock thresholds and the other remaining gates in [DesignKit.md](DesignKit.md), and choose durable full-game persistence. Keep above-ground sizing immutable. Underground remains parking only, with maximum three levels, three standard lifts and one executive lift. Offices lease whole floors.

Every implementation change must update the documentation and retain these constraints.

The user additionally confirmed that occupying empty land with a building automatically creates a road around its footprint. This is documented in Rules.md/Logic.md but not implemented in the current empty canvas. Before placement implementation, define road width/corners, edge handling and any cost/upkeep; validate road space and save it with the occupied plot without changing room/parking capacity.

## Validation on 2026-10-12

- Dart formatting check passes; `flutter analyze` reports no issues.
- All 13 tests pass, including concurrent save creation, corrupted save preservation, failed write/read recovery, phase order, profile creation and portrait/landscape layouts.
- Android debug APK builds successfully at `build/app/outputs/flutter-apk/app-debug.apk`. Package metadata confirms the game title, application ID, minimum API 24 and target API 36. ZIP inspection confirms both local fonts, the BM logo and all five artwork sources are bundled. No Android device was connected, so device execution has not been tested.
- Release Web build passes and generates an offline manifest with 48 local resources. Browser review confirms the branded profile screen. After cache installation, the preview server was stopped and the application reloaded successfully with its artwork and five slots visible.
- Android and Chrome pass `flutter doctor`. Remaining doctor warnings concern the intentionally project-local SDK PATH, the pinned detached release tag, and missing Windows desktop tools; this project targets Android and Web.
- The GitHub Actions workflow is configured but has not been run remotely. Temporary browser/server review sessions were closed.

![Verified launch screen](images/setup-launch.jpg)

## Build verification for GitHub handoff — 2026-10-12

Re-ran dependency resolution, the Dart format check, Flutter analysis and all 13 tests successfully before committing the project. Rebuilt the Android debug APK at `build/app/outputs/flutter-apk/app-debug.apk` and the release Web bundle at `build/web/`. The offline build generated 48 resources; all manifest paths exist and the generated service worker has its version and registration. The earlier browser/offline review above remains the UI validation; it was not repeated for these documentation-only rule additions.

The source handoff includes the approved BM assets/design references, Flutter application, tests, pinned dependencies/toolchain, GitHub Actions configuration and updated rules. SDKs, dependency caches, generated builds, Kotlin error logs and machine/signing settings remain ignored. Built outputs stay local; no store signing or GitHub release is configured. Apartment Sunday billing and automatic surrounding roads are recorded rules for future gameplay implementation, not features of this initial app build.
