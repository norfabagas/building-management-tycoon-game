import 'dart:convert';

import '../domain/game_rules.dart';
import '../domain/local_profile.dart';
import 'local_save_store.dart';

class SaveFormatException implements Exception {
  const SaveFormatException();
}

/// Versioned five-slot metadata. Invalid saves are preserved, never reset.
class SaveManager {
  SaveManager(this._store, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final LocalSaveStore _store;
  final DateTime Function() _now;
  Future<void> _pending = Future<void>.value();

  Future<List<LocalProfile?>> loadProfiles() async {
    final source = await _store.read();
    if (source == null) return List.filled(GameRules.profileSlots, null);
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        throw const SaveFormatException();
      }
      final slots = decoded['slots'];
      if (slots is! List || slots.length != GameRules.profileSlots) {
        throw const SaveFormatException();
      }
      return List.generate(GameRules.profileSlots, (index) {
        if (slots[index] == null) return null;
        if (slots[index] is! Map<String, dynamic>) {
          throw const SaveFormatException();
        }
        final profile = LocalProfile.fromJson(
          slots[index] as Map<String, dynamic>,
        );
        if (profile.slot != index + 1) throw const SaveFormatException();
        return profile;
      });
    } on FormatException {
      throw const SaveFormatException();
    } on ArgumentError {
      throw const SaveFormatException();
    }
  }

  /// Serialize read-modify-write to prevent concurrent slot creation losing data.
  Future<LocalProfile> createProfile({
    required int slot,
    required String areaName,
  }) {
    final profile = LocalProfile(
      slot: slot,
      areaName: areaName,
      createdAt: _now(),
    );
    final operation = _pending.then((_) async {
      final slots = await loadProfiles();
      if (slots[slot - 1] != null) throw StateError('Slot already occupied');
      slots[slot - 1] = profile;
      await _store.write(
        jsonEncode({
          'version': 1,
          'slots': slots.map((profile) => profile?.toJson()).toList(),
        }),
      );
      return profile;
    });
    _pending = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }
}
