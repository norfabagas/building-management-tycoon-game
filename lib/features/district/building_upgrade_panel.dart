import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../app/production_assets.dart';
import '../../domain/district_game.dart';
import '../../shared/widgets/game_button.dart';
import 'district_view_model.dart';
import 'building_presentation.dart';
import 'acceleration_button.dart';

class BuildingUpgradePanel extends StatelessWidget {
  const BuildingUpgradePanel({
    super.key,
    required this.model,
    required this.building,
    required this.onClose,
  });
  final DistrictViewModel model;
  final ApartmentBuilding building;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton.icon(
        onPressed: onClose,
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to floors'),
      ),
      Text(
        '${building.name} · Upgrades',
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text('Add one level or lift at a time. Your building stays open.'),
      if (building.stage != ConstructionStage.ready) ...[
        const SizedBox(height: 12),
        const Text('Open the building before upgrading.'),
      ],
      if (building.upgrade case final order?) ...[
        const SizedBox(height: 16),
        Text(
          '${order.kind.label} · ${order.stage.label}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: model.upgradeProgress(building),
          minHeight: 12,
          semanticsLabel: 'Upgrade progress',
          semanticsValue: '${(model.upgradeProgress(building) * 100).floor()}%',
        ),
        const SizedBox(height: 6),
        Text('${(model.upgradeProgress(building) * 100).floor()}%'),
        Text('Full refund: ${formatMoney(order.kind.cost(building))}'),
        TextButton(
          onPressed: model.busy || model.error != null
              ? null
              : () => unawaited(model.cancelUpgrade(building.id)),
          child: const Text('Cancel upgrade'),
        ),
      ],
      const SizedBox(height: 16),
      AccelerationButton(model: model, building: building),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 660 ? 2 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final kind in BuildingUpgrade.values)
                SizedBox(width: width, child: _card(context, kind)),
            ],
          );
        },
      ),
    ],
  );

  Widget _card(BuildContext context, BuildingUpgrade kind) {
    final count = kind.count(building);
    final maximum = count >= kind.maximum;
    final error = DistrictSimulation.upgradeError(model.game!, building, kind);
    final benefit = switch (kind) {
      BuildingUpgrade.floor =>
        'Floor ${count + 1} · +${building.unitsPerFloor} ${building.type.unitLabel}',
      BuildingUpgrade.basement =>
        'B${count + 1} · +${building.footprint.bays} parking bays',
      BuildingUpgrade.standardLift => 'Standard lift ${count + 1}',
      BuildingUpgrade.executiveLift => 'Executive lift',
      BuildingUpgrade.luxury => 'Tier ${count + 1} · +15% new rent/sales',
    };
    final asset = switch (kind) {
      BuildingUpgrade.floor => building.type.roomArtwork,
      BuildingUpgrade.basement => ProductionAssets.transportParkingEmpty,
      BuildingUpgrade.standardLift => ProductionAssets.transportStandardLift,
      BuildingUpgrade.executiveLift => ProductionAssets.transportExecutiveLift,
      BuildingUpgrade.luxury => building.type.luxuryArtwork(
        (count + 1).clamp(1, 3),
      ),
    };
    return Container(
      key: ValueKey('upgrade-${kind.name}'),
      padding: const EdgeInsets.all(16),
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
                asset,
                width: 70,
                height: 65,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$count / ${kind.maximum}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!maximum) ...[
            Text(benefit),
            const SizedBox(height: 6),
            Text(
              '${formatMoney(kind.cost(building))} · ${kind.duration(building)} game ${kind.duration(building) == 1 ? 'day' : 'days'}',
            ),
            Text(
              '+${formatMoney(kind.addedMaintenance(building))} upkeep / day',
            ),
            const SizedBox(height: 8),
          ],
          if (kind == BuildingUpgrade.standardLift ||
              kind == BuildingUpgrade.executiveLift)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Improves vertical access and new demand in tall buildings.',
                style: TextStyle(fontSize: 13, color: GameColors.muted),
              ),
            ),
          if (!maximum && error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                error,
                style: const TextStyle(fontSize: 13, color: GameColors.muted),
              ),
            ),
          GameButton(
            label: maximum ? 'Maximum reached' : 'Review upgrade',
            onPressed: model.busy || model.error != null || error != null
                ? null
                : () => unawaited(_review(context, kind, benefit)),
          ),
        ],
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    BuildingUpgrade kind,
    String benefit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(kind.label),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(benefit),
              const SizedBox(height: 12),
              Text('Price: ${formatMoney(kind.cost(building))}'),
              Text(
                'Added upkeep: ${formatMoney(kind.addedMaintenance(building))} / day',
              ),
              Text(
                'Construction: ${kind.duration(building)} game ${kind.duration(building) == 1 ? 'day' : 'days'}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Charged immediately. Cancel before completion for a full refund.',
              ),
              if (kind == BuildingUpgrade.floor)
                const Text('New tenants still need a free parking bay.'),
              if (kind == BuildingUpgrade.standardLift ||
                  kind == BuildingUpgrade.executiveLift)
                const Text(
                  'Lift price uses the original one-floor + B1 quote. Each lift reduces the vertical-access demand penalty by 10 points.',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm upgrade'),
          ),
        ],
      ),
    );
    if (confirmed == true && !model.busy) {
      await model.orderUpgrade(building.id, kind);
    }
  }
}
