import 'dart:math' as math;

import 'game_rules.dart';

/// User-approved apartment catalog; amounts are integer cents.
abstract final class StarterCatalog {
  static const shellPerTile = 200000;
  static const basementPerTile = 50000;
  static const weeklyRent = 84000;
  static const parkingPerTenant = 1000;
  static const maintenancePerFloor = 4000;
  static const maintenancePerBasement = 4000;
  static const phaseMilliseconds = 60000;
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
    if (result.width < 1 || result.length < 1 || result.rooms < 1) {
      throw const FormatException('Invalid starter footprint');
    }
    return result;
  }
}

enum ConstructionStage {
  reserved('Payment at Noon'),
  paid('Starts next Morning'),
  shell('Building shell'),
  shellDone('B1 starts next Morning'),
  basement('Building B1 parking'),
  parkingDone('Opens next Morning'),
  ready('Open');

  const ConstructionStage(this.label);
  final String label;
}

class ApartmentBuilding {
  ApartmentBuilding({
    required this.id,
    required this.footprint,
    this.stage = ConstructionStage.reserved,
    this.startedDay = 0,
    this.pendingRent = 0,
    Set<int>? occupied,
  }) : occupied = occupied ?? {};
  final int id;
  final Footprint footprint;
  ConstructionStage stage;
  int startedDay;
  int pendingRent;
  final Set<int> occupied;
  bool get shellComplete => stage.index >= ConstructionStage.shellDone.index;
  bool get parkingComplete =>
      stage.index >= ConstructionStage.parkingDone.index;
  int get valuation =>
      (shellComplete ? footprint.shellCost : 0) +
      (parkingComplete ? footprint.basementCost : 0);
  int get maintenance =>
      (shellComplete ? StarterCatalog.maintenancePerFloor : 0) +
      (parkingComplete ? StarterCatalog.maintenancePerBasement : 0);
  Map<String, Object> toJson() => {
    'id': id,
    'footprint': footprint.toJson(),
    'stage': stage.name,
    'startedDay': startedDay,
    'pendingRent': pendingRent,
    'occupied': occupied.toList()..sort(),
  };
  factory ApartmentBuilding.fromJson(Map<String, dynamic> json) {
    final building = ApartmentBuilding(
      id: json['id'] as int,
      footprint: Footprint.fromJson(
        Map<String, dynamic>.from(json['footprint'] as Map),
      ),
      stage: ConstructionStage.values.byName(json['stage'] as String),
      startedDay: json['startedDay'] as int,
      pendingRent: json['pendingRent'] as int,
      occupied: Set<int>.from(json['occupied'] as List),
    );
    if (building.id < 1 ||
        building.startedDay < 0 ||
        building.pendingRent < 0 ||
        building.occupied.any(
          (room) => room < 0 || room >= building.footprint.rooms,
        ) ||
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
  });
  final int day, rent, parking, maintenance, tax, purchases;
  int get gross => rent + parking;
  int get net => gross - maintenance - tax;
  Map<String, Object> toJson() => {
    'day': day,
    'rent': rent,
    'parking': parking,
    'maintenance': maintenance,
    'tax': tax,
    'purchases': purchases,
  };
  factory ClosingStatement.fromJson(Map<String, dynamic> json) =>
      ClosingStatement(
        day: json['day'] as int,
        rent: json['rent'] as int,
        parking: json['parking'] as int,
        maintenance: json['maintenance'] as int,
        tax: json['tax'] as int,
        purchases: json['purchases'] as int,
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
    this.lastClosing = 0,
    this.nextBuildingId = 1,
    this.earned = 0,
    List<ApartmentBuilding>? buildings,
    this.statement,
  }) : buildings = buildings ?? [];
  int watermark,
      balance,
      day,
      phaseIndex,
      remainder,
      lastClosing,
      nextBuildingId,
      earned;
  final List<ApartmentBuilding> buildings;
  ClosingStatement? statement;
  int advancedDays = 0;
  int balanceBeforeAdvance = 0;
  GamePhase get phase => GamePhase.values[phaseIndex];
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
  int get reserved => buildings
      .where((b) => b.stage == ConstructionStage.reserved)
      .fold(0, (sum, b) => sum + b.footprint.quote);
  int get available => math.max(0, balance - reserved);
  int get pendingRent => buildings.fold(0, (sum, b) => sum + b.pendingRent);
  Set<LandCell> get roads =>
      buildings.expand((b) => b.footprint.roadRing).toSet();
  Map<String, Object?> toJson() => {
    'version': 1,
    'catalog': 1,
    'watermark': watermark,
    'balance': balance,
    'day': day,
    'phaseIndex': phaseIndex,
    'remainder': remainder,
    'lastClosing': lastClosing,
    'nextBuildingId': nextBuildingId,
    'earned': earned,
    'buildings': buildings.map((b) => b.toJson()).toList(),
    'statement': statement?.toJson(),
  };
  factory DistrictGame.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 || json['catalog'] != 1) {
      throw const FormatException('Unsupported game save');
    }
    final state = DistrictGame(
      watermark: json['watermark'] as int,
      balance: json['balance'] as int,
      day: json['day'] as int,
      phaseIndex: json['phaseIndex'] as int,
      remainder: json['remainder'] as int,
      lastClosing: json['lastClosing'] as int,
      nextBuildingId: json['nextBuildingId'] as int,
      earned: json['earned'] as int,
      buildings: (json['buildings'] as List)
          .map(
            (b) =>
                ApartmentBuilding.fromJson(Map<String, dynamic>.from(b as Map)),
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
        state.phaseIndex > 4 ||
        state.remainder < 0 ||
        state.remainder >= StarterCatalog.phaseMilliseconds ||
        state.lastClosing != state.day - (state.phaseIndex == 4 ? 0 : 1) ||
        state.earned < 0 ||
        state.nextBuildingId < 1 ||
        state.buildings.map((b) => b.id).toSet().length !=
            state.buildings.length ||
        state.buildings.any((b) => b.id >= state.nextBuildingId)) {
      throw const FormatException('Invalid game snapshot');
    }
    return state;
  }
}

