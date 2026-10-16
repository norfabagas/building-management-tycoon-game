import 'game_rules.dart';

/// Catalog 2, explicitly approved on 2026-10-16. All amounts are cents.
extension BuildingCatalog on BuildingType {
  String get label => switch (this) {
    BuildingType.apartment => 'Apartment',
    BuildingType.hotel => 'Hotel',
    BuildingType.office => 'Office tower',
    BuildingType.foodCourt => 'Food court',
  };
  String get unitLabel => switch (this) {
    BuildingType.office => 'floor leases',
    BuildingType.foodCourt => 'visitor parties',
    _ => 'rooms',
  };
  String get role => switch (this) {
    BuildingType.apartment => 'Resident',
    BuildingType.hotel => 'Guest',
    BuildingType.office => 'Corporate tenant',
    BuildingType.foodCourt => 'Customer',
  };
  int get shellPerTile => switch (this) {
    BuildingType.apartment => 200000,
    BuildingType.hotel => 260000,
    BuildingType.office => 320000,
    BuildingType.foodCourt => 180000,
  };
  int get shellDays => this == BuildingType.office ? 3 : 2;
  int get floorMaintenance => switch (this) {
    BuildingType.hotel => 5500,
    BuildingType.office => 8000,
    _ => 4000,
  };
  int unitsPerFloor(int tiles) => switch (this) {
    BuildingType.office => 1,
    BuildingType.foodCourt => tiles,
    _ => tiles * 3 ~/ 4,
  };
  int baysPerUnit(int tiles) =>
      this == BuildingType.office ? (tiles * 3 + 1) ~/ 2 : 1;
  int quote(int tiles, [int floors = 1]) =>
      tiles * (shellPerTile * floors + 50000);
}
