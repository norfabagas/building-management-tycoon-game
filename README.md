# Building Management Tycoon Game

An offline 2D building management tycoon for Android and Web, built with Flutter and Dart.

[Open the Web app](https://building-management-tycoon-game.netlify.app). The apartment starter release replaces the empty canvas with construction, automatic roads, room management, weekly rent and daily finances. Netlify deployment details and update commands are in [Deployment.md](docs/Deployment.md).

## Run the project

```powershell
./tool/bootstrap.ps1
./tool/flutter.ps1 run -d chrome
```

Use `./tool/flutter.ps1 devices` and `./tool/flutter.ps1 run -d <android-device-id>` for Android. Flutter 3.47.7 and Dart 3.13.5 are pinned in `toolchain.json`.

The app includes the approved branding, five local slots, district naming, an unbounded pannable map, apartment planning and cost review, automatic surrounding roads, construction, tenant rooms and finance statements. Apartment rent pays weekly at in-game Sunday Noon; parking pays daily. Select **Upgrade building** in a building detail to add floors (10 total), parking basements (3 total), standard lifts (3) and an executive lift (1). Full snapshots and missed-time settlement remain local. Other building types, luxury and happiness effects await their catalogs. See [gameplay](docs/Gameplay.md) and [setup](docs/Setup.md) for commands and limitations.

## Documentation
- [Project and scope](docs/Project.md)
- [Visual design and navigation](docs/Design.md)
- [Rules and mechanics](docs/Rules.md)
- [Game logic](docs/Logic.md)
- [Selected economy and Sunday apartment billing](docs/Economy.md)
- [Playable apartment starter and local game saves](docs/Gameplay.md)
- [Original three economy alternatives](docs/EconomyOptions.md)
- [Platforms and offline storage](docs/Platform.md)
- [Canva component specification and design setup](docs/DesignKit.md)
- [BM tower icon and title artwork](design/brand/README.md)
- [Project setup and architecture](docs/Setup.md)
- [Runtime assets and animation specification](docs/Assets.md)
- [Web hosting and Netlify deployment status](docs/Deployment.md)

The game component inventory and shared visual rules are in `docs/DesignKit.md`. The user approved the current [Canva design system](https://www.canva.com/d/51ESDDCqVSdEOVT) on 2026-10-11. It contains 16 rebuilt tycoon boards, ordered 01–16, with the defined BM logo on every page. Artwork, native controls, editable export and previews are in `design/tycoon/`. The app reuses these assets; the full gameplay screens remain design references until their features are implemented.
