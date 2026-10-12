import 'package:flutter/material.dart';

import '../../app/game_assets.dart';

class GameBrand extends StatelessWidget {
  const GameBrand({super.key, this.size = 56, this.fontSize = 27});
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset(
        GameAssets.logo,
        width: size,
        height: size,
        semanticLabel: 'BM tower logo',
      ),
      SizedBox(width: size / 4),
      Expanded(
        child: Text(
          'Building Management Tycoon',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
