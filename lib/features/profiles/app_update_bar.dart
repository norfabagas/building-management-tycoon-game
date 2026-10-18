import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../shared/widgets/game_button.dart';
import 'app_update_view_model.dart';

class AppUpdateBar extends StatelessWidget {
  const AppUpdateBar({super.key, required this.model});
  final AppUpdateViewModel model;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: model,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Version ${model.currentVersion} UTC',
                  style: const TextStyle(fontSize: 12, color: GameColors.muted),
                ),
              ),
              if (model.checking)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (model.needsSync) ...[
                const SizedBox(width: 8),
                GameButton(
                  label: model.syncing ? 'Syncing…' : 'Sync',
                  compact: true,
                  onPressed: model.syncing || model.checking
                      ? null
                      : model.sync,
                ),
              ],
            ],
          ),
          if (model.needsSync)
            Text(
              'New version ${model.latestVersion} UTC',
              style: const TextStyle(fontSize: 12, color: GameColors.primary),
            ),
          if (model.message case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message,
                style: const TextStyle(fontSize: 12, color: GameColors.muted),
              ),
            ),
        ],
      ),
    ),
  );
}
