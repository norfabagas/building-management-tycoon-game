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

See [Setup.md](Setup.md) for commands, architecture, dependency choices, validation and limitations. The release Web build packages renderer resources and fonts on its own origin and installs an offline cache after the first load. Android backup/transfer exclusions retain local-only profile data. No backend or runtime network service is configured.

## Offline Constraints & Data Storage
- **Connectivity:** This game is strictly offline. No active internet connection is required to play.
- **Profiles:** The game supports up to **5 local player profiles (save slots)**. 
- **Data Storage:** Data for each of the 5 profiles is saved entirely on the local device (using local storage solutions like Hive, SharedPreferences, or sqflite). There is no cloud sync, analytics, or server-side logic dependencies.
