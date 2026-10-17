import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/tycoon_app.dart';
import 'data/local_save_store.dart';
import 'data/game_repository.dart';
import 'data/save_manager.dart';
import 'features/profiles/profile_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final games = GameRepository();
  final saves = SaveManager(
    PreferencesSaveStore(SharedPreferencesAsync()),
    games: games,
  );
  runApp(TycoonApp(profiles: ProfileViewModel(saves), games: games));
}
