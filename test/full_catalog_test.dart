import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

ApartmentBuilding business(
  BuildingType type, {
  int floors = 1,
  int basements = 1,
  Set<int>? occupied,
}) => ApartmentBuilding(
  id: 1,
  footprint: const Footprint(0, 0, 2, 2),
  type: type,
  stage: ConstructionStage.ready,
  aboveGroundFloors: floors,
  undergroundFloors: basements,
  occupied: occupied,
);
DistrictGame district(ApartmentBuilding building) =>
    DistrictGame(watermark: 0, nextBuildingId: 2, buildings: [building]);

void main() {
  test('catch-up synergy follows layout changes and long replay preserves every ledger', () {
    final state = DistrictGame(
      watermark: 0,
      nextBuildingId: 3,
      buildings: [
        ApartmentBuilding(
          id: 1,
          footprint: const Footprint(0, 0, 2, 2),
          stage: ConstructionStage.ready,
        ),
        ApartmentBuilding(
          id: 2,
          footprint: const Footprint(3, 0, 2, 2),
          type: BuildingType.foodCourt,
          stage: ConstructionStage.ready,
        ),
      ],
    );
    final stepped = DistrictGame.fromJson(state.toJson());
    const days = 365;
    DistrictSimulation.advance(state, days * 24000);
    for (var i = 1; i <= days * 4; i++) {
      DistrictSimulation.advance(stepped, i * 6000);
    }
    expect(state.toJson(), stepped.toJson());
    expect(DistrictSimulation.synergyPercent(state, state.buildings.first), 5);
    DistrictSimulation.place(
      state,
      const Footprint(0, 3, 2, 2),
      type: BuildingType.foodCourt,
    );
    expect(DistrictSimulation.synergyPercent(state, state.buildings.first), 10);
    final before = DistrictGame.fromJson(state.toJson());
    DistrictSimulation.advance(state, (days + 1) * 24000);
    for (var i = days * 4 + 1; i <= (days + 1) * 4; i++) {
      DistrictSimulation.advance(before, i * 6000);
    }
    expect(state.toJson(), before.toJson());
    DistrictSimulation.cancel(state, 3);
    expect(DistrictSimulation.synergyPercent(state, state.buildings.first), 5);
  });
  test('next closing estimate includes remaining food windows without changing save state', () {
    final food = business(BuildingType.foodCourt);
    final state = district(food);
    DistrictSimulation.advance(state, 30000);
    final before = state.toJson();
    final projected = DistrictSimulation.projectClosing(state);
    expect(state.toJson(), before);
    DistrictSimulation.advance(state, 48000);
    expect(state.statement!.toJson(), projected.toJson());
  });
  test(
    'four types quote and refund the complete immutable multi-floor purchase',
    () {
      const quotes = [1800000, 2280000, 2760000, 1640000];
      for (var i = 0; i < 4; i++) {
        final state = DistrictGame(watermark: 0);
        DistrictSimulation.place(
          state,
          const Footprint(0, 0, 2, 2),
          type: BuildingType.values[i],
          floors: 2,
        );
        expect(state.balance, 4000000 - quotes[i]);
        expect(state.buildings.single.originalQuote, quotes[i]);
        final restored = DistrictGame.fromJson(state.toJson());
        expect(restored.buildings.single.type, BuildingType.values[i]);
        expect(restored.buildings.single.initialFloors, 2);
        DistrictSimulation.cancel(restored, 1);
        expect(restored.balance, 4000000);
        expect(restored.roads, isEmpty);
        expect(
          () => DistrictSimulation.cancel(restored, 1),
          throwsA(isA<GameplayException>()),
        );
      }
    },
  );
  test('two-floor office takes six shell days and a separate B1 day, then manual opening', () {
    final state = DistrictGame(watermark: 0);
    DistrictSimulation.place(
      state,
      const Footprint(0, 0, 2, 2),
      type: BuildingType.office,
      floors: 2,
    );
    final building = state.buildings.single;
    DistrictSimulation.advance(state, 6 * 24000);
    expect(building.stage, ConstructionStage.shell);
    DistrictSimulation.advance(state, 7 * 24000);
    expect(building.stage, ConstructionStage.basement);
    expect(building.completedFloors, 2);
    DistrictSimulation.advance(state, 8 * 24000);
    expect(building.stage, ConstructionStage.parkingDone);
    expect(building.occupied, isEmpty);
    DistrictSimulation.openBusiness(state, 1);
    expect(building.occupied, isEmpty);
    DistrictSimulation.advance(state, 9 * 24000);
    expect(building.occupied, {0});
    expect(building.usedBays, 6);
  });
  test(
    'hotel refreshes daily guest demand and settles daily room income once',
    () {
      final building = business(BuildingType.hotel);
      final state = district(building);
      DistrictSimulation.advance(state, 24000);
      expect(building.occupied.length, 3);
      final before = state.balance;
      DistrictSimulation.advance(state, 48000);
      expect(state.statement!.hotel, 48000);
      expect(state.statement!.parking, 3000);
      expect(state.statement!.maintenance, 9500);
      expect(state.statement!.tax, 1640);
      expect(state.balance - before, 39860);
      expect(state.pendingRent, 0);
      DistrictSimulation.vacate(state, 1, 0);
      expect(building.occupied.length, 2);
      DistrictSimulation.advance(state, 72000);
      expect(building.occupied.length, 3);
      final once = state.toJson();
      DistrictSimulation.advance(state, 72000);
      expect(state.toJson(), once);
    },
  );
  test(
    'office leases are whole floors and each reserves six bays on four tiles',
    () {
      final building = business(BuildingType.office, floors: 2);
      final state = district(building);
      DistrictSimulation.advance(state, 24000);
      expect(building.occupied, {0});
      expect(building.eligibleCapacity, 1);
      expect(building.usedBays, 6);
      DistrictSimulation.advance(state, 48000);
      expect(state.statement!.office, 72000);
      expect(state.statement!.parking, 6000);
      expect(state.statement!.maintenance, 20000);
      expect(state.statement!.tax, 2940);
      expect(building.occupied, {0});
      DistrictSimulation.vacate(state, 1, 0);
      expect(building.usedBays, 0);
      building.undergroundFloors = 2;
      DistrictSimulation.advance(state, 96000);
      expect(building.occupied, {0, 1});
      expect(building.usedBays, 12);
    },
  );
  test('food visitors turn over without exceeding concurrent bays; totals close at midnight', () {
    final building = ApartmentBuilding(
      id: 1,
      footprint: const Footprint(0, 0, 1, 2),
      type: BuildingType.foodCourt,
      stage: ConstructionStage.ready,
    );
    final state = district(building);
    DistrictSimulation.advance(state, 24000);
    expect(building.currentVisitors, 1);
    for (final time in [30000, 36000, 42000]) {
      DistrictSimulation.advance(state, time);
      expect(building.currentVisitors, lessThanOrEqualTo(building.bays));
    }
    expect(building.visitsToday, 6);
    expect(building.salesToday, 15000);
    expect(building.parkingToday, 6000);
    DistrictSimulation.advance(state, 48000);
    expect(state.statement!.sales, 15000);
    expect(state.statement!.parking, 6000);
    expect(state.statement!.tax, 650);
    expect(state.statement!.net, 12350);
    expect(
      building.visitsToday,
      1,
    ); // New Morning's first window, no double closing.
    expect(building.salesToday, 2500);
  });
  test('high-rise needs scale only new demand and respect parking', () {
    final building = business(BuildingType.hotel, floors: 10, basements: 3);
    final state = district(building);
    expect(building.happiness, 70);
    DistrictSimulation.advance(state, 24000);
    expect(building.occupied.length, 13); // ceil(24 bays × 75% demand × 70%).
    building.standardLifts = 3;
    building.executiveLifts = 1;
    expect(building.happiness, 100);
    DistrictSimulation.advance(state, 48000);
    expect(building.occupied.length, 18);
  });
  test('synergy caps at 15 percent and luxury affects only new accrual, never parking', () {
    final receiver = ApartmentBuilding(
      id: 1,
      footprint: const Footprint(0, 0, 4, 4),
      stage: ConstructionStage.ready,
      occupied: {0},
      pendingRent: 12000,
      luxury: 2,
    );
    final state = DistrictGame(
      watermark: 0,
      nextBuildingId: 6,
      buildings: [
        receiver,
        for (final (id, x, y) in [(2, -2, 0), (3, 0, -2), (4, 5, 0), (5, 0, 5)])
          ApartmentBuilding(
            id: id,
            footprint: Footprint(x, y, 1, 1),
            type: BuildingType.foodCourt,
          ),
      ],
    );
    expect(DistrictSimulation.synergyPercent(state, receiver), 15);
    DistrictSimulation.advance(state, 24000);
    expect(
      receiver.pendingRent,
      27870,
    ); // Existing 12000 + new 12000 × 1.15 × 1.15.
    expect(state.statement!.parking, 1000);
    expect(receiver.maintenance, 10000);
  });
  test(
    'luxury and type-specific floor upgrades use approved rates and limits',
    () {
      final building = business(BuildingType.office);
      final state = district(building);
      expect(BuildingUpgrade.floor.cost(building), 1280000);
      expect(BuildingUpgrade.floor.duration(building), 3);
      expect(BuildingUpgrade.standardLift.cost(building), 370000);
      expect(BuildingUpgrade.luxury.cost(building), 444000);
      DistrictSimulation.orderUpgrade(state, 1, BuildingUpgrade.luxury);
      DistrictSimulation.advance(state, 48000);
      expect(building.luxury, 2);
      expect(building.valuation, 1924000);
      expect(building.maintenance, 14000);
    },
  );
  test('achievements award once, gem decorations persist, moves are free and collisions reject', () {
    final state = DistrictGame(
      watermark: 0,
      day: 8,
      lastClosing: 7,
      earned: 100000,
      nextBuildingId: 5,
      buildings: [
        for (var i = 0; i < 4; i++)
          ApartmentBuilding(
            id: i + 1,
            footprint: Footprint(i * 5, 0, 2, 2),
            type: BuildingType.values[i],
            stage: ConstructionStage.ready,
            aboveGroundFloors: i == 0 ? 10 : 1,
          ),
      ],
    );
    DistrictProgression.evaluate(state);
    expect(state.gems, 16);
    expect(state.achievements.length, 5);
    DistrictProgression.placeDecoration(
      state,
      DecorationKind.tree,
      const LandCell(30, 30),
    );
    expect(state.gems, 14);
    DistrictProgression.moveDecoration(state, 0, const LandCell(31, 30));
    expect(state.gems, 14);
    final before = state.toJson();
    expect(
      () => DistrictProgression.moveDecoration(state, 0, const LandCell(0, 0)),
      throwsA(isA<GameplayException>()),
    );
    expect(
      () => DistrictProgression.placeDecoration(
        state,
        DecorationKind.hedge,
        const LandCell(-1, 0),
      ),
      throwsA(isA<GameplayException>()),
    );
    expect(state.toJson(), before);
    final restored = DistrictGame.fromJson(state.toJson());
    DistrictProgression.evaluate(restored);
    expect(restored.gems, 14);
    expect(restored.toJson(), before);
    expect(
      DistrictSimulation.placementError(
        restored,
        const Footprint(30, 30, 2, 2),
      ),
      isNotNull,
    );
  });
  test('acceleration completes only the active job next Morning and never auto opens', () {
    final building = ApartmentBuilding(
      id: 1,
      footprint: const Footprint(0, 0, 2, 2),
      stage: ConstructionStage.shell,
      startedDay: 1,
    );
    final state = district(building)..gems = 5;
    expect(DistrictProgression.accelerationCost(state, building), 2);
    DistrictProgression.accelerate(
      state,
      1,
      quotedCost: 2,
      quotedJob: DistrictProgression.accelerationJob(building)!,
    );
    expect(state.gems, 3);
    final restored = DistrictGame.fromJson(state.toJson());
    final savedBuilding = restored.buildings.single;
    DistrictSimulation.advance(restored, 23999);
    expect(savedBuilding.stage, ConstructionStage.shell);
    DistrictSimulation.advance(restored, 24000);
    expect(savedBuilding.stage, ConstructionStage.basement);
    expect(savedBuilding.occupied, isEmpty);
    DistrictProgression.accelerate(
      restored,
      1,
      quotedCost: 1,
      quotedJob: DistrictProgression.accelerationJob(savedBuilding)!,
    );
    DistrictSimulation.advance(restored, 48000);
    expect(savedBuilding.stage, ConstructionStage.parkingDone);
    expect(savedBuilding.occupied, isEmpty);
    expect(restored.gems, 2);
  });
  test('cancel unfinished accelerated work refunds purchase and unperformed acceleration once', () {
    final building = business(BuildingType.apartment);
    final state = district(building)..gems = 5;
    DistrictSimulation.orderUpgrade(state, 1, BuildingUpgrade.floor);
    DistrictSimulation.advance(state, 24000);
    final before = state.gems;
    DistrictProgression.accelerate(
      state,
      1,
      quotedCost: 2,
      quotedJob: DistrictProgression.accelerationJob(building)!,
    );
    final restored = DistrictGame.fromJson(state.toJson());
    DistrictSimulation.cancelUpgrade(restored, 1);
    expect(restored.gems, before);
    expect(restored.buildings.single.aboveGroundFloors, 1);
    expect(
      () => DistrictSimulation.cancelUpgrade(restored, 1),
      throwsA(isA<GameplayException>()),
    );
  });
  test('four-type offline simulation equals every six-hour step through multiple Sundays', () {
    final start = DistrictGame(
      watermark: 0,
      nextBuildingId: 5,
      buildings: [
        for (var i = 0; i < 4; i++)
          ApartmentBuilding(
            id: i + 1,
            footprint: Footprint(i * 5, 0, 2, 2),
            type: BuildingType.values[i],
            stage: ConstructionStage.ready,
          ),
      ],
    );
    final offline = DistrictGame.fromJson(start.toJson());
    final online = DistrictGame.fromJson(start.toJson());
    DistrictSimulation.advance(offline, 29 * 24000 + 3500);
    for (var time = 6000; time <= 29 * 24000; time += 6000) {
      DistrictSimulation.advance(online, time);
    }
    DistrictSimulation.advance(online, 29 * 24000 + 3500);
    expect(offline.toJson(), online.toJson());
    final once = offline.toJson();
    DistrictSimulation.advance(offline, 0);
    expect(offline.toJson(), once);
  });
  test('catalog-1 catch-up retains original admissions and pending rent before migration', () {
    final source = district(
      business(BuildingType.apartment, floors: 10, basements: 3),
    )..catalogVersion = 1;
    source.buildings.single.pendingRent = 12345;
    final legacy = DistrictGame.fromJson(source.toJson());
    DistrictSimulation.advance(legacy, 24000);
    expect(
      legacy.buildings.single.occupied.length,
      6,
    ); // Old demand, not new 70% penalty.
    expect(legacy.pendingRent, 12345);
    expect(legacy.catalogVersion, 2);
    expect(legacy.toJson()['version'], 7);
    DistrictSimulation.advance(legacy, 48000);
    expect(
      legacy.buildings.single.occupied.length,
      11,
    ); // New demand from next Morning.
  });
  test(
    'gems and decorations roll back atomically when a transaction fails',
    () async {
      final db = await openNewInMemoryDatabase();
      addTearDown(db.close);
      final state = DistrictGame(watermark: 0, gems: 2);
      await GameRepository.store.record('1').put(db, state.toJson());
      final repository = GameRepository(open: () async => db);
      final profile = LocalProfile(
        slot: 1,
        areaName: 'Test',
        createdAt: DateTime(2020),
      );
      await expectLater(
        repository.update(profile, 0, (working) {
          DistrictProgression.placeDecoration(
            working,
            DecorationKind.tree,
            const LandCell(20, 20),
          );
          throw StateError('Rollback requested');
        }),
        throwsA(isA<StateError>()),
      );
      expect(await GameRepository.store.record('1').get(db), state.toJson());
      final saved = await repository.update(
        profile,
        0,
        (working) => DistrictProgression.placeDecoration(
          working,
          DecorationKind.tree,
          const LandCell(20, 20),
        ),
      );
      expect(saved.gems, 0);
      expect(saved.decorations.length, 1);
    },
  );
}
