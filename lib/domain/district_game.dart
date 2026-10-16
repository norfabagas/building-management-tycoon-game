import 'dart:math' as math;

import 'game_rules.dart';
import 'building_catalog.dart';

export 'game_rules.dart' show BuildingType;
export 'building_catalog.dart';
part 'district_progression.dart';

/// User-approved apartment catalog; amounts are integer cents.
abstract final class StarterCatalog {
  static const shellPerTile = 200000;
  static const basementPerTile = 50000;
  static const weeklyRent = 84000;
  static const parkingPerTenant = 1000;
  static const maintenancePerFloor = 4000;
  static const maintenancePerBasement = 4000;
  static const hourMilliseconds = 1000;
  static const dayMilliseconds = 24000;
  static const phaseMilliseconds = 6000;
  static const previousPhaseMilliseconds = 5000;
  static const legacyPhaseMilliseconds = 60000;
}

class LandCell {
  const LandCell(this.x, this.y);
  final int x;
  final int y;
  String get key => '$x,$y';
  @override
  bool operator ==(Object other) =>
      other is LandCell && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
}

class Footprint {
  const Footprint(this.x, this.y, this.width, this.length);
  factory Footprint.between(LandCell a, LandCell b) => Footprint(
    math.min(a.x, b.x),
    math.min(a.y, b.y),
    (a.x - b.x).abs() + 1,
    (a.y - b.y).abs() + 1,
  );
  final int x;
  final int y;
  final int width;
  final int length;
  int get tiles => width * length;
  int get rooms => tiles * 3 ~/ 4;
  int get bays => tiles * 2;
  int get shellCost => tiles * StarterCatalog.shellPerTile;
  int get basementCost => tiles * StarterCatalog.basementPerTile;
  int get quote => shellCost + basementCost;
  bool contains(LandCell cell) =>
      cell.x >= x && cell.x < x + width && cell.y >= y && cell.y < y + length;
  Iterable<LandCell> get cells sync* {
    for (var row = y; row < y + length; row++) {
      for (var col = x; col < x + width; col++) {
        yield LandCell(col, row);
      }
    }
  }

  Iterable<LandCell> get roadRing sync* {
    for (var row = y - 1; row <= y + length; row++) {
      for (var col = x - 1; col <= x + width; col++) {
        final cell = LandCell(col, row);
        if (!contains(cell)) yield cell;
      }
    }
  }

  Map<String, Object> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'length': length,
  };
  factory Footprint.fromJson(Map<String, dynamic> json) {
    final result = Footprint(
      json['x'] as int,
      json['y'] as int,
      json['width'] as int,
      json['length'] as int,
    );
    if (result.width < 1 || result.length < 1) {
      throw const FormatException('Invalid starter footprint');
    }
    return result;
  }
}

enum ConstructionStage {
  reserved('Queued'),
  paid('Starts tomorrow'),
  shell('Building apartments'),
  shellDone('Parking queued'),
  basement('Building parking'),
  parkingDone('Ready to open'),
  ready('Open');

  const ConstructionStage(this.label);
  final String label;
}

enum BuildingUpgrade {
  floor('Add floor', GameRules.maximumAboveGroundFloors, 2),
  basement('Add basement', GameRules.maximumUndergroundFloors, 1),
  standardLift('Standard lift', GameRules.maximumStandardLifts, 1),
  executiveLift('Executive lift', GameRules.maximumExecutiveLifts, 1),
  luxury('Luxury', 3, 1);

  const BuildingUpgrade(this.label, this.maximum, this.days);
  final String label;
  final int maximum, days;

  int count(ApartmentBuilding building) => switch (this) {
    floor => building.aboveGroundFloors,
    basement => building.undergroundFloors,
    standardLift => building.standardLifts,
    executiveLift => building.executiveLifts,
    luxury => building.luxury,
  };

  int cost(ApartmentBuilding building) => switch (this) {
    floor => building.footprint.tiles * building.type.shellPerTile,
    basement => building.footprint.basementCost,
    standardLift => building.type.quote(building.footprint.tiles) ~/ 4,
    executiveLift => building.type.quote(building.footprint.tiles) ~/ 2,
    luxury => building.originalQuote * 30 ~/ 100,
  };

  int duration(ApartmentBuilding building) =>
      this == floor ? building.type.shellDays : days;
  int addedMaintenance(ApartmentBuilding building) => switch (this) {
    floor => building.type.floorMaintenance + (building.luxury - 1) * 2000,
    luxury => building.completedFloors * 2000,
    _ => maintenance,
  };

  int get maintenance => switch (this) {
    floor => StarterCatalog.maintenancePerFloor,
    basement => StarterCatalog.maintenancePerBasement,
    standardLift || executiveLift => 4000,
    luxury => 2000,
  };
}

