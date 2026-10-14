import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/game_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void at(DistrictGame state, int day, [GamePhase phase = GamePhase.morning]) =>
    DistrictSimulation.advance(
      state,
      ((day - 1) * 5 + phase.index) * StarterCatalog.phaseMilliseconds,
    );

DistrictGame matureApartment() => DistrictGame(
  watermark: 0,
  nextBuildingId: 2,
  buildings: [
    ApartmentBuilding(
      id: 1,
      footprint: const Footprint(0, 0, 2, 4),
      stage: ConstructionStage.ready,
      occupied: {0, 1, 2, 3, 4, 5},
    ),
  ],
);

void main() {
  test('confirm reserves complete quote and roads; payment only at Noon', () {
    final state = DistrictGame(watermark: 0);
    DistrictSimulation.place(state, const Footprint(0, 0, 2, 4));
    expect(state.balance, 4000000);
    expect(state.reserved, 2000000);
    expect(state.available, 2000000);
    expect(state.roads.length, 16);
    expect(
      state.roads.intersection(state.buildings.single.footprint.cells.toSet()),
      isEmpty,
    );
    at(state, 1, GamePhase.night);
    expect(state.balance, 4000000);
    at(state, 1, GamePhase.noon);
    expect(state.balance, 2000000);
    expect(state.reserved, 0);
    expect(state.statement!.purchases, 2000000);
    expect(state.buildings.single.stage, ConstructionStage.paid);
    at(state, 1, GamePhase.noon);
    expect(state.balance, 2000000);
  });

  test('shell lasts two days, then B1 one; opening is manual before Morning admissions', () {
    final state = DistrictGame(watermark: 0);
    DistrictSimulation.place(state, const Footprint(0, 0, 2, 4));
    at(state, 2);
    final building = state.buildings.single;
    expect(building.stage, ConstructionStage.shell);
    at(state, 2, GamePhase.noon);
    expect(building.stage, ConstructionStage.shell);
    expect(building.occupied, isEmpty);
    at(state, 3, GamePhase.noon);
    expect(building.stage, ConstructionStage.shellDone);
    expect(building.valuation, 1600000);
    expect(state.statement!.maintenance, 4000);
    expect(state.statement!.tax, 800);
    at(state, 4);
    expect(building.stage, ConstructionStage.basement);
    at(state, 4, GamePhase.noon);
    expect(building.stage, ConstructionStage.parkingDone);
    expect(building.occupied, isEmpty);
    at(state, 5);
    expect(building.stage, ConstructionStage.parkingDone);
    expect(building.occupied, isEmpty);
    DistrictSimulation.openBusiness(state, building.id);
    expect(building.stage, ConstructionStage.ready);
    expect(building.occupied, isEmpty);
    at(state, 6);
    expect(building.occupied.length, 2);
    at(state, 7);
    expect(building.occupied.length, 4);
    at(state, 8);
    expect(building.occupied.length, 6);
  });

  test('construction progress follows both jobs and stays at 100 while awaiting opening', () {
    final state = DistrictGame(watermark: 0);
    DistrictSimulation.place(state, const Footprint(0, 0, 2, 4));
    final building = state.buildings.single;
    expect(DistrictSimulation.constructionProgress(state, building), 0);
    at(state, 2);
    expect(DistrictSimulation.constructionProgress(state, building), 0);
    final moving = DistrictSimulation.constructionProgress(
      state,
      building,
      elapsedMilliseconds: 2500,
    );
    expect(moving, closeTo(.5 / 9 * 2 / 3, .00001));
    at(state, 3, GamePhase.noon);
    expect(
      DistrictSimulation.constructionProgress(state, building),
      closeTo(2 / 3, .00001),
    );
    at(state, 4);
    expect(
      DistrictSimulation.constructionProgress(state, building),
      closeTo(2 / 3, .00001),
    );
    at(state, 4, GamePhase.afternoon);
    expect(
      DistrictSimulation.constructionProgress(state, building),
      closeTo(5 / 6, .00001),
    );
    expect(
      DistrictSimulation.constructionProgress(
        state,
        building,
        elapsedMilliseconds: 60000,
      ),
      lessThan(1),
    );
    at(state, 4, GamePhase.noon);
    expect(DistrictSimulation.constructionProgress(state, building), 1);
    at(state, 20);
    expect(building.stage, ConstructionStage.parkingDone);
    expect(building.occupied, isEmpty);
    expect(state.pendingRent, 0);
    expect(state.earned, 0);
    expect(DistrictSimulation.constructionProgress(state, building), 1);
  });

  test('opening rejects incomplete construction and is idempotent after completion', () {
    final state = DistrictGame(watermark: 0);
    DistrictSimulation.place(state, const Footprint(0, 0, 2, 4));
    final before = state.toJson();
    expect(
      () => DistrictSimulation.openBusiness(state, 1),
      throwsA(isA<GameplayException>()),
    );
    expect(state.toJson(), before);
    at(state, 4, GamePhase.noon);
    final balance = state.balance;
    DistrictSimulation.openBusiness(state, 1);
    expect(state.balance, balance);
    expect(state.buildings.single.occupied, isEmpty);
    final opened = state.toJson();
    DistrictSimulation.openBusiness(state, 1);
    expect(state.toJson(), opened);
    at(state, 5);
    expect(state.buildings.single.occupied.length, 2);
    at(state, 5, GamePhase.noon);
    expect(state.statement!.parking, 2000);
    expect(state.pendingRent, 24000);
  });

  test(
    'daily parking and costs, rent collected Sunday including Sunday accrual',
    () {
      final state = matureApartment();
      final starting = state.balance;
      at(state, 1, GamePhase.noon);
      expect(state.statement!.rent, 0);
      expect(state.statement!.parking, 6000);
      expect(state.statement!.tax, 1120);
      expect(state.balance - starting, -3120);
      expect(state.pendingRent, 72000);
      at(state, 7, GamePhase.noon);
      expect(state.statement!.rent, 504000);
      expect(state.statement!.tax, 11200);
      expect(state.statement!.net, 490800);
      expect(state.balance - starting, 472080);
      expect(state.pendingRent, 0);
      expect(
        state.earned,
        546000,
      ); // Rent earning is counted once, not again on receipt.
      expect(state.nextSunday, 14);
    },
  );

  test(
    'departing tenants retain ledger; partial week uses actual occupied days',
    () {
      final state = matureApartment();
      at(state, 5, GamePhase.noon);
      final pending = state.pendingRent;
      for (var room = 0; room < 6; room++) {
        DistrictSimulation.vacate(state, 1, room);
      }
      expect(state.pendingRent, pending);
      at(state, 7, GamePhase.noon);
      // Saturday admits two; Sunday admits another two. Friday earnings survive departure.
      expect(state.statement!.rent, 432000);
      expect(state.pendingRent, 0);
    },
  );

  test('offline multiple weeks equals phase-by-phase play; repeat/backward clock pays nothing twice', () {
    final offline = matureApartment();
    final online = matureApartment();
    at(offline, 22, GamePhase.afternoon);
    for (var phase = 1; phase <= 107; phase++) {
      DistrictSimulation.advance(
        online,
        phase * StarterCatalog.phaseMilliseconds,
      );
    }
    expect(offline.toJson(), online.toJson());
    final snapshot = offline.toJson();
    DistrictSimulation.advance(offline, offline.watermark);
    DistrictSimulation.advance(offline, 0);
    expect(offline.toJson(), snapshot);
    expect(DistrictGame.fromJson(snapshot).toJson(), snapshot);
  });

  test('overlap and insufficient funds leave sites and roads unchanged; shared roads merge', () {
    final state = DistrictGame(watermark: 0);
    DistrictSimulation.place(state, const Footprint(0, 0, 2, 4));
    final before = state.toJson();
    expect(
      () => DistrictSimulation.place(state, const Footprint(1, 0, 2, 2)),
      throwsA(isA<GameplayException>()),
    );
    expect(
      () => DistrictSimulation.place(state, const Footprint(2, 0, 2, 2)),
      throwsA(isA<GameplayException>()),
    );
    expect(
      () => DistrictSimulation.place(state, const Footprint(50, 0, 10, 10)),
      throwsA(isA<GameplayException>()),
    );
    expect(state.toJson(), before);
    DistrictSimulation.place(state, const Footprint(3, 0, 2, 2));
    expect(state.roads.length, 24); // 16 + 12 minus 4 compatible shared tiles.
    DistrictSimulation.cancel(state, 1);
    expect(state.roads.length, 12);
    expect(state.reserved, 1000000);
    at(state, 1, GamePhase.noon);
    expect(
      () => DistrictSimulation.cancel(state, 2),
      throwsA(isA<GameplayException>()),
    );
  });

  test('losses remain negative, pending rent cannot finance purchases', () {
    final state = matureApartment()..balance = 0;
    at(state, 1, GamePhase.noon);
    expect(state.balance, -3120);
    expect(state.available, 0);
    expect(state.pendingRent, greaterThan(0));
    expect(
      () => DistrictSimulation.place(state, const Footprint(10, 0, 1, 2)),
      throwsA(isA<GameplayException>()),
    );
  });
}
