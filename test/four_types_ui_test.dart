import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/district_screen.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:building_management_tycoon/features/district/building_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

final profile = LocalProfile(
  slot: 1,
  areaName: 'Four Seasons',
  createdAt: DateTime(2020),
);
Widget gameApp(GameRepository repository) => MaterialApp(
  theme: buildGameTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: DistrictScreen(profile: profile, repository: repository),
);
Future<void> click(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> chooseTile(WidgetTester tester, double x, double y) async {
  final map = tester.getRect(find.byKey(const ValueKey('district-map')));
  await tester.tapAt(
    map.topLeft + MapProjection(map.size, Offset.zero).point(x, y),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final type in [
      BuildingType.hotel,
      BuildingType.office,
      BuildingType.foodCourt,
    ]) {
      testWidgets(
        '${type.label} multi-floor purchase and full refund at $size',
        (tester) async {
          viewport(tester, size);
          final db = (await tester.runAsync(openNewInMemoryDatabase))!;
          final repository = GameRepository(open: () async => db);
          await tester.pumpWidget(gameApp(repository));
          await tester.pumpAndSettle();
          await click(tester, 'Build');
          await click(tester, 'Choose ${type.label.toLowerCase()}');
          await tester.ensureVisible(
            find.byKey(const ValueKey('initial-floor-plus')),
          );
          await tester.tap(find.byKey(const ValueKey('initial-floor-plus')));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('initial-floor-count')))
                .data,
            '2',
          );
          final map = tester.getRect(
            find.byKey(const ValueKey('district-map')),
          );
          final projection = MapProjection(map.size, Offset.zero);
          final drag = await tester.startGesture(
            map.topLeft + projection.point(0.5, 0.5),
          );
          await drag.moveTo(map.topLeft + projection.point(1.5, 1.5));
          await drag.up();
          await tester.pumpAndSettle();
          expect(find.text('2 × 2 tiles'), findsOneWidget);
          await click(tester, 'Review cost');
          await click(tester, 'Confirm construction');
          final saved = (await tester.runAsync(
            () async => (await GameRepository.store.record('1').get(db))!,
          ))!;
          final game = DistrictGame.fromJson(saved);
          expect(game.buildings.single.type, type);
          expect(game.buildings.single.initialFloors, 2);
          expect(game.balance, 4000000 - type.quote(4, 2));
          expect(find.text('${type.label} 1'), findsOneWidget);
          await click(tester, 'Cancel building');
          final canceled = (await tester.runAsync(
            () async => (await GameRepository.store.record('1').get(db))!,
          ))!;
          expect(DistrictGame.fromJson(canceled).balance, 4000000);
          expect(DistrictGame.fromJson(canceled).buildings, isEmpty);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(db.close);
        },
      );
    }
    testWidgets(
      'guest room, whole office floor and food facility use distinct saved data at $size',
      (tester) async {
        viewport(tester, size);
        final db = (await tester.runAsync(openNewInMemoryDatabase))!;
        final state = DistrictGame(
          // Keep seeded daily counters stable while real asynchronous images
          // load on busy CI machines. Clock advancement is tested separately.
          watermark: DateTime.now()
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch,
          nextBuildingId: 5,
          buildings: [
            for (var i = 0; i < 4; i++)
              ApartmentBuilding(
                id: i + 1,
                footprint: Footprint(5 + i * 5, 5, 2, 2),
                type: BuildingType.values[i],
                stage: ConstructionStage.ready,
                aboveGroundFloors: 2,
                occupied: i == 3
                    ? {}
                    : i == 1
                    ? {0, 3}
                    : {0},
                currentVisitors: i == 3 ? 3 : 0,
                visitorCapacity: i == 3 ? 8 : 0,
                visitsToday: i == 3 ? 12 : 0,
                salesToday: i == 3 ? 30000 : 0,
                parkingToday: i == 3 ? 12000 : 0,
              ),
          ],
        );
        await tester.runAsync(
          () => GameRepository.store.record('1').put(db, state.toJson()),
        );
        // The reusable game view also works under an enclosing Navigator.
        await tester.pumpWidget(
          MaterialApp(home: gameApp(GameRepository(open: () async => db))),
        );
        await tester.pumpAndSettle();
        await click(tester, 'Tenants');
        final guest = find.byKey(const ValueKey('tenant-2-3'));
        await tester.ensureVisible(guest);
        await tester.tap(guest);
        await tester.pumpAndSettle();
        expect(find.text('Room 4 · Guest'), findsOneWidget);
        await tester.ensureVisible(find.text('Daily base rate: \$160.00'));
        expect(find.text('Daily base rate: \$160.00'), findsOneWidget);
        await click(tester, 'Manage');
        await click(tester, 'Keep tenant');
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Current floor: Floor 2'), findsOneWidget);
        await click(tester, 'Exit building');
        final tenant = find.byKey(const ValueKey('tenant-3-0'));
        await tester.ensureVisible(tenant);
        await tester.tap(tenant);
        await tester.pumpAndSettle();
        expect(find.text('Lease 1 · Corporate tenant'), findsOneWidget);
        await tester.ensureVisible(find.text('Parking: 6 reserved bays'));
        expect(find.text('Parking: 6 reserved bays'), findsOneWidget);
        await click(tester, 'Manage');
        await click(tester, 'End floor lease');
        expect(find.text('Vacant'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await click(tester, 'Exit building');
        await click(tester, 'Food court 4');
        expect(find.text('Floor 1 · Food court'), findsOneWidget);
        await tester.ensureVisible(find.text('Sales awaiting midnight'));
        expect(find.text('\$300.00'), findsOneWidget);
        expect(
          tester
              .widgetList<Image>(find.byType(Image))
              .any(
                (image) =>
                    image.image is AssetImage &&
                    (image.image as AssetImage).assetName ==
                        BuildingType.foodCourt.roomArtwork,
              ),
          isTrue,
        );
        final saved = DistrictGame.fromJson(
          (await tester.runAsync(
            () async => (await GameRepository.store.record('1').get(db))!,
          ))!,
        );
        expect(saved.buildings[2].occupied, isEmpty);
        expect(saved.buildings[1].occupied, {0, 3});
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(db.close);
      },
    );
    testWidgets(
      'achievements and decoration review, cancel, purchase and free move at $size',
      (tester) async {
        viewport(tester, size);
        final db = (await tester.runAsync(openNewInMemoryDatabase))!;
        final state = DistrictGame(
          watermark: DateTime.now().millisecondsSinceEpoch,
          gems: 5,
        );
        await tester.runAsync(
          () => GameRepository.store.record('1').put(db, state.toJson()),
        );
        await tester.pumpWidget(gameApp(GameRepository(open: () async => db)));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('District activities'));
        await tester.pumpAndSettle();
        await click(tester, 'Achievements');
        expect(find.text('Open your first business'), findsOneWidget);
        await tester.tap(find.byTooltip('District activities'));
        await tester.pumpAndSettle();
        await click(tester, 'Decorations');
        await click(tester, 'Place bench');
        await chooseTile(tester, 2.5, 2.5);
        await click(tester, 'Review placement');
        await click(tester, 'Cancel placement');
        final canceled = DistrictGame.fromJson(
          (await tester.runAsync(
            () async => (await GameRepository.store.record('1').get(db))!,
          ))!,
        );
        expect(canceled.gems, 5);
        expect(canceled.decorations, isEmpty);
        await click(tester, 'Place bench');
        await chooseTile(tester, 2.5, 2.5);
        await click(tester, 'Review placement');
        await click(tester, 'Confirm placement');
        final placed = DistrictGame.fromJson(
          (await tester.runAsync(
            () async => (await GameRepository.store.record('1').get(db))!,
          ))!,
        );
        expect(placed.gems, 3);
        expect(placed.decorations.single.cell, const LandCell(2, 2));
        await click(tester, 'Move');
        await chooseTile(tester, 3.5, 2.5);
        await click(tester, 'Review placement');
        await click(tester, 'Confirm placement');
        final moved = DistrictGame.fromJson(
          (await tester.runAsync(
            () async => (await GameRepository.store.record('1').get(db))!,
          ))!,
        );
        expect(moved.gems, 3);
        expect(moved.decorations.single.cell, const LandCell(3, 2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(db.close);
      },
    );
  }
}