enum UpgradeStage {
  reserved('Queued'),
  paid('Starts tomorrow'),
  building('In progress');

  const UpgradeStage(this.label);
  final String label;
}

class UpgradeOrder {
  UpgradeOrder({
    required this.kind,
    this.stage = UpgradeStage.reserved,
    this.startedDay = 0,
    this.rushed = false,
    this.rushGems = 0,
  });
  final BuildingUpgrade kind;
  UpgradeStage stage;
  int startedDay;
  bool rushed;
  int rushGems;
  Map<String, Object> toJson() => {
    'kind': kind.name,
    'stage': stage.name,
    'startedDay': startedDay,
    'rushed': rushed,
    'rushGems': rushGems,
  };
  factory UpgradeOrder.fromJson(Map<String, dynamic> json) {
    final order = UpgradeOrder(
      kind: BuildingUpgrade.values.byName(json['kind'] as String),
      stage: UpgradeStage.values.byName(json['stage'] as String),
      startedDay: json['startedDay'] as int,
      rushed: json['rushed'] as bool? ?? false,
      rushGems: json['rushGems'] as int? ?? 0,
    );
    if (order.rushGems < 0 ||
        order.rushed != (order.rushGems > 0) ||
        (order.rushed && order.stage != UpgradeStage.building)) {
      throw const FormatException('Invalid acceleration');
    }
    if (order.stage == UpgradeStage.building
        ? order.startedDay < 1
        : order.startedDay != 0) {
      throw const FormatException('Invalid upgrade order');
    }
    return order;
  }
}

