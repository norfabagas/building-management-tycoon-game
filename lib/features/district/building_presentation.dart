import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../app/production_assets.dart';
import '../../domain/district_game.dart';

extension BuildingArtwork on BuildingType {
  String luxuryArtwork(int tier) =>
      exterior.replaceFirst('.png', '-luxury-$tier.png');
  String get exterior => switch (this) {
    BuildingType.apartment => ProductionAssets.buildingsApartment,
    BuildingType.hotel => ProductionAssets.buildingsHotel,
    BuildingType.office => ProductionAssets.buildingsOffice,
    BuildingType.foodCourt => ProductionAssets.buildingsFoodCourt,
  };
  String get roomArtwork => switch (this) {
    BuildingType.apartment => ProductionAssets.roomsApartment,
    BuildingType.hotel => ProductionAssets.roomsHotel,
    BuildingType.office => ProductionAssets.roomsOffice,
    BuildingType.foodCourt => ProductionAssets.roomsFoodCourt,
  };
  String get vacantArtwork => switch (this) {
    BuildingType.apartment => ProductionAssets.roomsApartmentVacantShell,
    BuildingType.hotel => ProductionAssets.roomsHotelVacantShell,
    BuildingType.office => ProductionAssets.roomsOfficeVacantShell,
    BuildingType.foodCourt => ProductionAssets.roomsFoodCourtVacantShell,
  };
  String get actor => switch (this) {
    BuildingType.apartment => ProductionAssets.charactersResidentAnimation,
    BuildingType.hotel => ProductionAssets.charactersGuestAnimation,
    BuildingType.office => ProductionAssets.charactersOfficeAnimation,
    BuildingType.foodCourt => ProductionAssets.charactersCustomerAnimation,
  };
  Color get color => switch (this) {
    BuildingType.apartment => GameColors.apartment,
    BuildingType.hotel => GameColors.hotel,
    BuildingType.office => GameColors.office,
    BuildingType.foodCourt => GameColors.mint,
  };
  String get description => switch (this) {
    BuildingType.apartment => 'Long-term rooms · Rent paid on Sunday',
    BuildingType.hotel => 'Daily guests · Daily room income',
    BuildingType.office => 'Whole-floor leases · Daily corporate rent',
    BuildingType.foodCourt => 'Visitor parties · Sales in four daily windows',
  };
}

extension DecorationArtwork on DecorationKind {
  String get artwork => switch (this) {
    DecorationKind.tree => ProductionAssets.decorationsTree,
    DecorationKind.hedge => ProductionAssets.decorationsHedge,
    DecorationKind.planter => ProductionAssets.decorationsPlanter,
    DecorationKind.bench => ProductionAssets.decorationsBench,
    DecorationKind.streetlamp => ProductionAssets.decorationsStreetlamp,
    DecorationKind.tableSet => ProductionAssets.decorationsTableSet,
  };
}
