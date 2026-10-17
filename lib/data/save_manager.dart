import 'dart:convert';

import '../domain/game_rules.dart';
import '../domain/local_profile.dart';
import 'local_save_store.dart';
import 'game_repository.dart';

class SaveFormatException implements Exception {
  const SaveFormatException();
}

/// Versioned five-slot metadata. Invalid saves are preserved, never reset.
class SaveManager {
  SaveManager(this._store, {this.games, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final LocalSaveStore _store;
  final GameRepository? games;
  final DateTime Function() _now;
  Future<void> _pending = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final operation = _pending.then((_) => action());
    _pending = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }

  Future<List<LocalProfile?>> loadProfiles() => _serial(() async {
    final repository = games;
    if (repository == null) return _readMetadata();
    final slots = await repository.loadProfiles(_readMetadata);
    await _mirror(slots);
    return slots;
  });

  Future<void> _mirror(List<LocalProfile?> slots) async {
    // The database catalog and snapshot commit together. Preferences are only
    // a compatibility mirror after the initial validated import.
    try {
      await _store.write(_encode(slots));
    } catch (_) {}
  }

  String _encode(List<LocalProfile?> profiles) => jsonEncode({
    'version': 1,
    'slots': profiles.map((profile) => profile?.toJson()).toList(),
  });

  Future<List<LocalProfile?>> _readMetadata() async {
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
      final profiles = List<LocalProfile?>.generate(GameRules.profileSlots, (
        index,
      ) {
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
      return profiles;
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
    final requested = LocalProfile(
      slot: slot,
      areaName: areaName,
      createdAt: _now(),
    );
    return _serial(() async {
      final repository = games;
      if (repository != null) {
        final profile = await repository.createProfile(
          requested,
          _readMetadata,
        );
        try {
          await _mirror(await repository.loadProfiles(_readMetadata));
        } catch (_) {}
        return profile;
      }
      final slots = await _readMetadata();
      if (slots[slot - 1] != null) throw StateError('Slot already occupied');
      final profile = requested;
      slots[slot - 1] = profile;
      await _store.write(_encode(slots));
      return profile;
    });
  }

  Future<void> deleteProfile(LocalProfile profile) => _serial(() async {
    final repository = games;
    if (repository == null) {
      throw StateError('Game storage is required for deletion');
    }
    await repository.deleteProfile(profile, _readMetadata);
    try {
      await _mirror(await repository.loadProfiles(_readMetadata));
    } catch (_) {}
  });
}