class ApartmentBuilding {
  ApartmentBuilding({
    required this.id,
    required this.footprint,
    this.type = BuildingType.apartment,
    this.initialFloors = 1,
    int? originalQuote,
    this.luxury = 1,
    this.visitsToday = 0,
    this.currentVisitors = 0,
    this.visitorCapacity = 0,
    this.salesToday = 0,
    this.parkingToday = 0,
    this.rushed = false,
    this.rushGems = 0,
    this.stage = ConstructionStage.reserved,
    this.startedDay = 0,
    this.pendingRent = 0,
    this.aboveGroundFloors = 1,
    this.undergroundFloors = 1,
    this.standardLifts = 0,
    this.executiveLifts = 0,
    this.upgrade,
    Set<int>? occupied,
  }) : occupied = occupied ?? {},
       originalQuote =
           originalQuote ?? type.quote(footprint.tiles, initialFloors);
  final int id;
  final Footprint footprint;
  final BuildingType type;
  final int initialFloors, originalQuote;
  int luxury,
      visitsToday,
      currentVisitors,
      visitorCapacity,
      salesToday,
      parkingToday;
  bool rushed;
  int rushGems;
  ConstructionStage stage;
  int startedDay;
  int pendingRent;
  int aboveGroundFloors, undergroundFloors, standardLifts, executiveLifts;
  UpgradeOrder? upgrade;
  final Set<int> occupied;
  bool get shellComplete => stage.index >= ConstructionStage.shellDone.index;
  bool get parkingComplete =>
      stage.index >= ConstructionStage.parkingDone.index;
  int get completedFloors => shellComplete ? aboveGroundFloors : 0;
  int get completedBasements => parkingComplete ? undergroundFloors : 0;
  int get unitsPerFloor => type.unitsPerFloor(footprint.tiles);
  int get rooms => completedFloors * unitsPerFloor;
  int get bays => completedBasements * footprint.bays;
  int get usedBays => type == BuildingType.foodCourt
      ? currentVisitors
      : occupied.length * type.baysPerUnit(footprint.tiles);
  int get eligibleCapacity =>
      math.min(rooms, bays ~/ type.baysPerUnit(footprint.tiles));
  int get happiness =>
      100 -
      (math.max(0, completedFloors - 2) * 5 -
              (standardLifts + executiveLifts) * 10)
          .clamp(0, 30);
  int get initialShellDays => type.shellDays * initialFloors;
  String get name => '${type.label} $id';
  String get status => stage == ConstructionStage.shell
      ? 'Building ${type.label.toLowerCase()}'
      : stage.label;
  int get valuation =>
      completedFloors * footprint.tiles * type.shellPerTile +
      completedBasements * footprint.basementCost +
      standardLifts * BuildingUpgrade.standardLift.cost(this) +
      executiveLifts * BuildingUpgrade.executiveLift.cost(this) +
      (luxury - 1) * BuildingUpgrade.luxury.cost(this);
  int get maintenance =>
      completedFloors * (type.floorMaintenance + (luxury - 1) * 2000) +
      completedBasements * StarterCatalog.maintenancePerBasement +
      standardLifts * BuildingUpgrade.standardLift.maintenance +
      executiveLifts * BuildingUpgrade.executiveLift.maintenance;
  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'initialFloors': initialFloors,
    'originalQuote': originalQuote,
    'luxury': luxury,
    'visitsToday': visitsToday,
    'currentVisitors': currentVisitors,
    'visitorCapacity': visitorCapacity,
    'salesToday': salesToday,
    'parkingToday': parkingToday,
    'rushed': rushed,
    'rushGems': rushGems,
    'footprint': footprint.toJson(),
    'stage': stage.name,
    'startedDay': startedDay,
    'pendingRent': pendingRent,
    'aboveGroundFloors': aboveGroundFloors,
    'undergroundFloors': undergroundFloors,
    'standardLifts': standardLifts,
    'executiveLifts': executiveLifts,
    'upgrade': upgrade?.toJson(),
    'occupied': occupied.toList()..sort(),
  };
  factory ApartmentBuilding.fromJson(
    Map<String, dynamic> json, {
    bool legacy = false,
  }) {
    final building = ApartmentBuilding(
      id: json['id'] as int,
      type: BuildingType.values.byName(json['type'] as String? ?? 'apartment'),
      initialFloors: json['initialFloors'] as int? ?? 1,
      originalQuote: json['originalQuote'] as int?,
      luxury: json['luxury'] as int? ?? 1,
      visitsToday: json['visitsToday'] as int? ?? 0,
      currentVisitors: json['currentVisitors'] as int? ?? 0,
      visitorCapacity: json['visitorCapacity'] as int? ?? 0,
      salesToday: json['salesToday'] as int? ?? 0,
      parkingToday: json['parkingToday'] as int? ?? 0,
      rushed: json['rushed'] as bool? ?? false,
      rushGems: json['rushGems'] as int? ?? 0,
      footprint: Footprint.fromJson(
        Map<String, dynamic>.from(json['footprint'] as Map),
      ),
      stage: ConstructionStage.values.byName(json['stage'] as String),
      startedDay: json['startedDay'] as int,
      pendingRent: json['pendingRent'] as int,
      aboveGroundFloors: legacy ? 1 : json['aboveGroundFloors'] as int,
      undergroundFloors: legacy ? 1 : json['undergroundFloors'] as int,
      standardLifts: legacy ? 0 : json['standardLifts'] as int,
      executiveLifts: legacy ? 0 : json['executiveLifts'] as int,
      upgrade: legacy || json['upgrade'] == null
          ? null
          : UpgradeOrder.fromJson(
              Map<String, dynamic>.from(json['upgrade'] as Map),
            ),
      occupied: Set<int>.from(json['occupied'] as List),
    );
    if (building.id < 1 ||
        building.rushGems < 0 ||
        building.rushed != (building.rushGems > 0) ||
        (building.rushed &&
            building.stage != ConstructionStage.shell &&
            building.stage != ConstructionStage.basement) ||
        building.initialFloors < 1 ||
        building.initialFloors > 10 ||
        building.initialFloors > building.aboveGroundFloors ||
        building.originalQuote !=
            building.type.quote(
              building.footprint.tiles,
              building.initialFloors,
            ) ||
        building.luxury < 1 ||
        building.luxury > 3 ||
        building.unitsPerFloor < 1 ||
        building.visitsToday < 0 ||
        building.currentVisitors < 0 ||
        building.currentVisitors > building.visitorCapacity ||
        building.currentVisitors > building.visitsToday ||
        building.visitorCapacity > building.eligibleCapacity ||
        building.salesToday < 0 ||
        building.parkingToday < 0 ||
        building.startedDay < 0 ||
        building.pendingRent < 0 ||
        building.aboveGroundFloors < 1 ||
        building.aboveGroundFloors > GameRules.maximumAboveGroundFloors ||
        building.undergroundFloors < 1 ||
        building.undergroundFloors > GameRules.maximumUndergroundFloors ||
        building.standardLifts < 0 ||
        building.standardLifts > GameRules.maximumStandardLifts ||
        building.executiveLifts < 0 ||
        building.executiveLifts > GameRules.maximumExecutiveLifts ||
        (building.stage != ConstructionStage.ready &&
            (building.aboveGroundFloors != building.initialFloors ||
                building.undergroundFloors != 1 ||
                building.standardLifts != 0 ||
                building.executiveLifts != 0 ||
                building.upgrade != null)) ||
        (building.upgrade != null &&
            building.upgrade!.kind.count(building) >=
                building.upgrade!.kind.maximum) ||
        building.occupied.any((room) => room < 0 || room >= building.rooms) ||
        building.usedBays > building.bays ||
        (building.type == BuildingType.foodCourt &&
            building.occupied.isNotEmpty) ||
        (building.stage != ConstructionStage.ready &&
            building.occupied.isNotEmpty)) {
      throw const FormatException('Invalid building state');
    }
    return building;
  }
}

