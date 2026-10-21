import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DistrictGame fresh() => DistrictGame(watermark: 0, balance: 100000000);
  test('first plot must reach the highway; rejection is free and atomic', () {
    final game = fresh();
    expect(game.roadNetwork.isMain(const LandCell(100000, -3)), isTrue);
    expect(game.roadNetwork.isMain(const LandCell(-100000, -2)), isTrue);
    final before = game.toJson();
    expect(
      () => DistrictSimulation.place(game, const Footprint(0, 3, 2, 2)),
      throwsA(isA<GameplayException>()),
    );
    expect(game.toJson(), before);
    DistrictSimulation.place(game, const Footprint(0, 0, 2, 2));
    expect(game.buildings, hasLength(1));
    expect(
      game.roadNetwork.serves(game.buildings.single.footprint, game.buildings),
      isTrue,
    );
  });
  test('connected neighbourhood can extend away from the main road', () {
    final game = fresh();
    DistrictSimulation.place(game, const Footprint(0, 0, 2, 2));
    // These rings meet only diagonally at (2,2)/(3,3).
    expect(
      DistrictSimulation.placementError(game, const Footprint(4, 4, 2, 2)),
      contains('Connect'),
    );
    DistrictSimulation.place(game, const Footprint(0, 4, 2, 2));
    DistrictSimulation.place(game, const Footprint(0, 8, 2, 2));
    expect(game.buildings, hasLength(3));
    expect(
      DistrictSimulation.placementError(game, const Footprint(0, 13, 2, 2)),
      contains('Connect'),
    );
  });
  test('isolated public streets are not accepted as access', () {
    final game = DistrictGame(
      watermark: 0,
      roadNetwork: DistrictRoadNetwork(
        streets: [const RoadSegment(9, 9, 20, 9)],
      ),
    );
    expect(
      DistrictSimulation.placementError(game, const Footprint(10, 11, 2, 2)),
      contains('Connect'),
    );
  });
  test(
    'highway and public access cannot be covered by a plot or decoration',
    () {
      final game = fresh();
      expect(
        DistrictSimulation.placementError(game, const Footprint(0, -3, 2, 2)),
        contains('overlaps a road'),
      );
      expect(
        DistrictProgression.decorationError(game, const LandCell(50, -2)),
        isNotNull,
      );
      game.roadNetwork.streets.add(const RoadSegment(10, -1, 10, 8));
      expect(
        DistrictSimulation.placementError(game, const Footprint(10, 3, 2, 2)),
        contains('overlaps a road'),
      );
      expect(
        DistrictProgression.decorationError(game, const LandCell(10, 5)),
        isNotNull,
      );
    },
  );
  test('canceling a bridge retains free public streets and full refund', () {
    final game = fresh();
    DistrictSimulation.place(game, const Footprint(0, 0, 2, 2));
    DistrictSimulation.place(game, const Footprint(0, 4, 2, 2));
    DistrictSimulation.place(game, const Footprint(0, 8, 2, 2));
    final before = game.balance;
    final quote = game.buildings.first.originalQuote;
    DistrictSimulation.cancel(game, 1);
    expect(game.balance, before + quote);
    expect(game.roadNetwork.streets, hasLength(4));
    expect(
      game.roadNetwork.serves(game.buildings.last.footprint, game.buildings),
      isTrue,
    );
    // Repeated bridge removal must retain the next connecting ring too.
    DistrictSimulation.cancel(game, 2);
    expect(game.roadNetwork.streets, hasLength(8));
    final restored = DistrictGame.fromJson(game.toJson());
    expect(restored.toJson(), game.toJson());
    expect(
      restored.roadNetwork.serves(
        restored.buildings.single.footprint,
        restored.buildings,
      ),
      isTrue,
    );
  });
  test('canceling a dead end removes its unshared ring', () {
    final game = fresh();
    DistrictSimulation.place(game, const Footprint(0, 0, 2, 2));
    DistrictSimulation.cancel(game, 1);
    expect(game.roads, isEmpty);
    expect(game.roadNetwork.streets, isEmpty);
    expect(game.balance, 100000000);
  });
  test('legacy district gets compact links around all existing plots', () {
    final buildings = [
      for (var i = 0; i < 4; i++)
        ApartmentBuilding(
          id: i + 1,
          type: BuildingType.values[i],
          footprint: Footprint(i * 5, i * 4, 2, 2),
        ),
      ApartmentBuilding(
        id: 5,
        footprint: const Footprint(1000000, 1000000, 2, 2),
      ),
    ];
    final seed = DistrictGame(
      watermark: 0,
      nextBuildingId: 6,
      buildings: buildings,
    );
    final legacy = seed.toJson()..['version'] = 7;
    legacy.remove('roadNetwork');
    final game = DistrictGame.fromJson(legacy);
    expect(game.toJson()['version'], 9);
    expect(game.balance, seed.balance);
    expect(
      game.buildings.map((b) => b.toJson()),
      seed.buildings.map((b) => b.toJson()),
    );
    expect(game.roadNetwork.streets.length, lessThan(100));
    for (final building in game.buildings) {
      expect(
        game.roadNetwork.serves(building.footprint, game.buildings),
        isTrue,
      );
      expect(game.roadNetwork.blocks(building.footprint), isFalse);
    }
    final restored = DistrictGame.fromJson(game.toJson());
    expect(restored.roadNetwork.mainRow, game.roadNetwork.mainRow);
    expect(restored.toJson(), game.toJson());
  });
  test('legacy routing avoids decorations as well as footprints', () {
    final game = DistrictGame(
      watermark: 0,
      nextBuildingId: 3,
      buildings: [
        ApartmentBuilding(id: 1, footprint: const Footprint(0, 0, 2, 2)),
        ApartmentBuilding(id: 2, footprint: const Footprint(0, 7, 2, 2)),
      ],
    );
    // A decoration blocking the direct northbound access path.
    final json = game.toJson()..['version'] = 7;
    // Use the domain serializer to keep the decoration schema authoritative.
    json['decorations'] = [
      DistrictDecoration(DecorationKind.tree, const LandCell(-1, 4)).toJson(),
    ];
    final migrated = DistrictGame.fromJson(json);
    expect(migrated.roadNetwork.contains(const LandCell(-1, 4)), isFalse);
    expect(
      migrated.roadNetwork.serves(
        migrated.buildings.last.footprint,
        migrated.buildings,
      ),
      isTrue,
    );
  });
  test('corrupt persisted road geometry is rejected', () {
    final json = fresh().toJson();
    json['roadNetwork'] = {
      'mainRow': -3,
      'streets': [
        [0, 0, 2, 2],
      ],
    };
    expect(() => DistrictGame.fromJson(json), throwsFormatException);
    final game = fresh();
    DistrictSimulation.place(game, const Footprint(0, 0, 2, 2));
    final blocked = game.toJson();
    blocked['roadNetwork'] = {'mainRow': 0, 'streets': []};
    expect(() => DistrictGame.fromJson(blocked), throwsFormatException);
  });
}
