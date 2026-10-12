import 'game_rules.dart';

/// Save-slot metadata, not a complete economy or building snapshot.
class LocalProfile {
  LocalProfile({
    required this.slot,
    required String areaName,
    required this.createdAt,
  }) : areaName = areaName.trim() {
    if (slot < 1 || slot > GameRules.profileSlots) {
      throw ArgumentError.value(slot, 'slot', 'Must be between 1 and 5');
    }
    if (this.areaName.isEmpty) {
      throw ArgumentError.value(areaName, 'areaName', 'Must not be empty');
    }
  }

  final int slot;
  final String areaName;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'slot': slot,
    'areaName': areaName,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory LocalProfile.fromJson(Map<String, dynamic> json) {
    if (json['slot'] is! int ||
        json['areaName'] is! String ||
        json['createdAt'] is! String) {
      throw const FormatException('Invalid profile metadata');
    }
    return LocalProfile(
      slot: json['slot'] as int,
      areaName: json['areaName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