class ClosingStatement {
  const ClosingStatement({
    required this.day,
    required this.rent,
    required this.parking,
    required this.maintenance,
    required this.tax,
    required this.purchases,
    this.refunds = 0,
    this.hotel = 0,
    this.office = 0,
    this.sales = 0,
  });
  final int day, rent, parking, maintenance, tax, purchases, refunds;
  final int hotel, office, sales;
  int get gross => rent + parking + hotel + office + sales;
  int get net => gross - maintenance - tax;
  Map<String, Object> toJson() => {
    'day': day,
    'rent': rent,
    'parking': parking,
    'maintenance': maintenance,
    'tax': tax,
    'purchases': purchases,
    'refunds': refunds,
    'hotel': hotel,
    'office': office,
    'sales': sales,
  };
  factory ClosingStatement.fromJson(Map<String, dynamic> json) =>
      ClosingStatement(
        day: json['day'] as int,
        rent: json['rent'] as int,
        parking: json['parking'] as int,
        maintenance: json['maintenance'] as int,
        tax: json['tax'] as int,
        purchases: json['purchases'] as int,
        refunds: json['refunds'] as int? ?? 0,
        hotel: json['hotel'] as int? ?? 0,
        office: json['office'] as int? ?? 0,
        sales: json['sales'] as int? ?? 0,
      );
}