class GameplayException implements Exception {
  const GameplayException(this.message);
  final String message;
}

abstract final class DistrictSimulation {
  static void advance(DistrictGame state, int now) {
    if (now <= state.watermark) return;
    var elapsed = now - state.watermark + state.remainder;
    state.watermark = now;
    while (elapsed >= StarterCatalog.phaseMilliseconds) {
      elapsed -= StarterCatalog.phaseMilliseconds;
      if (state.phaseIndex == 4) {
        state.day++;
        state.phaseIndex = 0;
        _morning(state);
      } else {
        state.phaseIndex++;
        if (state.phaseIndex == 4) _close(state);
      }
    }
    state.remainder = elapsed;
  }

  static String? placementError(DistrictGame state, Footprint site) {
    if (site.width < 1 || site.length < 1 || site.rooms < 1) {
      return 'Choose at least two land tiles for an apartment.';
    }
    if (site.quote > state.available) {
      return 'Not enough available dollars for the shell and B1 parking.';
    }
    final roads = state.roads;
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

  static void place(DistrictGame state, Footprint site) {
    final error = placementError(state, site);
    if (error != null) throw GameplayException(error);
    state.buildings.add(
      ApartmentBuilding(id: state.nextBuildingId++, footprint: site),
    );
  }

  static void cancel(DistrictGame state, int id) {
    final building = _find(state, id);
    if (building.stage != ConstructionStage.reserved) {
      throw const GameplayException('Only unpaid orders can be canceled.');
    }
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
      if (building.stage == ConstructionStage.paid) {
        building.stage = ConstructionStage.shell;
        building.startedDay = state.day;
      } else if (building.stage == ConstructionStage.shellDone) {
        building.stage = ConstructionStage.basement;
        building.startedDay = state.day;
      } else if (building.stage == ConstructionStage.parkingDone) {
        building.stage = ConstructionStage.ready;
      }
      if (building.stage == ConstructionStage.ready) {
        final capacity = math.min(
          building.footprint.rooms,
          building.footprint.bays,
        );
        var remainingAdmissions = (capacity + 3) ~/ 4;
        for (var room = 0; room < capacity && remainingAdmissions > 0; room++) {
          if (building.occupied.add(room)) remainingAdmissions--;
        }
      }
    }
  }

  static void _close(DistrictGame state) {
    if (state.lastClosing >= state.day) return;
    var rent = 0, parking = 0, maintenance = 0, valuation = 0, purchases = 0;
    for (final building in state.buildings) {
      if (building.stage == ConstructionStage.reserved) {
        purchases += building.footprint.quote;
        building.stage = ConstructionStage.paid;
      } else if (building.stage == ConstructionStage.shell &&
          state.day >= building.startedDay + 1) {
        building.stage = ConstructionStage.shellDone;
      } else if (building.stage == ConstructionStage.basement &&
          state.day >= building.startedDay) {
        building.stage = ConstructionStage.parkingDone;
      }
      if (building.stage == ConstructionStage.ready) {
        final dailyPortion =
            StarterCatalog.weeklyRent ~/ 7 +
            (state.weekday < StarterCatalog.weeklyRent % 7 ? 1 : 0);
        final accrual = dailyPortion * building.occupied.length;
        building.pendingRent += accrual;
        final receipts =
            StarterCatalog.parkingPerTenant * building.occupied.length;
        parking += receipts;
        state.earned += accrual + receipts;
      }
      if (state.weekday == 6) {
        rent += building.pendingRent;
        building.pendingRent = 0;
      }
      maintenance += building.maintenance;
      valuation += building.valuation;
    }
    final tax = (valuation + 1000) ~/ 2000 + ((rent + parking) + 25) ~/ 50;
    state.balance += rent + parking - maintenance - tax - purchases;
    state.lastClosing = state.day;
    state.statement = ClosingStatement(
      day: state.day,
      rent: rent,
      parking: parking,
      maintenance: maintenance,
      tax: tax,
      purchases: purchases,
    );
  }
}
