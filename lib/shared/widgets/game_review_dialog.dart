import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/game_theme.dart';

/// Scroll the review independently from its reachable, keyboard-safe actions.
class GameReviewDialog extends StatelessWidget {
  const GameReviewDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: GameColors.surface,
    insetPadding: EdgeInsets.fromLTRB(12, 12, 12, kIsWeb ? 64 : 12),
    constraints: const BoxConstraints(maxWidth: 560),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: GameColors.ink, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  namesRoute: true,
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                content,
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Stack on narrow phones; keep landscape's short viewport free.
              final stacked =
                  constraints.maxWidth < 380 &&
                  MediaQuery.sizeOf(context).height > 400;
              final buttons = [
                for (final action in actions)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: action,
                  ),
              ];
              return stacked
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < buttons.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          buttons[i],
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        for (var i = 0; i < buttons.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: buttons[i]),
                        ],
                      ],
                    );
            },
          ),
        ),
      ],
    ),
  );
}
