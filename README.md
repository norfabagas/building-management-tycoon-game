# Building Management Tycoon Game

An offline 2D building management tycoon for Android and Web, built with Flutter and Dart.

## Run the project

```powershell
./tool/bootstrap.ps1
./tool/flutter.ps1 run -d chrome
```

Use `./tool/flutter.ps1 devices` and `./tool/flutter.ps1 run -d <android-device-id>` for Android. Flutter 3.47.7 and Dart 3.13.5 are pinned in `toolchain.json`.

The initial app includes the approved branding, five local profile slots, district naming and an empty map that pans by dragging. The selected economy is Relaxed idle (Option 1): apartment rent pays weekly at in-game Sunday Noon; hotel, office, F&B and parking income pay daily at Noon. This economy is documented and awaits implementation. See [setup, architecture and validation](docs/Setup.md) for build commands, offline Web packaging and current limitations.

## Documentation
- [Project and scope](docs/Project.md)
- [Visual design and navigation](docs/Design.md)
- [Rules and mechanics](docs/Rules.md)
- [Game logic](docs/Logic.md)
- [Selected economy and Sunday apartment billing](docs/Economy.md)
- [Original three economy alternatives](docs/EconomyOptions.md)
- [Platforms and offline storage](docs/Platform.md)
- [Canva component specification and design setup](docs/DesignKit.md)
- [BM tower icon and title artwork](design/brand/README.md)
- [Project setup and architecture](docs/Setup.md)
- [Runtime assets and animation specification](docs/Assets.md)
- [Web hosting status — Netlify skipped](docs/Deployment.md)

The game component inventory and shared visual rules are in `docs/DesignKit.md`. The user approved the current [Canva design system](https://www.canva.com/d/51ESDDCqVSdEOVT) on 2026-10-11. It contains 16 rebuilt tycoon boards, ordered 01–16, with the defined BM logo on every page. Artwork, native controls, editable export and previews are in `design/tycoon/`. The app reuses these assets; the full gameplay screens remain design references until their features are implemented.
