import 'package:sembast/sembast.dart';

import '../domain/district_game.dart';
import '../domain/local_profile.dart';
import '../domain/game_rules.dart';
import 'game_database.dart';

class GameRepository {
  GameRepository({Future<Database> Function()? open})
    : _open = open ?? openGameDatabase;
  final Future<Database> Function() _open;
  Future<Database>? _database;
  static final store = stringMapStoreFactory.store('districts');
  static final lifecycle = stringMapStoreFactory.store('profile_lifecycle');
  static final profiles = stringMapStoreFactory.store('profiles');

  List<LocalProfile?> _decodeProfiles(Map<String, dynamic> source) {
    final slots = source['slots'];
    if (source['version'] != 1 ||
        slots is! List ||
        slots.length != GameRules.profileSlots) {
      throw const FormatException('Unsupported profile catalog');
    }
    return List.generate(GameRules.profileSlots, (index) {
      if (slots[index] == null) return null;
      final profile = LocalProfile.fromJson(
        Map<String, dynamic>.from(slots[index] as Map),
      );
      if (profile.slot != index + 1) {
        throw const FormatException('Mismatched profile slot');
      }
      return profile;
    });
  }

  Future<void> _putProfiles(Transaction tx, List<LocalProfile?> slots) =>
      profiles.record('catalog').put(tx, {
        'version': 1,
        'slots': slots.map((profile) => profile?.toJson()).toList(),
      });

  Future<List<LocalProfile?>> _catalog(
    Transaction tx,
    Future<List<LocalProfile?>> Function() importLegacy,
  ) async {
    final current = await profiles.record('catalog').get(tx);
    if (current != null) return _decodeProfiles(current);
    final legacy = await importLegacy();
    await _putProfiles(tx, legacy);
    return legacy;
  }

  Future<List<LocalProfile?>> loadProfiles(
    Future<List<LocalProfile?>> Function() importLegacy,
  ) async {
    final database = await _getDatabase();
    return database.transaction((tx) => _catalog(tx, importLegacy));
  }

  Future<LocalProfile> createProfile(
    LocalProfile requested,
    Future<List<LocalProfile?>> Function() importLegacy,
  ) async {
    final database = await _getDatabase();
    return database.transaction((tx) async {
      final slots = await _catalog(tx, importLegacy);
      if (slots[requested.slot - 1] != null) {
        throw StateError('Slot already occupied');
      }
      final marker = lifecycle.record('${requested.slot}');
      final entry = await marker.get(tx);
      final cutoff = entry?['deletedThrough'];
      final deleted = cutoff == null ? null : DateTime.parse(cutoff as String);
      final profile = LocalProfile(
        slot: requested.slot,
        areaName: requested.areaName,
        createdAt: deleted != null && !requested.createdAt.isAfter(deleted)
            ? deleted.add(const Duration(microseconds: 1))
            : requested.createdAt,
      );
      slots[profile.slot - 1] = profile;
      await _putProfiles(tx, slots);
      await store.record('${profile.slot}').delete(tx);
      await marker.put(tx, {...?entry, 'owner': profile.toJson()});
      return profile;
    });
  }

  Future<Database> _getDatabase() async {
    try {
      return await (_database ??= _open());
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  static bool sameProfile(LocalProfile a, LocalProfile b) =>
      a.slot == b.slot &&
      a.createdAt.isAtSameMomentAs(b.createdAt) &&
      a.areaName == b.areaName;

  bool _deleted(Map<String, dynamic>? entry, LocalProfile profile) =>
      entry?['deletedThrough'] != null &&
      !profile.createdAt.toUtc().isAfter(
        DateTime.parse(entry!['deletedThrough'] as String),
      );

  Future<void> deleteProfile(
    LocalProfile profile,
    Future<List<LocalProfile?>> Function() importLegacy,
  ) async {
    final database = await _getDatabase();
    await database.transaction((transaction) async {
      final marker = lifecycle.record('${profile.slot}');
      final entry = await marker.get(transaction);
      final slots = await _catalog(transaction, importLegacy);
      final current = slots[profile.slot - 1];
      if (current == null && _deleted(entry, profile)) return;
      if (current == null || !sameProfile(current, profile)) {
        throw StateError(
          'The district in this slot has changed. Refresh the profile list.',
        );
      }
      final owner = entry?['owner'];
      if (owner != null &&
          !sameProfile(
            LocalProfile.fromJson(Map<String, dynamic>.from(owner as Map)),
            profile,
          )) {
        throw StateError(
          'The district in this slot has changed. Refresh the profile list.',
        );
      }
      await store.record('${profile.slot}').delete(transaction);
      await marker.put(transaction, {
        'deletedThrough': profile.createdAt.toUtc().toIso8601String(),
      });
      slots[profile.slot - 1] = null;
      await _putProfiles(transaction, slots);
    });
  }

  Future<DistrictGame> update(
    LocalProfile profile,
    int now, [
    void Function(DistrictGame)? action,
  ]) async {
    final database = await _getDatabase();
    return database.transaction((transaction) async {
      final catalog = await profiles.record('catalog').get(transaction);
      if (catalog != null) {
        final current = _decodeProfiles(catalog)[profile.slot - 1];
        if (current == null || !sameProfile(current, profile)) {
          throw const GameplayException(
            'This saved district is no longer available. Return to Choose a district.',
          );
        }
      }
      final marker = lifecycle.record('${profile.slot}');
      final entry = await marker.get(transaction);
      if (_deleted(entry, profile)) {
        throw const GameplayException(
          'This district was deleted. Return to Choose a district.',
        );
      }
      final owner = entry?['owner'];
      if (owner != null &&
          !sameProfile(
            LocalProfile.fromJson(Map<String, dynamic>.from(owner as Map)),
            profile,
          )) {
        throw const GameplayException(
          'This slot contains a different district. Return to Choose a district.',
        );
      }
      final record = store.record(profile.slot.toString());
      // A reused slot never inherits orphaned progress from an older client.
      final source = entry?['deletedThrough'] != null && owner == null
          ? null
          : await record.get(transaction);
      final state = source == null
          ? DistrictGame(watermark: now)
          : DistrictGame.fromJson(source);
      final previousDay = state.day;
      state.balanceBeforeAdvance = state.balance;
      DistrictSimulation.advance(state, now);
      state.advancedDays = state.day - previousDay;
      action?.call(state);
      await record.put(transaction, state.toJson());
      await marker.put(transaction, {...?entry, 'owner': profile.toJson()});
      return state;
    });
  }
}
