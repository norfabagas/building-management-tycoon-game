import 'package:flutter/material.dart';

import '../../domain/district_game.dart';
import '../../shared/widgets/game_button.dart';
import 'district_view_model.dart';

class AccelerationButton extends StatelessWidget {
  const AccelerationButton({
    super.key,
    required this.model,
    required this.building,
  });
  final DistrictViewModel model;
  final ApartmentBuilding building;
  @override
  Widget build(BuildContext context) {
    if (building.rushed || building.upgrade?.rushed == true) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Accelerated work activates next Morning.'),
      );
    }
    final cost = DistrictProgression.accelerationCost(model.game!, building);
    if (cost == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameButton(
            label: 'Accelerate · $cost ${cost == 1 ? 'gem' : 'gems'}',
            secondary: true,
            onPressed:
                model.busy || model.error != null || model.game!.gems < cost
                ? null
                : () async {
                    final job =
                        building.upgrade?.kind.label ??
                        (building.stage == ConstructionStage.shell
                            ? '${building.type.label} shell'
                            : 'B1 parking');
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Accelerate active job'),
                        content: Text(
                          '$job in ${building.name}\nPrice: $cost gems\n\nThis job completes next Morning. Remaining jobs still run separately. New buildings still require Open to Business.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Confirm acceleration'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await model.save(
                        (state) => DistrictProgression.accelerate(
                          state,
                          building.id,
                          quotedCost: cost,
                        ),
                      );
                    }
                  },
          ),
          if (model.game!.gems < cost)
            const Text('Earn more gems through achievements.'),
        ],
      ),
    );
  }
}