/// Working snapshot. Repositories mutate only transaction-local instances.
class DistrictGame {
  DistrictGame({
    required this.watermark,
    this.balance = 4000000,
    this.day = 1,
    this.phaseIndex = 0,
    this.remainder = 0,
    this.phaseMilliseconds = StarterCatalog.phaseMilliseconds,
    this.hourlyClock = true,
    this.lastClosing = 0,
    this.nextBuildingId = 1,
    this.earned = 0,
    this.purchasesSinceClosing = 0,
    this.refundsSinceClosing = 0,
    this.catalogVersion = 2,
    this.gems = 0,
    this.soundEnabled = false,
    Set<Achievement>? achievements,
    List<DistrictDecoration>? decorations,
    List<ApartmentBuilding>? buildings,
    this.statement,
  }) : buildings = buildings ?? [],
       achievements = achievements ?? {},
       decorations = decorations ?? [];
  int watermark,
      phaseMilliseconds,
      balance,
      day,
      phaseIndex,
      remainder,
      lastClosing,
      nextBuildingId,
      earned,
      purchasesSinceClosing,
      refundsSinceClosing;
  int catalogVersion, gems;
  bool soundEnabled;
  final Set<Achievement> achievements;
  final List<DistrictDecoration> decorations;
  final List<ApartmentBuilding> buildings;
  bool hourlyClock;
  ClosingStatement? statement;
  int advancedDays = 0;
  int balanceBeforeAdvance = 0;
  GamePhase get phase => GamePhase.values[phaseIndex];
  int get timeOfDayMilliseconds => phaseIndex * phaseMilliseconds + remainder;
  int get weekday => (day - 1) % 7;
  String get weekdayLabel => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday];
  int get nextSunday =>
      day + (6 - weekday) + (weekday == 6 && phaseIndex == 4 ? 7 : 0);
  int get pendingRent => buildings.fold(0, (sum, b) => sum + b.pendingRent);
  Set<LandCell> get roads =>
      buildings.expand((b) => b.footprint.roadRing).toSet();
  Map<String, Object?> toJson() => {
    'version': hourlyClock ? (catalogVersion == 2 ? 7 : 6) : 5,
    'catalog': catalogVersion,
    'gems': gems,
    'soundEnabled': soundEnabled,
    'achievements': achievements.map((a) => a.name).toList()..sort(),
    'decorations': decorations.map((d) => d.toJson()).toList(),
    'phaseMilliseconds': phaseMilliseconds,
    'watermark': watermark,
    'balance': balance,
    'day': day,
    'phaseIndex': phaseIndex,
    'remainder': remainder,
    'lastClosing': lastClosing,
    'nextBuildingId': nextBuildingId,
    'earned': earned,
    'purchasesSinceClosing': purchasesSinceClosing,
    'refundsSinceClosing': refundsSinceClosing,
    'buildings': buildings.map((b) => b.toJson()).toList(),
    'statement': statement?.toJson(),
  };
  factory DistrictGame.fromJson(Map<String, dynamic> json) {
    if ((json['version'] != 1 &&
            json['version'] != 2 &&
            json['version'] != 3 &&
            json['version'] != 4 &&
            json['version'] != 5 &&
            json['version'] != 6 &&
            json['version'] != 7) ||
        json['catalog'] != (json['version'] == 7 ? 2 : 1)) {
      throw const FormatException('Unsupported game save');
    }
    final state = DistrictGame(
      watermark: json['watermark'] as int,
      balance: json['balance'] as int,
      day: json['day'] as int,
      phaseIndex: json['phaseIndex'] as int,
      remainder: json['remainder'] as int,
      phaseMilliseconds: json['version'] == 1
          ? StarterCatalog.legacyPhaseMilliseconds
          : json['phaseMilliseconds'] as int,
      hourlyClock: (json['version'] as int) >= 6,
      catalogVersion: json['catalog'] as int,
      gems: json['gems'] as int? ?? 0,
      soundEnabled: json['soundEnabled'] as bool? ?? false,
      achievements: (json['achievements'] as List? ?? [])
          .map((a) => Achievement.values.byName(a as String))
          .toSet(),
      decorations: (json['decorations'] as List? ?? [])
          .map(
            (d) => DistrictDecoration.fromJson(
              Map<String, dynamic>.from(d as Map),
            ),
          )
          .toList(),
      lastClosing: json['lastClosing'] as int,
      nextBuildingId: json['nextBuildingId'] as int,
      earned: json['earned'] as int,
      purchasesSinceClosing: (json['version'] as int) >= 5
          ? json['purchasesSinceClosing'] as int
          : 0,
      refundsSinceClosing: (json['version'] as int) >= 5
          ? json['refundsSinceClosing'] as int
          : 0,
      buildings: (json['buildings'] as List)
          .map(
            (b) => ApartmentBuilding.fromJson(
              Map<String, dynamic>.from(b as Map),
              legacy: (json['version'] as int) < 4,
            ),
          )
          .toList(),
      statement: json['statement'] == null
          ? null
          : ClosingStatement.fromJson(
              Map<String, dynamic>.from(json['statement'] as Map),
            ),
    );
    if (state.day < 1 ||
        state.phaseIndex < 0 ||
        state.phaseIndex > (state.hourlyClock ? 3 : 4) ||
        state.remainder < 0 ||
        (state.hourlyClock
            ? state.phaseMilliseconds != StarterCatalog.phaseMilliseconds
            : state.phaseMilliseconds !=
                      StarterCatalog.previousPhaseMilliseconds &&
                  state.phaseMilliseconds !=
                      StarterCatalog.legacyPhaseMilliseconds) ||
        state.remainder >= state.phaseMilliseconds ||
        state.lastClosing != state.day - (state.phaseIndex == 4 ? 0 : 1) ||
        state.earned < 0 ||
        state.gems < 0 ||
        state.decorations.map((d) => d.cell).toSet().length !=
            state.decorations.length ||
        state.decorations.any(
          (d) =>
              DistrictProgression.decorationError(state, d.cell, ignore: d) !=
              null,
        ) ||
        state.purchasesSinceClosing < 0 ||
        state.refundsSinceClosing < 0 ||
        state.nextBuildingId < 1 ||
        state.buildings.map((b) => b.id).toSet().length !=
            state.buildings.length ||
        state.buildings.any((b) => b.id >= state.nextBuildingId)) {
      throw const FormatException('Invalid game snapshot');
    }
    if ((json['version'] as int) < 5) {
      // Old queued orders held funds outside the wallet. Debit them once before
      // catch-up; later closings only advance their construction stage.
      final queuedCost = state.buildings.fold<int>(
        0,
        (sum, building) =>
            sum +
            (building.stage == ConstructionStage.reserved
                ? building.footprint.quote
                : 0) +
            (building.upgrade?.stage == UpgradeStage.reserved
                ? building.upgrade!.kind.cost(building)
                : 0),
      );
      state.balance -= queuedCost;
      state.purchasesSinceClosing += queuedCost;
    }
    return state;
  }
}

class GameplayException implements Exception {
  const GameplayException(this.message);
  final String message;
}

abstract final class DistrictSimulation {
  /// A transaction-local preview only; no balance, rewards or time are published.
  static ClosingStatement projectClosing(DistrictGame state) {
    final preview = DistrictGame.fromJson(state.toJson());
    advance(
      preview,
      preview.watermark +
          StarterCatalog.dayMilliseconds -
          preview.timeOfDayMilliseconds,
    );
    return preview.statement!;
  }

  static String? upgradeError(
    DistrictGame state,
    ApartmentBuilding building,
    BuildingUpgrade kind,
  ) {
    if (building.stage != ConstructionStage.ready) {
      return 'Open the building before upgrading.';
    }
    if (kind.count(building) >= kind.maximum) return 'Maximum reached.';
    if (building.upgrade != null) return 'Finish the current upgrade first.';
    if (kind.cost(building) > state.balance) {
      return 'Not enough money.';
    }
    return null;
  }

