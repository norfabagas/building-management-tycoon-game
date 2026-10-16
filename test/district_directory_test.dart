import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/district_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'district directories open the saved tenant floor and upgrades at $size',
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
              footprint: const Footprint(3, 3, 2, 2),
              stage: ConstructionStage.ready,
              aboveGroundFloors: 2,
              occupied: {3},
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
              profile: LocalProfile(
                slot: 1,
                areaName: 'Riverside',
                createdAt: DateTime(2020),
              ),
              repository: GameRepository(open: () async => database),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tenants'));
        await tester.pumpAndSettle();
        expect(find.text('District tenants'), findsOneWidget);
        final tenant = find.byKey(const ValueKey('tenant-1-3'));
        await tester.ensureVisible(tenant);
        await tester.tap(tenant);
        await tester.pumpAndSettle();
        expect(find.text('Current floor: Floor 2'), findsOneWidget);
        expect(find.text('Room 4'), findsOneWidget);
        await tester.ensureVisible(find.text('Room 4'));
        await tester.tap(find.text('Room 4'));
        await tester.pumpAndSettle();
        expect(find.text('Parking: 1 reserved bay'), findsOneWidget);
        await tester.tap(find.text('Keep tenant'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Exit building'));
        await tester.pumpAndSettle();
        expect(find.text('District tenants'), findsOneWidget);
        await tester.ensureVisible(find.text('Upgrades'));
        await tester.tap(find.text('Upgrades'));
        await tester.pumpAndSettle();
        expect(find.text('District upgrades'), findsOneWidget);
        await tester.ensureVisible(find.text('Apartment 1'));
        await tester.tap(find.text('Apartment 1'));
        await tester.pumpAndSettle();
        expect(find.text('Apartment 1 · Upgrades'), findsOneWidget);
        await tester.tap(find.text('Exit building'));
        await tester.pumpAndSettle();
        expect(find.text('District upgrades'), findsOneWidget);
        final saved = (await tester.runAsync(
          () => GameRepository.store.record('1').get(database),
        ))!;
        expect(DistrictGame.fromJson(saved).buildings.single.occupied, {3});
        expect(DistrictGame.fromJson(saved).pendingRent, 12000);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(database.close);
      },
    );
  }
}
