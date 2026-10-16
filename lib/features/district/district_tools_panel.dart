import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../domain/district_game.dart';
import '../../shared/widgets/game_button.dart';
import 'building_presentation.dart';
import 'district_view_model.dart';

class DistrictToolsPanel extends StatelessWidget {
  const DistrictToolsPanel({
    super.key,
    required this.game,
    required this.achievements,
    required this.onChooseDecoration,
    required this.onMoveDecoration,
  });
  final DistrictGame game;
  final bool achievements;
  final ValueChanged<DecorationKind>? onChooseDecoration;
  final ValueChanged<int>? onMoveDecoration;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (achievements) ...[
        const Text(
          'Earn gems offline by growing your district. Rewards are saved automatically, once per achievement.',
        ),
        for (final item in Achievement.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${item.reward} gems · ${game.achievements.contains(item)
                      ? 'Awarded'
                      : item == Achievement.earnedThousand
                      ? '${formatMoney(DistrictProgression.progress(game, item))} / ${formatMoney(DistrictProgression.target(item))}'
                      : '${DistrictProgression.progress(game, item)} / ${DistrictProgression.target(item)}'}',
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: game.achievements.contains(item)
                      ? 1
                      : DistrictProgression.progress(game, item) /
                            DistrictProgression.target(item),
                ),
              ],
            ),
          ),
      ] else ...[
        const Text(
          'Cosmetic only. Choose a free tile outside roads and buildings, then review before spending gems. Moving is free.',
        ),
        for (final kind in DecorationKind.values)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: GameColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      kind.artwork,
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${kind.label} · ${kind.price} gems')),
                  ],
                ),
                GameButton(
                  label: 'Place ${kind.label.toLowerCase()}',
                  onPressed:
                      game.gems < kind.price || onChooseDecoration == null
                      ? null
                      : () => onChooseDecoration!(kind),
                ),
              ],
            ),
          ),
        if (game.decorations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Placed decorations',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          for (var index = 0; index < game.decorations.length; index++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${game.decorations[index].kind.label} · ${game.decorations[index].cell.key}',
              ),
              trailing: TextButton(
                onPressed: onMoveDecoration == null
                    ? null
                    : () => onMoveDecoration!(index),
                child: const Text('Move'),
              ),
            ),
        ],
      ],
    ],
  );
}
