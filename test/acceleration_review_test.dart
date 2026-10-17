import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/acceleration_button.dart';
import 'package:building_management_tycoon/features/district/district_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

DistrictGame shellAtLastHour() => DistrictGame(
  watermark: 0,
  day: 2,
  lastClosing: 1,
  phaseIndex: 3,
  remainder: 5000,
  gems: 5,
  nextBuildingId: 2,
  buildings: [
    ApartmentBuilding(
      id: 1,
      footprint: const Footprint(0, 0, 2, 2),
      stage: ConstructionStage.shell,
      startedDay: 1,
    ),
  ],
);

void main() {
  test('shell confirmation cannot charge for the subsequent B1 job at the same price', () {
    final state = shellAtLastHour();
    final price = DistrictProgression.accelerationCost(
      state,
      state.buildings.single,
    )!;
    final job = DistrictProgression.accelerationJob(state.buildings.single)!;
    expect(price, 1);
    DistrictSimulation.advance(state, 1000);
    expect(state.buildings.single.stage, ConstructionStage.basement);
    expect(
      DistrictProgression.accelerationCost(state, state.buildings.single),
      price,
    );
    final before = state.toJson();
    expect(
      () => DistrictProgression.accelerate(
        state,
        1,
        quotedCost: price,
        quotedJob: job,
      ),
      throwsA(isA<GameplayException>()),
    );
    expect(state.toJson(), before);
    DistrictProgression.accelerate(
      state,
      1,
      quotedCost: price,
      quotedJob: DistrictProgression.accelerationJob(state.buildings.single)!,
    );
    expect(state.gems, 4);
    expect(state.buildings.single.rushed, isTrue);
  });

  test(
    'a repeated upgrade needs a new review even when kind and price match',
    () {
      final building = ApartmentBuilding(
        id: 1,
        footprint: const Footprint(0, 0, 2, 2),
        stage: ConstructionStage.ready,
        upgrade: UpgradeOrder(
          kind: BuildingUpgrade.basement,
          stage: UpgradeStage.building,
          startedDay: 1,
        ),
      );
      final state = DistrictGame(
        watermark: 0,
        gems: 5,
        nextBuildingId: 2,
        buildings: [building],
      );
      final oldJob = DistrictProgression.accelerationJob(building)!;
      DistrictSimulation.advance(state, 24000);
      expect(building.completedBasements, 2);
      DistrictSimulation.orderUpgrade(state, 1, BuildingUpgrade.basement);
      DistrictSimulation.advance(state, 48000);
      expect(DistrictProgression.accelerationCost(state, building), 1);
      expect(DistrictProgression.accelerationJob(building), isNot(oldJob));
      final before = state.toJson();
      expect(
        () => DistrictProgression.accelerate(
          state,
          1,
          quotedCost: 1,
          quotedJob: oldJob,
        ),
        throwsA(isA<GameplayException>()),
      );
      expect(state.toJson(), before);
    },
  );

  test(
    'a stale confirmation rolls back catch-up and a retry settles only once',
    () async {
      final db = await openNewInMemoryDatabase();
      addTearDown(db.close);
      final profile = LocalProfile(
        slot: 1,
        areaName: 'Review test',
        createdAt: DateTime(2020),
      );
      final state = shellAtLastHour();
      final job = DistrictProgression.accelerationJob(state.buildings.single)!;
      final original = state.toJson();
      await GameRepository.store.record('1').put(db, original);
      final repository = GameRepository(open: () async => db);
      await expectLater(
        repository.update(
          profile,
          1000,
          (latest) => DistrictProgression.accelerate(
            latest,
            1,
            quotedCost: 1,
            quotedJob: job,
          ),
        ),
        throwsA(isA<GameplayException>()),
      );
      expect(await GameRepository.store.record('1').get(db), original);
      final caughtUp = await repository.update(profile, 1000);
      expect(caughtUp.gems, 5);
      expect(caughtUp.buildings.single.stage, ConstructionStage.basement);
      expect(caughtUp.buildings.single.rushed, isFalse);
      expect(
        (await repository.update(profile, 1000)).toJson(),
        caughtUp.toJson(),
      );
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'open acceleration dialog retains the reviewed shell across midnight at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = (await tester.runAsync(openNewInMemoryDatabase))!;
        final repository = GameRepository(open: () async => db);
        await tester.runAsync(
          () => GameRepository.store
              .record('1')
              .put(db, shellAtLastHour().toJson()),
        );
        var now = 0;
        final model = DistrictViewModel(
          LocalProfile(
            slot: 1,
            areaName: 'Review test',
            createdAt: DateTime(2020),
          ),
          repository,
          now: () => DateTime.fromMillisecondsSinceEpoch(now),
        );
        await tester.runAsync(() => model.save());
        await tester.pumpWidget(
          MaterialApp(
            theme: buildGameTheme(),
            home: Scaffold(
              body: AnimatedBuilder(
                animation: model,
                builder: (_, _) => AccelerationButton(
                  model: model,
                  building: model.game!.buildings.single,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Accelerate · 1 gem'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Apartment shell'), findsOneWidget);
        now = 1000;
        await tester.runAsync(() => model.save());
        await tester.pumpAndSettle();
        expect(model.game!.buildings.single.stage, ConstructionStage.basement);
        await tester.tap(find.text('Confirm acceleration'));
        await tester.pumpAndSettle();
        final saved = (await tester.runAsync(
          () => GameRepository.store.record('1').get(db),
        ))!;
        await tester.pumpAndSettle();
        expect(model.error, 'The job changed. Review acceleration again.');
        final actual = DistrictGame.fromJson(saved);
        expect(actual.gems, 5);
        expect(actual.buildings.single.rushed, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        model.dispose();
        await tester.runAsync(db.close);
      },
    );
  }
}
