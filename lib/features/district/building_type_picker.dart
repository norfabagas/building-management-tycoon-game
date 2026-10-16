import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../domain/district_game.dart';
import '../../shared/widgets/game_button.dart';
import 'building_presentation.dart';
import 'district_view_model.dart';

class BuildingTypePicker extends StatelessWidget {
  const BuildingTypePicker({super.key, required this.onChoose});
  final ValueChanged<BuildingType>? onChoose;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1050
          ? 4
          : constraints.maxWidth >= 650
          ? 2
          : 1;
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final type in BuildingType.values)
            Container(
              width: width,
              key: ValueKey('building-type-${type.name}'),
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: type.color, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    type.exterior,
                    width: double.infinity,
                    height: columns == 1 ? 160 : 200,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(type.description),
                    ],
                  ),
                  Text(
                    '${formatMoney(type.shellPerTile)} / tile / floor · ${type.shellDays} days / floor',
                    style: const TextStyle(
                      fontSize: 13,
                      color: GameColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.baseRevenueLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'B1 parking: +\$500 / tile · 1 extra day',
                    style: TextStyle(fontSize: 12, color: GameColors.muted),
                  ),
                  const SizedBox(height: 10),
                  GameButton(
                    label: 'Choose ${type.label.toLowerCase()}',
                    onPressed: onChoose == null ? null : () => onChoose!(type),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