  static void orderUpgrade(DistrictGame state, int id, BuildingUpgrade kind) {
    final building = _find(state, id);
    final error = upgradeError(state, building, kind);
    if (error != null) throw GameplayException(error);
    final cost = kind.cost(building);
    state.balance -= cost;
    state.purchasesSinceClosing += cost;
    building.upgrade = UpgradeOrder(kind: kind);
  }

  static void cancelUpgrade(DistrictGame state, int id) {
    final building = _find(state, id);
    final order = building.upgrade;
    if (order == null) {
      throw const GameplayException('There is no upgrade to cancel.');
    }
    final refund = order.kind.cost(building);
    state.gems += order.rushGems;
    state.balance += refund;
    state.refundsSinceClosing += refund;
    building.upgrade = null;
  }

  static double upgradeProgress(
    DistrictGame state,
    ApartmentBuilding building, {
    int elapsedMilliseconds = 0,
  }) {
    final order = building.upgrade;
    if (order == null) return 1;
    if (order.stage != UpgradeStage.building) return 0;
    final phases =
        (state.day - order.startedDay) * 4 +
        state.phaseIndex +
        (state.remainder + math.max(0, elapsedMilliseconds)) /
            state.phaseMilliseconds;
    return (phases / (order.kind.duration(building) * 4)).clamp(0.0, .999);
  }

  /// Completed work: the two-day shell is 2/3; the one-day B1 job is 1/3.
  static double constructionProgress(
    DistrictGame state,
    ApartmentBuilding building, {
    int elapsedMilliseconds = 0,
  }) {
    final elapsedPhases =
        (state.day - building.startedDay) * 4 +
        state.phaseIndex +
        (state.remainder + math.max(0, elapsedMilliseconds)) /
            state.phaseMilliseconds;
    return switch (building.stage) {
      ConstructionStage.reserved || ConstructionStage.paid => 0,
      ConstructionStage.shell =>
        (elapsedPhases / (building.initialShellDays * 4)).clamp(0.0, 1.0) *
            building.initialShellDays /
            (building.initialShellDays + 1),
      ConstructionStage.shellDone =>
        building.initialShellDays / (building.initialShellDays + 1),
      ConstructionStage.basement =>
        // Reserve 100% for the committed completion state.
        building.initialShellDays / (building.initialShellDays + 1) +
            (elapsedPhases / 4).clamp(0.0, .999) /
                (building.initialShellDays + 1),
      ConstructionStage.parkingDone || ConstructionStage.ready => 1,
    };
  }

  static void openBusiness(DistrictGame state, int id) {
    final building = _find(state, id);
    if (building.stage == ConstructionStage.ready) return;
    if (building.stage != ConstructionStage.parkingDone) {
      throw const GameplayException('Finish construction before opening.');
    }
    building.stage = ConstructionStage.ready;
    DistrictProgression.evaluate(state);
  }

  static void advance(DistrictGame state, int now) {
    final interval = state.phaseMilliseconds;
    var elapsed = math.max(0, now - state.watermark) + state.remainder;
    state.watermark = math.max(now, state.watermark);
    while (elapsed >= interval) {
      elapsed -= interval;
      if (state.hourlyClock && state.phaseIndex == 3) {
        _close(state);
        state.day++;
        state.phaseIndex = 0;
        _morning(state);
      } else if (state.phaseIndex == 4) {
        state.day++;
        state.phaseIndex = 0;
        _morning(state);
      } else {
        state.phaseIndex++;
        if (!state.hourlyClock && state.phaseIndex == 4) _close(state);
        if (state.catalogVersion == 2 && state.phaseIndex < 4) {
          _visitWindow(state);
        }
      }
    }
    // Settle legacy offline time at its saved speed, then preserve phase progress.
    state.remainder = elapsed * StarterCatalog.phaseMilliseconds ~/ interval;
    state.phaseMilliseconds = StarterCatalog.phaseMilliseconds;
    if (!state.hourlyClock && state.phaseIndex == 4) {
      // Legacy closing was already settled. Do not rewind into that paid day.
      state.day++;
      state.phaseIndex = 0;
      state.remainder = 0;
      _morning(state);
    }
    state.hourlyClock = true;
    state.catalogVersion = 2;
    DistrictProgression.evaluate(state);
  }

