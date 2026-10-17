import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/district_view_model.dart';
import 'package:building_management_tycoon/features/district/tenant_activity_screen.dart';
import 'package:building_management_tycoon/features/district/tenant_activity_view_model.dart';
import 'package:building_management_tycoon/shared/widgets/asset_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final type in BuildingType.values) {
      testWidgets('$type interior fills $size and reads live saved state', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = (await tester.runAsync(openNewInMemoryDatabase))!;
        final now = DateTime(2026, 10, 17);
        final building = ApartmentBuilding(
          id: 1,
          type: type,
          footprint: const Footprint(0, 0, 2, 2),
          stage: ConstructionStage.ready,
          occupied: type == BuildingType.foodCourt ? {} : {0},
          currentVisitors: type == BuildingType.foodCourt ? 3 : 0,
          visitorCapacity: type == BuildingType.foodCourt ? 4 : 0,
          visitsToday: type == BuildingType.foodCourt ? 7 : 0,
          salesToday: type == BuildingType.foodCourt ? 17500 : 0,
          pendingRent: type == BuildingType.apartment ? 12000 : 0,
        );
        final state = DistrictGame(
          watermark: now.millisecondsSinceEpoch,
          nextBuildingId: 2,
          buildings: [building],
        );
        await tester.runAsync(
          () => GameRepository.store.record('1').put(db, state.toJson()),
        );
        final model = DistrictViewModel(
          LocalProfile(slot: 1, areaName: 'Interiors', createdAt: now),
          GameRepository(open: () async => db),
          now: () => now,
        );
        await tester.runAsync(model.save);
        var managed = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildGameTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => TenantActivityScreen(
                        model: model,
                        buildingId: 1,
                        unit: 0,
                        onManage: () async {
                          managed++;
                        },
                      ),
                    ),
                  ),
                  child: const Text('Enter unit'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Enter unit'));
        await tester.pumpAndSettle();
        final page = find.byKey(const ValueKey('tenant-fullscreen'));
        expect(tester.getSize(page), size);
        // The complete cutaway, including its floor and actors, fits above
        // the fold even on short landscape screens.
        expect(
          tester
              .getRect(find.byKey(const ValueKey('tenant-interior-art')))
              .bottom,
          lessThanOrEqualTo(size.height),
        );
        expect(find.text('A day inside'), findsOneWidget);
        expect(find.text('00:00–06:00'), findsOneWidget);
        expect(find.text('18:00–24:00'), findsOneWidget);
        if (type == BuildingType.foodCourt) {
          expect(find.text('Manage'), findsNothing);
          expect(find.text('3 / 4 parties on this floor'), findsOneWidget);
          await tester.ensureVisible(
            find.text('Sales awaiting midnight: \$175.00'),
          );
          expect(
            find.text('Sales awaiting midnight: \$175.00'),
            findsOneWidget,
          );
        } else {
          await tester.tap(find.text('Manage'));
          expect(managed, 1);
        }
        // A snapshot replacement must refresh the open route without re-entry.
        await tester.runAsync(
          () => model.save((game) {
            game.phaseIndex = 1;
          }),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Day 1 · 06:00 · Day'), findsOneWidget);
        expect(
          find.byType(AssetAnimation),
          type == BuildingType.foodCourt ? findsNWidgets(3) : findsOneWidget,
        );
        if (type != BuildingType.foodCourt) {
          await tester.runAsync(
            () => model.save((game) => DistrictSimulation.vacate(game, 1, 0)),
          );
          await tester.pumpAndSettle();
          expect(find.text('Waiting for occupants'), findsOneWidget);
          expect(find.byType(AssetAnimation), findsNothing);
          final manage = tester.widget<TextButton>(
            find.widgetWithText(TextButton, 'Manage'),
          );
          expect(manage.onPressed, isNull);
        }
        final saved = (await tester.runAsync(
          () => GameRepository.store.record('1').get(db),
        ))!;
        final result = DistrictGame.fromJson(saved);
        expect(result.balance, state.balance);
        expect(result.pendingRent, state.pendingRent);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Enter unit'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        model.dispose();
        await tester.runAsync(db.close);
      });
    }
  }

  test(
    'food floor allocation and vacant/quiet interiors do not invent occupants',
    () {
      final food = ApartmentBuilding(
        id: 1,
        type: BuildingType.foodCourt,
        footprint: const Footprint(0, 0, 2, 2),
        stage: ConstructionStage.ready,
        aboveGroundFloors: 3,
        currentVisitors: 5,
        visitorCapacity: 12,
        visitsToday: 5,
      );
      final game = DistrictGame(watermark: 0, buildings: [food]);
      expect(TenantActivityViewModel(game, food, 4).visitors, 1);
      expect(TenantActivityViewModel(game, food, 8).active, isFalse);
      final office = ApartmentBuilding(
        id: 2,
        type: BuildingType.office,
        footprint: const Footprint(4, 0, 2, 2),
        stage: ConstructionStage.ready,
        occupied: {0},
      );
      game.phaseIndex = 3;
      final view = TenantActivityViewModel(game, office, 0);
      expect(view.active, isTrue);
      expect(view.showPeople, isFalse);
      expect(view.current.label, 'Quiet office');
      office.occupied.clear();
      expect(view.active, isFalse);
    },
  );
}
