import 'package:sembast/sembast.dart';

import '../domain/district_game.dart';
import '../domain/local_profile.dart';
import 'game_database.dart';

class GameRepository {
  GameRepository({Future<Database> Function()? open})
    : _open = open ?? openGameDatabase;
  final Future<Database> Function() _open;
  Future<Database>? _database;
  static final store = stringMapStoreFactory.store('districts');

  Future<DistrictGame> update(
    LocalProfile profile,
    int now, [
    void Function(DistrictGame)? action,
  ]) async {
    Database database;
    try {
      database = await (_database ??= _open());
    } catch (_) {
      _database = null;
      rethrow;
    }
    return database.transaction((transaction) async {
      final record = store.record(profile.slot.toString());
      final source = await record.get(transaction);
      final state = source == null
          ? DistrictGame(watermark: now)
          : DistrictGame.fromJson(source);
      final previousDay = state.day;
      state.balanceBeforeAdvance = state.balance;
      DistrictSimulation.advance(state, now);
      state.advancedDays = state.day - previousDay;
      action?.call(state);
      await record.put(transaction, state.toJson());
      return state;
    });
  }
}
