import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/district_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

LocalProfile profile(int slot) => LocalProfile(
  slot: slot,
  areaName: 'District $slot',
  createdAt: DateTime(2020),
);

void main() {
  test('schema 2 completed buildings wait offline; already open buildings stay open', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    for (final slot in [1, 2]) {
      final source = DistrictGame(
        watermark: 0,
        nextBuildingId: 2,
        buildings: [
          ApartmentBuilding(
            id: 1,
            footprint: const Footprint(0, 0, 2, 4),
            stage: slot == 1
                ? ConstructionStage.parkingDone
                : ConstructionStage.ready,
            occupied: slot == 1 ? {} : {0},
            pendingRent: slot == 1 ? 0 : 12000,
          ),
        ],
      ).toJson()..['version'] = 2;
      await GameRepository.store.record('$slot').put(database, source);
    }
    const now = 400000;
    final closed = await repository.update(profile(1), now);
    expect(closed.buildings.single.stage, ConstructionStage.parkingDone);
    expect(closed.buildings.single.occupied, isEmpty);
    expect(closed.earned, 0);
    final before = closed.toJson();
    await expectLater(
      repository.update(profile(1), now, (s) {
        DistrictSimulation.openBusiness(s, 1);
        throw StateError('write failed');
      }),
      throwsStateError,
    );
    expect(await GameRepository.store.record('1').get(database), before);
    final opened = await repository.update(
      profile(1),
      now,
      (s) => DistrictSimulation.openBusiness(s, 1),
    );
    expect(opened.buildings.single.stage, ConstructionStage.ready);
    expect(opened.toJson()['version'], 5);
    final repeated = await repository.update(
      profile(1),
      now,
      (s) => DistrictSimulation.openBusiness(s, 1),
    );
    expect(repeated.toJson(), opened.toJson());
    final existing = await repository.update(profile(2), 0);
    expect(existing.buildings.single.stage, ConstructionStage.ready);
    expect(existing.buildings.single.occupied, {0});
    expect(existing.pendingRent, 12000);
    await database.close();
  });

  test('legacy clock catches up at its old speed and migrates once', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    final legacy =
        DistrictGame(
            watermark: 0,
            remainder: 30000,
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
          ).toJson()
          ..['version'] = 1
          ..remove('phaseMilliseconds');
    await GameRepository.store.record('1').put(database, legacy);
    final migrated = await repository.update(profile(1), 270000);
    expect(migrated.day, 2);
    expect(migrated.phaseIndex, 0);
    expect(migrated.lastClosing, 1);
    expect(migrated.balance, 3996880);
    expect(migrated.pendingRent, 84345);
    expect(migrated.phaseMilliseconds, 5000);
    expect(migrated.toJson()['version'], 5);
    expect(
      (await repository.update(profile(1), 270000)).toJson(),
      migrated.toJson(),
    );
    expect((await repository.update(profile(1), 274999)).phaseIndex, 0);
    expect((await repository.update(profile(1), 275000)).phaseIndex, 1);
    await database.close();
  });

  test('legacy remainder scales even on an unchanged or backward clock', () {
    final legacy = DistrictGame(watermark: 1000, remainder: 30000).toJson()
      ..['version'] = 1
      ..remove('phaseMilliseconds');
    for (final now in [0, 1000]) {
      final state = DistrictGame.fromJson(legacy);
      DistrictSimulation.advance(state, now);
      expect(state.watermark, 1000);
      expect(state.remainder, 2500);
      expect(state.phaseIndex, 0);
      DistrictSimulation.advance(state, 3500);
      expect(state.phaseIndex, 1);
      expect(state.remainder, 0);
    }
  });

  test('failed migration transaction preserves the legacy save', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    final legacy = DistrictGame(watermark: 0, remainder: 59999).toJson()
      ..['version'] = 1
      ..remove('phaseMilliseconds');
    await GameRepository.store.record('1').put(database, legacy);
    await expectLater(
      repository.update(profile(1), 1, (_) => throw StateError('failed write')),
      throwsStateError,
    );
    expect(await GameRepository.store.record('1').get(database), legacy);
    final migrated = await repository.update(profile(1), 1);
    expect(migrated.phaseIndex, 1);
    expect(migrated.remainder, 0);
    await database.close();
  });

  test('countdown follows five-second phase boundaries', () async {
    final database = await openNewInMemoryDatabase();
    var now = 0;
    final model = DistrictViewModel(
      profile(1),
      GameRepository(open: () async => database),
      now: () => DateTime.fromMillisecondsSinceEpoch(now),
    );
    await model.save();
    expect(model.secondsRemaining, 5);
    now = 4999;
    expect(model.secondsRemaining, 1);
    now = 5000;
    expect(model.secondsRemaining, 0);
    await model.save();
    expect(model.game!.phaseIndex, 1);
    expect(model.secondsRemaining, 5);
    model.dispose();
    await database.close();
  });

  test('legacy slots initialize once and transactions serialize simultaneous reservations', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    final initial = await repository.update(profile(1), 1000);
    expect(
      initial.watermark,
      1000,
    ); // Old profile creation is not offline game time.
    final outcomes = await Future.wait([
      repository.update(
        profile(1),
        1000,
        (s) => DistrictSimulation.place(s, const Footprint(0, 0, 2, 4)),
      ),
      repository.update(
        profile(1),
        1000,
        (s) => DistrictSimulation.place(s, const Footprint(3, 0, 2, 4)),
      ),
    ]);
    expect(outcomes.last.buildings.length, 2);
    final reloaded = await repository.update(profile(1), 1000);
    expect(reloaded.balance, 0);
    final second = await repository.update(profile(2), 1000);
    expect(second.balance, 4000000);
    expect(second.buildings, isEmpty);
    final closingTime = 1000 + 4 * StarterCatalog.phaseMilliseconds;
    final paid = await repository.update(profile(1), closingTime);
    expect(paid.balance, 0);
    expect((await repository.update(profile(1), closingTime)).balance, 0);
    await database.close();
  });

  test('failed transaction preserves wallet/ledger; view model publishes no successful mutation', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    final model = DistrictViewModel(
      profile(1),
      repository,
      now: () => DateTime.fromMillisecondsSinceEpoch(0),
    );
    await model.save();
    final before = model.game!.toJson();
    expect(
      await model.save((s) {
        DistrictSimulation.place(s, const Footprint(0, 0, 2, 4));
        throw StateError('storage transaction failed');
      }),
      isFalse,
    );
    expect(model.game!.toJson(), before);
    expect((await repository.update(profile(1), 0)).toJson(), before);
    expect(model.error, isNotNull);
    expect(
      await model.save(
        (s) => DistrictSimulation.place(s, const Footprint(0, 0, 2, 4)),
      ),
      isTrue,
    );
    expect(model.game!.buildings.length, 1);
    model.dispose();
    await database.close();
  });

  test('unsupported/corrupt game saves are preserved and cannot become a new wallet', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    for (final bad in [
      {'version': 99, 'balance': 9},
      DistrictGame(watermark: 0).toJson()..['phaseMilliseconds'] = 1000,
    ]) {
      await GameRepository.store.record('1').put(database, bad);
      await expectLater(
        repository.update(profile(1), 0),
        throwsFormatException,
      );
      expect(await GameRepository.store.record('1').get(database), bad);
    }
    await database.close();
  });
}
