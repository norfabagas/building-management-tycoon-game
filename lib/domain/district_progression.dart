part of 'district_game.dart';

enum Achievement {
  firstBusiness('Open your first business', 1),
  earnedThousand(r'Earn $1,000 in total revenue', 3),
  allTypes('Open all four building types', 5),
  tenFloors('Complete a ten-floor building', 5),
  sevenClosings('Close seven days of books', 2);

  const Achievement(this.label, this.reward);
  final String label;
  final int reward;
}

enum DecorationKind {
  tree('Tree', 2),
  hedge('Hedge', 1),
  planter('Planter', 1),
  bench('Bench', 2),
  streetlamp('Streetlamp', 2),
  tableSet('Table set', 3);

  const DecorationKind(this.label, this.price);
  final String label;
  final int price;
}

class DistrictDecoration {
  DistrictDecoration(this.kind, this.cell);
  final DecorationKind kind;
  LandCell cell;
  Map<String, Object> toJson() => {'kind': kind.name, 'x': cell.x, 'y': cell.y};
  factory DistrictDecoration.fromJson(Map<String, dynamic> json) =>
      DistrictDecoration(
        DecorationKind.values.byName(json['kind'] as String),
        LandCell(json['x'] as int, json['y'] as int),
      );
}

abstract final class DistrictProgression {
  static int progress(DistrictGame state, Achievement achievement) =>
      switch (achievement) {
        Achievement.firstBusiness =>
          state.buildings
                  .where((b) => b.stage == ConstructionStage.ready)
                  .isEmpty
              ? 0
              : 1,
        Achievement.earnedThousand => state.earned.clamp(0, 100000),
        Achievement.allTypes =>
          state.buildings
              .where((b) => b.stage == ConstructionStage.ready)
              .map((b) => b.type)
              .toSet()
              .length,
        Achievement.tenFloors => state.buildings.fold(
          0,
          (n, b) => math.max(n, b.completedFloors),
        ),
        Achievement.sevenClosings => state.lastClosing.clamp(0, 7),
      };
  static int target(Achievement achievement) => switch (achievement) {
    Achievement.firstBusiness => 1,
    Achievement.earnedThousand => 100000,
    Achievement.allTypes => 4,
    Achievement.tenFloors => 10,
    Achievement.sevenClosings => 7,
  };
  static void evaluate(DistrictGame state) {
    if (state.catalogVersion < 2) return;
    for (final achievement in Achievement.values) {
      if (progress(state, achievement) >= target(achievement) &&
          state.achievements.add(achievement)) {
        state.gems += achievement.reward;
      }
    }
  }

  static String? decorationError(
    DistrictGame state,
    LandCell cell, {
    DistrictDecoration? ignore,
  }) {
    if (state.roadNetwork.contains(cell) ||
        state.roads.contains(cell) ||
        state.buildings.any((b) => b.footprint.contains(cell))) {
      return 'Choose free land outside buildings and roads.';
    }
    if (state.decorations.any((d) => !identical(d, ignore) && d.cell == cell)) {
      return 'A decoration already occupies this tile.';
    }
    return null;
  }

  static void placeDecoration(
    DistrictGame state,
    DecorationKind kind,
    LandCell cell,
  ) {
    final error = decorationError(state, cell);
    if (error != null) throw GameplayException(error);
    if (state.gems < kind.price) {
      throw const GameplayException(
        'Not enough gems. Complete achievements to earn more.',
      );
    }
    state.gems -= kind.price;
    state.decorations.add(DistrictDecoration(kind, cell));
  }

  static void moveDecoration(DistrictGame state, int index, LandCell cell) {
    if (index < 0 || index >= state.decorations.length) {
      throw const GameplayException('This decoration is no longer available.');
    }
    final decoration = state.decorations[index];
    final error = decorationError(state, cell, ignore: decoration);
    if (error != null) throw GameplayException(error);
    decoration.cell = cell;
  }

  static int? accelerationCost(DistrictGame state, ApartmentBuilding building) {
    final upgrade = building.upgrade;
    if (upgrade?.stage == UpgradeStage.building && !upgrade!.rushed) {
      final remaining =
          upgrade.kind.duration(building) * 4 -
          ((state.day - upgrade.startedDay) * 4 + state.phaseIndex) -
          state.remainder / state.phaseMilliseconds;
      return math.max(1, (remaining / 4).ceil());
    }
    if (!building.rushed &&
        (building.stage == ConstructionStage.shell ||
            building.stage == ConstructionStage.basement)) {
      final duration = building.stage == ConstructionStage.shell
          ? building.initialShellDays
          : 1;
      final remaining =
          duration * 4 -
          ((state.day - building.startedDay) * 4 + state.phaseIndex) -
          state.remainder / state.phaseMilliseconds;
      return math.max(1, (remaining / 4).ceil());
    }
    return null;
  }

  /// Identifies the reviewed work across repository snapshot replacements.
  /// Type/stage plus start day also distinguishes repeated upgrades.
  static String? accelerationJob(ApartmentBuilding building) {
    final upgrade = building.upgrade;
    if (upgrade?.stage == UpgradeStage.building && !upgrade!.rushed) {
      return '${building.id}:upgrade:${upgrade.kind.name}:${upgrade.startedDay}';
    }
    if (!building.rushed &&
        (building.stage == ConstructionStage.shell ||
            building.stage == ConstructionStage.basement)) {
      return '${building.id}:construction:${building.stage.name}:${building.startedDay}';
    }
    return null;
  }

  static void accelerate(
    DistrictGame state,
    int id, {
    required int quotedCost,
    required String quotedJob,
  }) {
    final building = DistrictSimulation._find(state, id);
    final cost = accelerationCost(state, building);
    if (cost == null) {
      throw const GameplayException(
        'Only an active construction job can be accelerated.',
      );
    }
    if (quotedCost != cost || quotedJob != accelerationJob(building)) {
      throw const GameplayException(
        'The job changed. Review acceleration again.',
      );
    }
    if (state.gems < cost) throw const GameplayException('Not enough gems.');
    state.gems -= cost;
    if (building.upgrade != null) {
      building.upgrade!.rushed = true;
      building.upgrade!.rushGems = cost;
    } else {
      building.rushed = true;
      building.rushGems = cost;
    }
  }
}
