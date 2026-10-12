import 'package:flutter/material.dart';

import '../data/game_repository.dart';

import '../features/profiles/profile_screen.dart';
import '../features/profiles/profile_view_model.dart';
import 'game_theme.dart';

class TycoonApp extends StatelessWidget {
  const TycoonApp({super.key, required this.profiles, required this.games});
  final ProfileViewModel profiles;
  final GameRepository games;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Building Management Tycoon',
    debugShowCheckedModeBanner: false,
    theme: buildGameTheme(),
    home: ProfileScreen(viewModel: profiles, games: games),
  );
}