  static String? placementError(
    DistrictGame state,
    Footprint site, {
    BuildingType type = BuildingType.apartment,
    int floors = 1,
  }) {
    if (floors < 1 || floors > GameRules.maximumAboveGroundFloors) {
      return 'Choose 1–10 above-ground floors.';
    }
    if (site.width < 1 ||
        site.length < 1 ||
        type.unitsPerFloor(site.tiles) < 1) {
      return 'Choose at least two land tiles for an apartment or hotel.';
    }
    if (type.quote(site.tiles, floors) > state.balance) {
      return 'Not enough money for the building and B1 parking.';
    }
    final roads = state.roads;
    if (state.decorations.any(
      (d) => site.contains(d.cell) || site.roadRing.contains(d.cell),
    )) {
      return 'Move decorations clear of the building and its surrounding road.';
    }
    if (site.cells.any(roads.contains)) {
      return 'The footprint overlaps a road. Leave roads outside your building.';
    }
    for (final building in state.buildings) {
      if (site.cells.any(building.footprint.contains) ||
          site.roadRing.any(building.footprint.contains)) {
        return 'The building or its surrounding road overlaps an occupied plot.';
      }
    }
    return null;
  }

  static void place(
    DistrictGame state,
    Footprint site, {
    BuildingType type = BuildingType.apartment,
    int floors = 1,
  }) {
    final error = placementError(state, site, type: type, floors: floors);
    if (error != null) throw GameplayException(error);
    final quote = type.quote(site.tiles, floors);
    state.balance -= quote;
    state.purchasesSinceClosing += quote;
    state.buildings.add(
      ApartmentBuilding(
        id: state.nextBuildingId++,
        footprint: site,
        type: type,
        initialFloors: floors,
        aboveGroundFloors: floors,
      ),
    );
  }

  static void cancel(DistrictGame state, int id) {
    final building = _find(state, id);
    if (building.stage == ConstructionStage.ready) {
      throw const GameplayException('An open building cannot be canceled.');
    }
    state.balance += building.originalQuote;
    state.gems += building.rushGems;
    state.refundsSinceClosing += building.originalQuote;
    state.buildings.remove(building);
  }

  static void vacate(DistrictGame state, int id, int room) {
    final building = _find(state, id);
    if (!building.occupied.remove(room)) {
      throw const GameplayException('This room is already vacant.');
    }
  }

  static ApartmentBuilding _find(DistrictGame state, int id) =>
      state.buildings.firstWhere(
        (b) => b.id == id,
        orElse: () => throw const GameplayException(
          'This building is no longer available.',
        ),
      );

  static void _morning(DistrictGame state) {
    for (final building in state.buildings) {
      final upgrade = building.upgrade;
      if (upgrade?.rushed == true) _completeUpgrade(building);
      if (building.rushed) {
        building.rushed = false;
        building.rushGems = 0;
        building.stage = building.stage == ConstructionStage.shell
            ? ConstructionStage.shellDone
            : ConstructionStage.parkingDone;
      }
      if (upgrade?.stage == UpgradeStage.paid) {
        upgrade!.stage = UpgradeStage.building;
        upgrade.startedDay = state.day;
      }
      if (building.stage == ConstructionStage.paid) {
        building.stage = ConstructionStage.shell;
        building.startedDay = state.day;
      } else if (building.stage == ConstructionStage.shellDone) {
        building.stage = ConstructionStage.basement;
        building.startedDay = state.day;
      }
      if (building.stage == ConstructionStage.ready) {
        final capacity = building.eligibleCapacity;
        final happiness = state.catalogVersion < 2 ? 100 : building.happiness;
        if (building.type == BuildingType.foodCourt) {
          building.visitorCapacity = capacity;
          continue;
        }
        if (building.type == BuildingType.hotel) building.occupied.clear();
        final demandPercent = building.type == BuildingType.hotel ? 75 : 25;
        var remainingAdmissions = math.min(
          (capacity * demandPercent * happiness + 9999) ~/ 10000,
          capacity - building.occupied.length,
        );
        for (
          var room = 0;
          room < building.rooms && remainingAdmissions > 0;
          room++
        ) {
          if (building.occupied.add(room)) remainingAdmissions--;
        }
      }
    }
    if (state.catalogVersion == 2) _visitWindow(state);
    DistrictProgression.evaluate(state);
  }

  static int synergyPercent(DistrictGame state, ApartmentBuilding receiver) {
    if (state.catalogVersion < 2) return 0;
    final ring = receiver.footprint.roadRing.toSet();
    var bonus = 0;
    for (final neighbor in state.buildings) {
      if (identical(neighbor, receiver)) continue;
      final compatible = receiver.type == BuildingType.foodCourt
          ? neighbor.type == BuildingType.apartment ||
                neighbor.type == BuildingType.office
          : neighbor.type == BuildingType.foodCourt;
      if (compatible && neighbor.footprint.roadRing.any(ring.contains)) {
        bonus += 5;
      }
    }
    return math.min(15, bonus);
  }

