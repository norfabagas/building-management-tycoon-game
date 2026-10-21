import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void tick(DistrictGame state, int phases) => DistrictSimulation.advance(
  state,
  (phases ~/ 5) * 24000 + (phases % 5) * 6000,
);

final profile = LocalProfile(
  slot: 1,
  areaName: 'Money',
  createdAt: DateTime(2026),
);

void main() {
  test('schema 4 already-paid and active upgrades refund their existing payment without another debit', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    for (final stage in [UpgradeStage.paid, UpgradeStage.building]) {
      final source =
          DistrictGame(
              watermark: 0,
              balance: 3500000,
              nextBuildingId: 2,
              buildings: [
                ApartmentBuilding(
                  id: 1,
                  footprint: const Footprint(0, 0, 2, 4),
                  stage: ConstructionStage.ready,
                  upgrade: UpgradeOrder(
                    kind: BuildingUpgrade.standardLift,
                    stage: stage,
                    startedDay: stage == UpgradeStage.building ? 1 : 0,
                  ),
                ),
              ],
            ).toJson()
            ..['catalog'] = 1
            ..['version'] = 4
            ..['phaseMilliseconds'] = 5000;
      await GameRepository.store.record('1').put(database, source);
      final migrated = await repository.update(profile, 0);
      expect(migrated.balance, 3500000);
      final canceled = await repository.update(
        profile,
        0,
        (s) => DistrictSimulation.cancelUpgrade(s, 1),
      );
      expect(canceled.balance, 4000000);
      expect((await repository.update(profile, 0)).balance, 4000000);
    }
    await database.close();
  });

  test('every pre-opening building stage refunds once, preserves incurred costs and removes roads', () {
    for (final phases in [0, 4, 5, 14, 15, 19]) {
      final state = DistrictGame(watermark: 0);
      DistrictSimulation.place(state, const Footprint(0, 0, 2, 4));
      expect(state.balance, 2000000);
      tick(state, phases);
      final before = state.balance;
      final earned = state.earned;
      DistrictSimulation.cancel(state, 1);
      expect(state.balance, before + 2000000);
      expect(state.earned, earned);
      expect(state.roads, isEmpty);
      expect(state.buildings, isEmpty);
      final refunded = state.toJson();
      expect(
        () => DistrictSimulation.cancel(state, 1),
        throwsA(isA<GameplayException>()),
      );
      expect(state.toJson(), refunded);
      tick(state, phases + 10);
      expect(state.balance, before + 2000000);
    }
  });

  test('open businesses cannot be canceled or refunded', () {
    final state = DistrictGame(watermark: 0);
    DistrictSimulation.place(state, const Footprint(0, 0, 2, 2));
    tick(state, 19);
    DistrictSimulation.openBusiness(state, 1);
    final before = state.toJson();
    expect(
      () => DistrictSimulation.cancel(state, 1),
      throwsA(isA<GameplayException>()),
    );
    expect(state.toJson(), before);
  });

  test('upgrade refunds at queue, waiting and in-progress stages never add capacity or erase tenants', () {
    for (final kind in BuildingUpgrade.values) {
      for (final phases in [0, 4, 5, 6]) {
        final state = DistrictGame(
          watermark: 0,
          nextBuildingId: 2,
          buildings: [
            ApartmentBuilding(
              id: 1,
              footprint: const Footprint(0, 0, 2, 4),
              stage: ConstructionStage.ready,
              occupied: {0},
              pendingRent: 12345,
            ),
          ],
        );
        final building = state.buildings.single;
        final price = kind.cost(building);
        DistrictSimulation.orderUpgrade(state, 1, kind);
        expect(state.balance, 4000000 - price);
        tick(state, phases);
        final before = state.balance;
        final occupied = Set<int>.from(building.occupied);
        final pending = state.pendingRent;
        DistrictSimulation.cancelUpgrade(state, 1);
        expect(state.balance, before + price);
        expect(building.occupied, occupied);
        expect(state.pendingRent, pending);
        expect(building.upgrade, isNull);
        final refunded = state.toJson();
        expect(
          () => DistrictSimulation.cancelUpgrade(state, 1),
          throwsA(isA<GameplayException>()),
        );
        expect(state.toJson(), refunded);
        tick(state, 25);
        expect(
          kind.count(building),
          kind == BuildingUpgrade.floor ||
                  kind == BuildingUpgrade.basement ||
                  kind == BuildingUpgrade.luxury
              ? 1
              : 0,
        );
      }
    }
  });

  test('purchase and refund history never change the balance again or become taxable income', () {
    final state = DistrictGame(watermark: 0);
    DistrictSimulation.place(state, const Footprint(0, 0, 2, 4));
    tick(state, 4);
    expect(state.balance, 2000000);
    expect(state.statement!.purchases, 2000000);
    expect(state.statement!.refunds, 0);
    DistrictSimulation.cancel(state, 1);
    expect(state.balance, 4000000);
    tick(state, 9);
    expect(state.balance, 4000000);
    expect(state.statement!.purchases, 0);
    expect(state.statement!.refunds, 2000000);
    expect(state.statement!.gross, 0);
    expect(state.statement!.tax, 0);
    expect(state.earned, 0);
    tick(state, 14);
    expect(state.statement!.refunds, 0);
    expect(state.balance, 4000000);
  });

  test('schema 1 through 4 queued buildings debit once; paid buildings never debit again', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    for (final version in [1, 2, 3, 4]) {
      for (final stage in [
        ConstructionStage.reserved,
        ConstructionStage.paid,
        ConstructionStage.shell,
      ]) {
        final old =
            DistrictGame(
                watermark: 0,
                nextBuildingId: 2,
                buildings: [
                  ApartmentBuilding(
                    id: 1,
                    footprint: const Footprint(0, 0, 2, 2),
                    stage: stage,
                    startedDay: stage == ConstructionStage.shell ? 1 : 0,
                  ),
                ],
              ).toJson()
              ..['catalog'] = 1
              ..['version'] = version
              ..['phaseMilliseconds'] = 5000;
        old.remove('purchasesSinceClosing');
        old.remove('refundsSinceClosing');
        await GameRepository.store.record('1').put(database, old);
        final migrated = await repository.update(profile, 0);
        final expected = stage == ConstructionStage.reserved
            ? 3000000
            : 4000000;
        expect(migrated.balance, expected);
        expect(migrated.toJson()['version'], 9);
        expect(
          (await repository.update(profile, 0)).toJson(),
          migrated.toJson(),
        );
        final closing = await repository.update(profile, 20000);
        expect(closing.balance, expected);
        expect((await repository.update(profile, 20000)).balance, expected);
      }
    }
    await database.close();
  });

  test('schema 4 queued upgrade migration and refund rollback preserve original data', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    final old =
        DistrictGame(
            watermark: 0,
            nextBuildingId: 2,
            buildings: [
              ApartmentBuilding(
                id: 1,
                footprint: const Footprint(0, 0, 2, 4),
                stage: ConstructionStage.ready,
                occupied: {0},
                pendingRent: 12345,
                upgrade: UpgradeOrder(kind: BuildingUpgrade.standardLift),
              ),
            ],
          ).toJson()
          ..['catalog'] = 1
          ..['version'] = 4
          ..['phaseMilliseconds'] = 5000;
    old.remove('purchasesSinceClosing');
    old.remove('refundsSinceClosing');
    await GameRepository.store.record('1').put(database, old);
    await expectLater(
      repository.update(profile, 0, (s) {
        DistrictSimulation.cancelUpgrade(s, 1);
        throw StateError('write failed');
      }),
      throwsStateError,
    );
    expect(await GameRepository.store.record('1').get(database), old);
    final migrated = await repository.update(profile, 0);
    expect(migrated.balance, 3500000);
    expect(migrated.pendingRent, 12345);
    final refunded = await repository.update(
      profile,
      0,
      (s) => DistrictSimulation.cancelUpgrade(s, 1),
    );
    expect(refunded.balance, 4000000);
    expect(refunded.buildings.single.occupied, {0});
    expect((await repository.update(profile, 0)).toJson(), refunded.toJson());
    await database.close();
  });
}
