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
    const Size(320, 568),
    const Size(568, 320),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('upgrade review, reservation and cancellation at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
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
          ),
        ],
      );
      await tester.runAsync(
        () => GameRepository.store.record('1').put(database, state.toJson()),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          theme: buildGameTheme(),
          home: DistrictScreen(
            profile: localProfile,
            repository: FixedClockGameRepository(
              open: () async => database,
              fixedNow: state.watermark,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final map = tester.getRect(find.byKey(const ValueKey('district-map')));
      await tester.tapAt(
        map.topLeft + MapProjection(map.size, Offset.zero).point(1, 1),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upgrade building'));
      await tester.pumpAndSettle();
      expect(find.text('Apartment 1 · Upgrades'), findsOneWidget);
      expect(find.text('1 / 10'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('upgrade-basement')),
          matching: find.text('1 / 3'),
        ),
        findsOneWidget,
      );
      expect(find.text('0 / 3'), findsOneWidget);
      expect(find.text('0 / 1'), findsOneWidget);
      final floorCard = find.byKey(const ValueKey('upgrade-floor'));
      final review = find.descendant(
        of: floorCard,
        matching: find.text('Review upgrade'),
      );
      await tester.ensureVisible(review);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(find.text(r'Price: $8,000.00'), findsOneWidget);
      expect(find.text(r'Added upkeep: $40.00 / day'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      final untouched = (await tester.runAsync(
        () => GameRepository.store.record('1').get(database),
      ))!;
      expect(DistrictGame.fromJson(untouched).balance, state.balance);
      await tester.tap(review);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm upgrade'));
      await tester.pumpAndSettle();
      expect(find.text('Add floor · Queued'), findsOneWidget);
      final source = (await tester.runAsync(
        () => GameRepository.store.record('1').get(database),
      ))!;
      final reserved = DistrictGame.fromJson(source);
      expect(reserved.balance, state.balance - 800000);
      expect(find.text(formatMoney(state.balance - 800000)), findsOneWidget);
      expect(find.text('Available'), findsNothing);
      expect(find.text('Dollars'), findsNothing);
      expect(find.text('Pending rent'), findsNothing);
      expect(reserved.buildings.single.upgrade!.kind, BuildingUpgrade.floor);
      await tester.ensureVisible(find.text('Cancel upgrade'));
      await tester.tap(find.text('Cancel upgrade'));
      await tester.pumpAndSettle();
      expect(find.text('Add floor · Queued'), findsNothing);
      final canceled = (await tester.runAsync(
        () => GameRepository.store.record('1').get(database),
      ))!;
      expect(DistrictGame.fromJson(canceled).balance, state.balance);
      await tester.ensureVisible(find.text('Back to floors'));
      await tester.tap(find.text('Back to floors'));
      await tester.pumpAndSettle();
      expect(find.text('Upgrade building'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(database.close);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'upgraded floors show separate rooms, basement counts and maximums at $size',
      (tester) async {
        tester.view.physicalSize = size;
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
              aboveGroundFloors: 10,
              undergroundFloors: 3,
              standardLifts: 3,
              executiveLifts: 1,
              occupied: {0, 3, 29},
            ),
          ],
        );
        await tester.runAsync(
          () => GameRepository.store.record('1').put(database, state.toJson()),
        );
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            theme: buildGameTheme(),
            home: DistrictScreen(
              profile: localProfile,
              repository: GameRepository(open: () async => database),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final map = tester.getRect(find.byKey(const ValueKey('district-map')));
        await tester.tapAt(
          map.topLeft + MapProjection(map.size, Offset.zero).point(1, 1),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Go up'));
        await tester.pumpAndSettle();
        expect(find.text('Current floor: Floor 2'), findsOneWidget);
        expect(find.text('Room 4'), findsOneWidget);
        expect(find.text('Room 1'), findsNothing);
        for (var i = 0; i < 8; i++) {
          await tester.tap(find.text('Go up'));
          await tester.pump();
        }
        expect(find.text('Current floor: Floor 10'), findsOneWidget);
        expect(find.text('Room 30'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Go up'))
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('Upgrade building'));
        await tester.pumpAndSettle();
        expect(find.text('Maximum reached'), findsNWidgets(4));
        for (final button in tester.widgetList<FilledButton>(
          find.widgetWithText(FilledButton, 'Maximum reached'),
        )) {
          expect(button.onPressed, isNull);
        }
        for (var i = 0; i < 12; i++) {
          await tester.tap(find.text('Go down'));
          await tester.pump();
        }
        expect(find.text('Current floor: B3'), findsOneWidget);
        expect(find.text('B3 · Parking only'), findsOneWidget);
        expect(find.text('Room 30'), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Go down'),
              )
              .onPressed,
          isNull,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(database.close);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('completed building waits for manual opening at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = (await tester.runAsync(openNewInMemoryDatabase))!;
      final repository = GameRepository(open: () async => database);
      const site = Footprint(0, 0, 2, 2);
      final state = DistrictGame(
        watermark: DateTime.now().millisecondsSinceEpoch,
        nextBuildingId: 2,
        buildings: [
          ApartmentBuilding(
            id: 1,
            footprint: site,
            stage: ConstructionStage.parkingDone,
          ),
        ],
      );
      await tester.runAsync(
        () => GameRepository.store.record('1').put(database, state.toJson()),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          theme: buildGameTheme(),
          home: DistrictScreen(profile: localProfile, repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      final map = tester.getRect(find.byKey(const ValueKey('district-map')));
      final projection = MapProjection(map.size, Offset.zero);
      final art = projection.buildingRect(site);
      final facade = Offset(art.center.dx, art.top + art.height * .25);
      expect(site.contains(projection.cellAt(facade)), isFalse);
      await tester.tapAt(map.topLeft + facade);
      await tester.pumpAndSettle();
      expect(find.text('Construction · 100%'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const ValueKey('construction-progress')),
            )
            .value,
        1,
      );
      expect(find.text('Room 1'), findsNothing);
      await tester.ensureVisible(find.text('Open to Business'));
      await tester.tap(find.text('Open to Business'));
      await tester.pumpAndSettle();
      expect(find.text('Open to Business'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Room 1'), findsOneWidget);
      final saved = (await tester.runAsync(
        () => GameRepository.store.record('1').get(database),
      ))!;
      final opened = DistrictGame.fromJson(saved);
      expect(opened.buildings.single.stage, ConstructionStage.ready);
      expect(opened.buildings.single.occupied, isEmpty);
      expect(opened.balance, state.balance);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(database.close);
      expect(tester.takeException(), isNull);
    });

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
            footprint: const Footprint(0, 0, 2, 2),
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
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
      await tester.tapAt(map.topLeft + projection.point(1, 1));
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
      if (size.height < 500) {
        // The distant building is outside the shallow map: use its directory.
        await tester.ensureVisible(find.text('Tenants'));
        await tester.tap(find.text('Tenants'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Apartment 2'));
        await tester.tap(find.text('Apartment 2'));
      } else if (size.width < 700) {
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
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            theme: buildGameTheme(),
            home: DistrictScreen(profile: localProfile, repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        if (size.width < 700 || size.height < 500) {
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  (widget.properties.label ?? '').startsWith('Balance '),
            ),
            findsOneWidget,
          );
          expect(find.text(r'$40,000.00'), findsOneWidget);
        } else {
          expect(find.text('Balance'), findsOneWidget);
        }
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
          map.topLeft + projection.point(0.5, 0.5),
        );
        await gesture.moveTo(map.topLeft + projection.point(1.5, 1.5));
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
        expect(saved.balance, 3000000);
        expect(find.text(r'$30,000.00'), findsOneWidget);
        expect(saved.roads.length, 12);
        expect(find.text('Queued'), findsOneWidget);
        expect(find.text('Construction · 0%'), findsOneWidget);
        expect(find.text('Open to Business'), findsNothing);
        await tester.ensureVisible(find.text('Cancel building'));
        await tester.tap(find.text('Cancel building'));
        await tester.pumpAndSettle();
        final canceled = (await tester.runAsync(
          () => repository.update(
            localProfile,
            DateTime.now().millisecondsSinceEpoch,
          ),
        ))!;
        expect(canceled.buildings, isEmpty);
        expect(canceled.roads, isEmpty);
        expect(canceled.balance, 4000000);
        expect(find.text(r'$40,000.00'), findsOneWidget);
        await tester.ensureVisible(find.text('Finances'));
        await tester.tap(find.text('Finances'));
        await tester.pumpAndSettle();
        expect(find.text('No transactions yet'), findsOneWidget);
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();
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
