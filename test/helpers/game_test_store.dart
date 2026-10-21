import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:sembast/sembast_memory.dart';

GameRepository testGameRepository() {
  final database = openNewInMemoryDatabase();
  return GameRepository(open: () => database);
}

// Review/cancel assertions must not cross a game day on a busy test host.
class FixedClockGameRepository extends GameRepository {
  FixedClockGameRepository({required super.open, required this.fixedNow});
  final int fixedNow;
  @override
  Future<DistrictGame> update(
    LocalProfile profile,
    int now, [
    void Function(DistrictGame)? action,
  ]) => super.update(profile, fixedNow, action);
}
