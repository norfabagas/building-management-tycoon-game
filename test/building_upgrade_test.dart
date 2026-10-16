import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/game_rules.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/district_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

DistrictGame district() => DistrictGame(
  watermark: 0,
  balance: 100000000,
  nextBuildingId: 2,
  buildings: [
    ApartmentBuilding(
      id: 1,
      footprint: const Footprint(0, 0, 2, 4),
      stage: ConstructionStage.ready,
      occupied: {0, 1, 2, 3, 4, 5},
      pendingRent: 12345,
    ),
  ],
);

void at(DistrictGame state, int day, [GamePhase phase = GamePhase.morning]) =>
    DistrictSimulation.advance(state, (day - 1) * 24000 + phase.index * 6000);

void finish(DistrictGame state, BuildingUpgrade kind) {
  DistrictSimulation.orderUpgrade(state, 1, kind);
  for (
    var step = 0;
    state.buildings.single.upgrade != null && step < 20;
    step++
  ) {
    DistrictSimulation.advance(state, state.watermark + 5000);
  }
  expect(state.buildings.single.upgrade, isNull);
}

void main() {
  test(
    'floor charges immediately, completes after two days and keeps tenants',
    () {
      final state = district();
      final building = state.buildings.single;
      final original = building.footprint.toJson();
      final balance = state.balance;
      DistrictSimulation.orderUpgrade(state, 1, BuildingUpgrade.floor);
      expect(state.balance, balance - 1600000);
      expect(building.rooms, 6);
      at(state, 1, GamePhase.noon);
      expect(state.statement!.purchases, 1600000);
      expect(state.balance, balance - 1600000 - 3120);
      final paid = state.toJson();
      at(state, 1, GamePhase.noon);
      expect(state.toJson(), paid);
      at(state, 2);
      expect(building.upgrade!.stage, UpgradeStage.building);
      expect(DistrictSimulation.upgradeProgress(state, building), 0);
      expect(
        DistrictSimulation.upgradeProgress(
          state,
          building,
          elapsedMilliseconds: 2500,
        ),
        closeTo(2500 / 48000, .00001),
      );
      at(state, 2, GamePhase.noon);
      expect(building.aboveGroundFloors, 1);
      at(state, 3, GamePhase.noon);
      expect(building.aboveGroundFloors, 2);
      expect(building.rooms, 12);
      // Midnight completes work, then runs the new day's admissions.
      expect(building.occupied, {0, 1, 2, 3, 4, 5, 6, 7, 8});
      expect(building.footprint.toJson(), original);
      expect(building.stage, ConstructionStage.ready);
      expect(building.valuation, 3600000);
      expect(state.statement!.maintenance, 12000);
      expect(state.statement!.purchases, 0);
      expect(state.statement!.tax, 1920);
      at(state, 4);
      expect(building.occupied.length, 9);
      expect(building.occupied.contains(6), isTrue);
    },
  );

  for (final kind in BuildingUpgrade.values) {
    test(
      '${kind.name} completes at its cap, rejects the next order without mutation',
      () {
        final state = district();
        final building = state.buildings.single;
        while (kind.count(building) < kind.maximum) {
          final before = kind.count(building);
          finish(state, kind);
          expect(kind.count(building), before + 1);
          expect(building.stage, ConstructionStage.ready);
          expect(
            DistrictGame.fromJson(state.toJson()).toJson(),
            state.toJson(),
          );
        }
        final snapshot = state.toJson();
        expect(
          () => DistrictSimulation.orderUpgrade(state, 1, kind),
          throwsA(isA<GameplayException>()),
        );
        expect(state.toJson(), snapshot);
      },
    );
  }

  test('lift prices use the original floor plus B1, upkeep and valuation apply on completion', () {
    final state = district();
    final building = state.buildings.single;
    finish(state, BuildingUpgrade.floor);
    finish(state, BuildingUpgrade.basement);
    expect(BuildingUpgrade.standardLift.cost(building), 500000);
    expect(BuildingUpgrade.executiveLift.cost(building), 1000000);
    final maintenance = building.maintenance;
    final valuation = building.valuation;
    finish(state, BuildingUpgrade.standardLift);
    expect(building.maintenance, maintenance + 4000);
    expect(building.valuation, valuation + 500000);
    finish(state, BuildingUpgrade.executiveLift);
    expect(building.maintenance, maintenance + 8000);
    expect(building.valuation, valuation + 1500000);
    expect(BuildingUpgrade.standardLift.cost(building), 500000);
  });

  test(
    'parking caps all floors and released upper-floor room uses a stable ID',
    () {
      final state = district();
      final building = state.buildings.single..aboveGroundFloors = 10;
      at(state, 10);
      expect(building.occupied.length, 16);
      expect(building.rooms, 60);
      expect(building.bays, 16);
      building.occupied.remove(0);
      building.occupied.add(59);
      at(state, 11);
      expect(building.occupied.length, 16);
      expect(building.occupied.contains(0), isFalse);
      expect(building.occupied.contains(59), isTrue);
      final pending = building.pendingRent;
      DistrictSimulation.vacate(state, 1, 59);
      expect(building.pendingRent, pending);
      at(state, 12);
      expect(building.occupied.length, 16);
      finish(state, BuildingUpgrade.basement);
      expect(building.bays, 32);
      at(state, state.day + 10);
      expect(building.occupied.length, 32);
      finish(state, BuildingUpgrade.basement);
      at(state, state.day + 10);
      expect(building.occupied.length, 48);
    },
  );

  test('upgrades refund immediately; duplicate, unaffordable and unopened orders do not mutate', () {
    final state = district();
    final building = state.buildings.single;
    DistrictSimulation.orderUpgrade(state, 1, BuildingUpgrade.standardLift);
    final queued = state.toJson();
    expect(
      () => DistrictSimulation.orderUpgrade(state, 1, BuildingUpgrade.floor),
      throwsA(isA<GameplayException>()),
    );
    expect(state.toJson(), queued);
    DistrictSimulation.cancelUpgrade(state, 1);
    expect(state.balance, 100000000);
    state.balance = 499999;
    final poor = state.toJson();
    expect(
      () => DistrictSimulation.orderUpgrade(
        state,
        1,
        BuildingUpgrade.standardLift,
      ),
      throwsA(isA<GameplayException>()),
    );
    expect(state.toJson(), poor);
    state.balance = 100000000;
    building.stage = ConstructionStage.parkingDone;
    building.occupied.clear();
    final closed = state.toJson();
    expect(
      () => DistrictSimulation.orderUpgrade(state, 1, BuildingUpgrade.basement),
      throwsA(isA<GameplayException>()),
    );
    expect(state.toJson(), closed);
  });

  test(
    'offline queued upgrades equal individual phases and never settle twice',
    () {
      for (final kind in BuildingUpgrade.values) {
        final online = district();
        DistrictSimulation.orderUpgrade(online, 1, kind);
        final offline = DistrictGame.fromJson(online.toJson());
        for (var tick = 1; tick <= 100; tick++) {
          DistrictSimulation.advance(online, tick * 5000);
        }
        DistrictSimulation.advance(offline, 500000);
        expect(offline.toJson(), online.toJson());
        final saved = offline.toJson();
        DistrictSimulation.advance(offline, 500000);
        DistrictSimulation.advance(offline, 0);
        expect(offline.toJson(), saved);
      }
    },
  );

  test('schema 1/2/3 migration retains rooms and rent; corrupt caps and orders are rejected', () {
    for (final version in [1, 2, 3]) {
      final source = district().toJson()
        ..['version'] = version
        ..['phaseMilliseconds'] = 5000;
      for (final b in source['buildings'] as List) {
        for (final field in [
          'aboveGroundFloors',
          'undergroundFloors',
          'standardLifts',
          'executiveLifts',
          'upgrade',
        ]) {
          (b as Map).remove(field);
        }
      }
      final migrated = DistrictGame.fromJson(source);
      expect(migrated.toJson()['version'], 5);
      expect(migrated.buildings.single.aboveGroundFloors, 1);
      expect(migrated.buildings.single.completedBasements, 1);
      expect(migrated.buildings.single.occupied, {0, 1, 2, 3, 4, 5});
      expect(migrated.pendingRent, 12345);
    }
    for (final field in [
      'aboveGroundFloors',
      'undergroundFloors',
      'standardLifts',
      'executiveLifts',
    ]) {
      final source = district().toJson();
      ((source['buildings'] as List).single as Map)[field] = 11;
      expect(() => DistrictGame.fromJson(source), throwsFormatException);
    }
    final invalid = district().toJson();
    ((invalid['buildings'] as List).single as Map)['upgrade'] = {
      'kind': 'floor',
      'stage': 'building',
      'startedDay': 0,
    };
    expect(() => DistrictGame.fromJson(invalid), throwsFormatException);
  });

  test('transaction rollback and competing upgrade requests charge exactly one purchase', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    final profile = LocalProfile(
      slot: 1,
      areaName: 'Upgrades',
      createdAt: DateTime(2026),
    );
    final initial = district().toJson();
    await GameRepository.store.record('1').put(database, initial);
    await expectLater(
      repository.update(profile, 0, (s) {
        DistrictSimulation.orderUpgrade(s, 1, BuildingUpgrade.floor);
        throw StateError('failed save');
      }),
      throwsStateError,
    );
    expect(await GameRepository.store.record('1').get(database), initial);
    final requests = await Future.wait([
      repository
          .update(
            profile,
            0,
            (s) => DistrictSimulation.orderUpgrade(s, 1, BuildingUpgrade.floor),
          )
          .then((_) => true, onError: (_) => false),
      repository
          .update(
            profile,
            0,
            (s) =>
                DistrictSimulation.orderUpgrade(s, 1, BuildingUpgrade.basement),
          )
          .then((_) => true, onError: (_) => false),
    ]);
    expect(requests.where((success) => success).length, 1);
    final queued = await repository.update(profile, 0);
    expect(queued.buildings.single.upgrade, isNotNull);
    expect(
      queued.balance,
      100000000 -
          queued.buildings.single.upgrade!.kind.cost(queued.buildings.single),
    );
    await database.close();
  });

  test('navigation reaches Floor 10 through B3, skips zero and stops at boundaries', () async {
    final database = await openNewInMemoryDatabase();
    final state = district();
    state.buildings.single
      ..aboveGroundFloors = 10
      ..undergroundFloors = 3;
    await GameRepository.store.record('1').put(database, state.toJson());
    final model = DistrictViewModel(
      LocalProfile(slot: 1, areaName: 'Floors', createdAt: DateTime(2026)),
      GameRepository(open: () async => database),
      now: () => DateTime.fromMillisecondsSinceEpoch(0),
    );
    await model.save();
    model.selectBuilding(1);
    expect(model.currentFloor, 1);
    for (var floor = 2; floor <= 10; floor++) {
      model.goUp();
      expect(model.floorLabel, 'Floor $floor');
    }
    expect(model.canGoUp, isFalse);
    model.goUp();
    expect(model.currentFloor, 10);
    while (model.canGoDown) {
      model.goDown();
      expect(model.currentFloor, isNot(0));
    }
    expect(model.floorLabel, 'B3');
    model.goDown();
    expect(model.currentFloor, -3);
    model.selectBuilding(1);
    expect(model.currentFloor, 1);
    model.dispose();
    await database.close();
  });
}
