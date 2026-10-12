import 'package:flutter/material.dart';

import '../../app/game_theme.dart';

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: onPressed == null
          ? null
          : const [BoxShadow(color: GameColors.ink, offset: Offset(0, 4))],
    ),
    child: FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(96, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: GameColors.ink, width: 2),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return GameColors.border;
          if (states.contains(WidgetState.pressed)) {
            return secondary ? GameColors.mint : GameColors.pressed;
          }
          return secondary ? GameColors.surface : GameColors.primary;
        }),
        foregroundColor: WidgetStatePropertyAll(
          secondary ? GameColors.ink : GameColors.surface,
        ),
      ),
      child: Text(label),
    ),
  );
}
