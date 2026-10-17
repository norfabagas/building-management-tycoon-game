# Platform & Tech Stack

## Volumetric figures and visible floors — 2026-10-17

Use small local XYZ meshes, CPU-projected into the existing Flutter isometric canvas: articulated limbs, shaded faces and world-heading rotation. No 3D engine, plugin, network model service or new dependency is required. Cap animation at 30 visual updates/second and 12 visible businesses (36 models); cache routes and building-occlusion masks. The camera remains the existing isometric pan/zoom camera, without orbit controls. See [VolumeAndHeight.md](VolumeAndHeight.md).


## Road save update — 2026-10-17

Current snapshots use schema 8/catalog 2 for a compact, entirely local highway/public-street network. Android/Web, five slots, offline progression and MVVM remain unchanged. Ambient map activity uses Flutter canvas/ticker and bundled assets, without external services. Close older tabs before reopening this release; older clients cannot load schema 8. See [DistrictRoads.md](DistrictRoads.md).


## Catalog 2 runtime — 2026-10-16

Flutter MVVM and local Sembast transactions remain the application architecture. Schema 7/catalog 2 adds four-type behavior and progression without a backend. `audioplayers` 6.8.1 adds Android/Web local WAV playback; only bundled asset sources are used, initially muted and gated by an explicit sound gesture. A per-profile preference is stored in the same local snapshot; no network audio service or new Android network permission is introduced. The dependency lockfile is committed. Android compilation/device verification remains limited by this workstation's absent Android SDK; publication targets the existing offline Web build.

## Target Platform
- **Primary OS:** Android (Mobile and Tablet) & Web
- **Distribution:** Google Play Store, Web Hosting
- **Orientation:** Supports both Portrait and Landscape modes

## Technology Stack
- **Engine/Framework:** Flutter
- **Language:** Dart
- **Version Control:** Git & GitHub
- **Architecture:** MVVM or BLoC for state management

## Initial Project Setup

The user approved the latest design on 2026-10-11. The initial project uses **MVVM with ChangeNotifier**, Flutter **3.47.7** and Dart **3.13.5**. Android and Web runners, shared branding/theme, five-slot profile metadata and an empty pannable district canvas are implemented. Android minimum API is 24; Java 21 supports its Gradle build. Versioned profile metadata uses `SharedPreferencesAsync`. Full game-save durability and economy simulation remain separate implementation work.

The apartment starter adds full game snapshots and gameplay using local SQLite on Android and IndexedDB on Web. Existing profile metadata stays in SharedPreferences; legacy districts initialize empty game progress once without losing their names/slots. See [Gameplay.md](Gameplay.md) and [Setup.md](Setup.md) for architecture, dependencies and limitations. Web bundles renderer/fonts on its own origin and installs an offline cache after first load. Android backup/transfer exclusions cover the new database as well as profiles. No backend or game network service is configured.

The Web app was published to a new Netlify project on 2026-10-12: [Open the game](https://building-management-tycoon-game.netlify.app). Hosting currently uses manual CLI uploads; GitHub continuous deployment is not connected. See [Deployment.md](Deployment.md) for project/deploy identities, validation and origin-specific save behavior. Android and Web builds remain available locally; gameplay and saves remain local.

## Offline Constraints & Data Storage
- **Connectivity:** This game is strictly offline. No active internet connection is required to play.
- **Profiles:** The game supports up to **5 local player profiles (save slots)**. 
- **Data Storage:** Data for each of the 5 profiles is saved entirely on the local device (using local storage solutions like Hive, SharedPreferences, or sqflite). There is no cloud sync, analytics, or server-side logic dependencies.
