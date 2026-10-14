import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:building_management_tycoon/features/district/district_screen.dart';
import 'package:building_management_tycoon/features/district/district_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'helpers/game_test_store.dart';

final localProfile = LocalProfile(
  slot: 1,
  areaName: 'Riverside',
  createdAt: DateTime(2020),
);

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('building floor navigation replaces map at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = (await tester.runAsync(openNewInMemoryDatabase))!;
      final state = DistrictGame(
        watermark: DateTime.now().millisecondsSinceEpoch,
        nextBuildingId: 3,
        buildings: [
          ApartmentBuilding(
            id: 1,
            footprint: const Footprint(3, 3, 2, 2),
            stage: ConstructionStage.ready,
            occupied: {0},
          ),
          ApartmentBuilding(id: 2, footprint: const Footprint(0, 4, 2, 2)),
        ],
      );
      await tester.runAsync(
        () => GameRepository.store.record('1').put(database, state.toJson()),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildGameTheme(),
          home: DistrictScreen(
            profile: localProfile,
            repository: GameRepository(open: () async => database),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
      await tester.pumpAndSettle();
      final map = tester.getRect(find.byKey(const ValueKey('district-map')));
      final projection = MapProjection(map.size, Offset.zero, zoom: 1.25);
      await tester.tapAt(map.topLeft + projection.point(4, 4));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('district-map')), findsNothing);
      expect(find.byKey(const ValueKey('building-floor-view')), findsOneWidget);
      expect(find.text('Apartment 1'), findsOneWidget);
      expect(find.text('Current floor: Floor 1'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Go up'))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Room 1'));
      await tester.tap(find.text('Go down'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Current floor: B1'), findsOneWidget);
      expect(find.text('B1 · Parking only'), findsOneWidget);
      expect(find.text('Room 1'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Go down'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Go up'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Current floor: Floor 1'), findsOneWidget);
      expect(find.text('Room 1'), findsOneWidget);
      await tester.tap(find.text('Exit building'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('district-map')), findsOneWidget);
      expect(find.text('125%'), findsOneWidget);
      // Select the other building through the native district list.
      if (size.width < 700) {
        // On portrait the list is intentionally collapsed; use the map.
        final nextMap = tester.getRect(
          find.byKey(const ValueKey('district-map')),
        );
        final nextProjection = MapProjection(
          nextMap.size,
          Offset.zero,
          zoom: 1.25,
        );
        await tester.tapAt(nextMap.topLeft + nextProjection.point(1, 5));
      } else {
        await tester.ensureVisible(find.text('Apartment 2'));
        await tester.tap(find.text('Apartment 2'));
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Apartment 2'), findsOneWidget);
      expect(find.text('Current floor: Floor 1'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Go down'))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(database.close);
    });

    testWidgets('draw, review, reserve and cancel apartment at $size', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = testGameRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildGameTheme(),
            home: DistrictScreen(profile: localProfile, repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Dollars'), findsOneWidget);
        await tester.tap(find.text('Build'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Choose apartment'));
        await tester.tap(find.text('Choose apartment'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
        await tester.pumpAndSettle();
        expect(find.text('125%'), findsOneWidget);
        final map = tester.getRect(find.byKey(const ValueKey('district-map')));
        final projection = MapProjection(map.size, Offset.zero, zoom: 1.25);
        final gesture = await tester.startGesture(
          map.topLeft + projection.point(3.5, 3.5),
        );
        await gesture.moveTo(map.topLeft + projection.point(4.5, 4.5));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('2 × 2 tiles'), findsOneWidget);
        await tester.ensureVisible(find.text('Review cost'));
        await tester.tap(find.text('Review cost'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Confirm construction'));
        await tester.tap(find.text('Confirm construction'));
        await tester.pumpAndSettle();
        final saved = (await tester.runAsync(
          () => repository.update(
            localProfile,
            DateTime.now().millisecondsSinceEpoch,
          ),
        ))!;
        expect(saved.buildings.length, 1);
        expect(saved.balance, 4000000);
        expect(saved.reserved, 1000000);
        expect(saved.roads.length, 12);
        expect(find.text('Payment at Noon'), findsOneWidget);
        await tester.ensureVisible(find.text('Cancel unpaid order'));
        await tester.tap(find.text('Cancel unpaid order'));
        await tester.pumpAndSettle();
        final canceled = (await tester.runAsync(
          () => repository.update(
            localProfile,
            DateTime.now().millisecondsSinceEpoch,
          ),
        ))!;
        expect(canceled.buildings, isEmpty);
        expect(canceled.roads, isEmpty);
        expect(canceled.available, 4000000);
        await tester.tap(find.text('Finances'));
        await tester.pumpAndSettle();
        expect(find.text('First closing is still ahead'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
    'loaded operational building shows real rooms and preserved pending rent',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = (await tester.runAsync(openNewInMemoryDatabase))!;
      final state = DistrictGame(
        watermark: DateTime.now().millisecondsSinceEpoch,
        nextBuildingId: 2,
        buildings: [
          ApartmentBuilding(
            id: 1,
            footprint: const Footprint(0, 0, 2, 2),
            stage: ConstructionStage.ready,
            occupied: {0},
            pendingRent: 12000,
          ),
        ],
      );
      await tester.runAsync(
        () => GameRepository.store.record('1').put(database, state.toJson()),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildGameTheme(),
          home: DistrictScreen(
            profile: localProfile,
            repository: GameRepository(open: () async => database),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Apartment 1'));
      await tester.tap(find.text('Apartment 1'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Floor 1 · Rooms'), findsOneWidget);
      expect(find.text('Room 1'), findsOneWidget);
      await tester.ensureVisible(find.text('Room 1'));
      await tester.tap(find.text('Room 1'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Vacate room'));
      await tester.pump(const Duration(seconds: 1));
      final saved = await tester.runAsync(
        () => GameRepository.store.record('1').get(database),
      );
      final result = DistrictGame.fromJson(saved!);
      expect(result.buildings.single.occupied, isEmpty);
      expect(result.pendingRent, 12000);
      expect(formatMoney(result.pendingRent), r'$120.00');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(database.close);
    },
  );
}
