import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/district_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

Future<void> press(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final acceleration in [false, true]) {
      testWidgets(
        '${acceleration ? 'acceleration' : 'luxury'} review, confirm and cancellation at $size',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = (await tester.runAsync(openNewInMemoryDatabase))!;
          final state = DistrictGame(
            watermark: DateTime.now().millisecondsSinceEpoch,
            balance: acceleration ? 3200000 : 4000000,
            gems: 5,
            achievements: {Achievement.firstBusiness},
            nextBuildingId: 2,
            buildings: [
              ApartmentBuilding(
                id: 1,
                footprint: const Footprint(3, 3, 2, 2),
                stage: ConstructionStage.ready,
                occupied: {0},
                pendingRent: 12000,
                upgrade: acceleration
                    ? UpgradeOrder(
                        kind: BuildingUpgrade.floor,
                        stage: UpgradeStage.building,
                        startedDay: 1,
                      )
                    : null,
              ),
            ],
          );
          await tester.runAsync(
            () => GameRepository.store.record('1').put(db, state.toJson()),
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: buildGameTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: DistrictScreen(
                profile: LocalProfile(
                  slot: 1,
                  areaName: 'Test',
                  createdAt: DateTime(2020),
                ),
                repository: GameRepository(open: () async => db),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await press(tester, 'Upgrades');
          await press(tester, 'Apartment 1');
          if (acceleration) {
            await press(tester, 'Accelerate · 2 gems');
            expect(find.text('Accelerate active job'), findsOneWidget);
            await press(tester, 'Cancel');
            final untouched = (await tester.runAsync(
              () => GameRepository.store.record('1').get(db),
            ))!;
            expect(DistrictGame.fromJson(untouched).gems, 5);
            await press(tester, 'Accelerate · 2 gems');
            await press(tester, 'Confirm acceleration');
            final charged = (await tester.runAsync(
              () => GameRepository.store.record('1').get(db),
            ))!;
            expect(DistrictGame.fromJson(charged).gems, 3);
            expect(
              DistrictGame.fromJson(charged).buildings.single.upgrade!.rushed,
              isTrue,
            );
            expect(
              find.text('Accelerated work activates next Morning.'),
              findsOneWidget,
            );
          } else {
            final review = find.descendant(
              of: find.byKey(const ValueKey('upgrade-luxury')),
              matching: find.text('Review upgrade'),
            );
            await tester.ensureVisible(review);
            await tester.tap(review);
            await tester.pumpAndSettle();
            expect(find.text(r'Price: $3,000.00'), findsOneWidget);
            await press(tester, 'Cancel');
            final untouched = (await tester.runAsync(
              () => GameRepository.store.record('1').get(db),
            ))!;
            expect(DistrictGame.fromJson(untouched).balance, 4000000);
            await tester.tap(review);
            await tester.pumpAndSettle();
            await press(tester, 'Confirm upgrade');
            final charged = (await tester.runAsync(
              () => GameRepository.store.record('1').get(db),
            ))!;
            expect(DistrictGame.fromJson(charged).balance, 3700000);
            expect(
              DistrictGame.fromJson(charged).buildings.single.upgrade!.kind,
              BuildingUpgrade.luxury,
            );
          }
          await press(tester, 'Cancel upgrade');
          final refunded = DistrictGame.fromJson(
            (await tester.runAsync(
              () async => (await GameRepository.store.record('1').get(db))!,
            ))!,
          );
          expect(refunded.balance, 4000000);
          expect(refunded.gems, 5);
          expect(refunded.pendingRent, 12000);
          expect(refunded.buildings.single.occupied, {0});
          expect(refunded.buildings.single.luxury, 1);
          expect(refunded.buildings.single.aboveGroundFloors, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(db.close);
        },
      );
    }
  }
}
