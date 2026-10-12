# Platform & Tech Stack

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
