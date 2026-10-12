import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:sembast/sembast_memory.dart';

GameRepository testGameRepository() {
  final database = openNewInMemoryDatabase();
  return GameRepository(open: () => database);
}