  static int _boost(DistrictGame state, ApartmentBuilding building, int base) {
    final percent =
        (100 + (building.luxury - 1) * 15) *
        (100 + synergyPercent(state, building));
    return (base * percent + 5000) ~/ 10000;
  }

  static void _visitWindow(DistrictGame state) {
    for (final building in state.buildings) {
      if (building.type != BuildingType.foodCourt ||
          building.stage != ConstructionStage.ready) {
        continue;
      }
      final demand = const [25, 75, 100, 50][state.phaseIndex];
      final count =
          (building.visitorCapacity * demand * building.happiness + 9999) ~/
          10000;
      building.currentVisitors = count;
      building.visitsToday += count;
      building.salesToday += _boost(state, building, count * 2500);
      building.parkingToday += count * StarterCatalog.parkingPerTenant;
    }
  }

  static void _completeUpgrade(ApartmentBuilding building) {
    switch (building.upgrade!.kind) {
      case BuildingUpgrade.floor:
        building.aboveGroundFloors++;
      case BuildingUpgrade.basement:
        building.undergroundFloors++;
      case BuildingUpgrade.standardLift:
        building.standardLifts++;
      case BuildingUpgrade.executiveLift:
        building.executiveLifts++;
      case BuildingUpgrade.luxury:
        building.luxury++;
    }
    building.upgrade = null;
  }

  static void _close(DistrictGame state) {
    if (state.lastClosing >= state.day) return;
    var rent = 0, parking = 0, maintenance = 0, valuation = 0;
    var hotel = 0, office = 0, sales = 0;
    for (final building in state.buildings) {
      final upgrade = building.upgrade;
      if (upgrade?.stage == UpgradeStage.reserved) {
        upgrade!.stage = UpgradeStage.paid;
      } else if (upgrade?.stage == UpgradeStage.building &&
          !upgrade!.rushed &&
          state.day >=
              upgrade.startedDay + upgrade.kind.duration(building) - 1) {
        _completeUpgrade(building);
      }
      if (building.stage == ConstructionStage.reserved) {
        building.stage = ConstructionStage.paid;
      } else if (building.stage == ConstructionStage.shell &&
          !building.rushed &&
          state.day >= building.startedDay + building.initialShellDays - 1) {
        building.stage = ConstructionStage.shellDone;
      } else if (building.stage == ConstructionStage.basement &&
          !building.rushed &&
          state.day >= building.startedDay) {
        building.stage = ConstructionStage.parkingDone;
      }
      if (building.stage == ConstructionStage.ready) {
        final dailyPortion =
            StarterCatalog.weeklyRent ~/ 7 +
            (state.weekday < StarterCatalog.weeklyRent % 7 ? 1 : 0);
        final accrual = building.type == BuildingType.apartment
            ? _boost(state, building, dailyPortion * building.occupied.length)
            : 0;
        building.pendingRent += accrual;
        final receipts = building.type == BuildingType.foodCourt
            ? building.parkingToday
            : StarterCatalog.parkingPerTenant * building.usedBays;
        parking += receipts;
        final hotelRevenue = building.type == BuildingType.hotel
            ? _boost(state, building, 16000 * building.occupied.length)
            : 0;
        final officeRevenue = building.type == BuildingType.office
            ? _boost(
                state,
                building,
                18000 * building.footprint.tiles * building.occupied.length,
              )
            : 0;
        hotel += hotelRevenue;
        office += officeRevenue;
        sales += building.salesToday;
        state.earned +=
            accrual +
            receipts +
            hotelRevenue +
            officeRevenue +
            building.salesToday;
        building.salesToday = 0;
        building.parkingToday = 0;
        building.visitsToday = 0;
        building.currentVisitors = 0;
      }
      if (state.weekday == 6) {
        rent += building.pendingRent;
        building.pendingRent = 0;
      }
      maintenance += building.maintenance;
      valuation += building.valuation;
    }
    final gross = rent + parking + hotel + office + sales;
    final tax = (valuation + 1000) ~/ 2000 + (gross + 25) ~/ 50;
    state.balance += gross - maintenance - tax;
    state.lastClosing = state.day;
    state.statement = ClosingStatement(
      day: state.day,
      rent: rent,
      parking: parking,
      maintenance: maintenance,
      tax: tax,
      purchases: state.purchasesSinceClosing,
      refunds: state.refundsSinceClosing,
      hotel: hotel,
      office: office,
      sales: sales,
    );
    state.purchasesSinceClosing = 0;
    state.refundsSinceClosing = 0;
    DistrictProgression.evaluate(state);
  }
}
