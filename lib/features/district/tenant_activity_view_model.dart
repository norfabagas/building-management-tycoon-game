import 'package:flutter/material.dart';

import '../../domain/district_game.dart';

/// A read-only presentation of the saved unit, never a second simulation.
class TenantActivityViewModel {
  TenantActivityViewModel(this.game, this.building, this.unit);
  final DistrictGame game;
  final ApartmentBuilding building;

  /// A stable room/lease ID, or the first capacity position of a food floor.
  final int unit;

  int get floor => unit ~/ building.unitsPerFloor + 1;
  bool get isFoodCourt => building.type == BuildingType.foodCourt;
  int get visitors =>
      (building.currentVisitors - (floor - 1) * building.unitsPerFloor).clamp(
        0,
        building.unitsPerFloor,
      );
  bool get active =>
      building.stage == ConstructionStage.ready &&
      (isFoodCourt ? visitors > 0 : building.occupied.contains(unit));
  String get title => isFoodCourt
      ? 'Floor $floor · Dining area'
      : '${building.type == BuildingType.office ? 'Lease' : 'Room'} ${unit + 1} · ${building.type.role}';
  String get status => isFoodCourt
      ? '$visitors / ${building.unitsPerFloor} parties on this floor'
      : active
      ? 'Occupied'
      : 'Vacant';
  int get phase => game.phaseIndex.clamp(0, 3);
  List<InteriorActivity> get activities => switch (building.type) {
    BuildingType.apartment => const [
      InteriorActivity(
        'Getting ready',
        'Entrance',
        Icons.door_front_door_outlined,
        .18,
      ),
      InteriorActivity(
        'Time by the window',
        'Window',
        Icons.wb_sunny_outlined,
        .67,
      ),
      InteriorActivity(
        'Relaxing at home',
        'Lounge',
        Icons.weekend_outlined,
        .77,
      ),
      InteriorActivity('Winding down', 'Bedroom', Icons.bed_outlined, .40),
    ],
    BuildingType.hotel => const [
      InteriorActivity(
        'Getting ready',
        'Luggage area',
        Icons.luggage_outlined,
        .62,
      ),
      InteriorActivity('Time at the desk', 'Desk', Icons.laptop_outlined, .83),
      InteriorActivity(
        'Time by the window',
        'Window',
        Icons.wb_sunny_outlined,
        .64,
      ),
      InteriorActivity('Winding down', 'Bedroom', Icons.bed_outlined, .35),
    ],
    BuildingType.office => const [
      InteriorActivity('Arrival & planning', 'Entrance', Icons.login, .15),
      InteriorActivity(
        'Desk work',
        'Workstations',
        Icons.computer_outlined,
        .48,
      ),
      InteriorActivity(
        'Team catch-up',
        'Meeting area',
        Icons.groups_outlined,
        .79,
      ),
      InteriorActivity(
        'Quiet office',
        'Workstations',
        Icons.nights_stay_outlined,
        .48,
      ),
    ],
    BuildingType.foodCourt => const [
      InteriorActivity(
        'Breakfast service',
        'Service counter',
        Icons.bakery_dining_outlined,
        .68,
      ),
      InteriorActivity(
        'Lunch service',
        'Dining tables',
        Icons.restaurant_outlined,
        .38,
      ),
      InteriorActivity(
        'Afternoon dining',
        'Dining tables',
        Icons.local_cafe_outlined,
        .18,
      ),
      InteriorActivity(
        'Evening service',
        'Service counter',
        Icons.dinner_dining_outlined,
        .69,
      ),
    ],
  };
  InteriorActivity get current => activities[phase];
  bool get showPeople =>
      active && !(building.type == BuildingType.office && phase == 3);
  String get emptyMessage => isFoodCourt
      ? 'No parties on this floor. Visitors refresh each six-hour window, within the parking limit.'
      : 'No occupant in this unit. Admissions are checked next Morning, within demand and parking limits.';
}

class InteriorActivity {
  const InteriorActivity(this.label, this.zone, this.icon, this.x);
  final String label, zone;
  final IconData icon;
  final double x;
}
