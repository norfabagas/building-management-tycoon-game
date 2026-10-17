import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../domain/district_game.dart';
import '../../shared/widgets/asset_animation.dart';
import 'building_presentation.dart';
import 'district_view_model.dart';
import 'tenant_activity_view_model.dart';

/// An opaque route keeps the building/floor and map camera intact underneath.
class TenantActivityScreen extends StatelessWidget {
  const TenantActivityScreen({
    super.key,
    required this.model,
    required this.buildingId,
    required this.unit,
    required this.onManage,
  });
  final DistrictViewModel model;
  final int buildingId, unit;
  final Future<void> Function() onManage;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: model,
    builder: (context, _) {
      final building = model.game?.buildings
          .where((b) => b.id == buildingId)
          .firstOrNull;
      if (building == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Unit unavailable')),
          body: const Center(
            child: Text('Return to the district to continue.'),
          ),
        );
      }
      final view = TenantActivityViewModel(model.game!, building, unit);
      return Scaffold(
        key: const ValueKey('tenant-fullscreen'),
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.pop(context)),
          title: Text(
            view.title,
            style: const TextStyle(fontSize: 18),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (!view.isFoodCourt)
              TextButton.icon(
                onPressed: !view.active || model.busy || model.error != null
                    ? null
                    : onManage,
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Manage'),
              ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final scene = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Text(
                        '${building.name} · Floor ${view.floor}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Day ${model.game!.day} · ${model.clockLabel} · ${model.game!.phase.label}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxHeight < 450
                            ? math.max(180, constraints.maxHeight - 110) *
                                  10 /
                                  7
                            : double.infinity,
                      ),
                      child: _InteriorScene(view: view),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        view.active
                            ? view.current.icon
                            : Icons.person_off_outlined,
                        color: GameColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              view.active
                                  ? view.current.label
                                  : 'Waiting for occupants',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              view.active
                                  ? view.current.zone
                                  : view.emptyMessage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'A day inside',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < view.activities.length; i++)
                        _ActivityCard(
                          activity: view.activities[i],
                          index: i,
                          selected: view.active && i == view.phase,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Daily routines illustrate the time of day. Occupancy and finances below follow your saved game.',
                    style: TextStyle(color: GameColors.muted, fontSize: 12),
                  ),
                ],
              );
              final details = _UnitDetails(view: view, model: model);
              return SingleChildScrollView(
                key: const PageStorageKey('tenant-activity-scroll'),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 76),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: scene),
                              const SizedBox(width: 24),
                              Expanded(child: details),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              scene,
                              const SizedBox(height: 24),
                              details,
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.index,
    required this.selected,
  });
  final InteriorActivity activity;
  final int index;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    width: 164,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: selected ? GameColors.mint : Colors.white,
      border: Border.all(
        color: selected ? GameColors.primary : GameColors.border,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(activity.icon, size: 20),
            const Spacer(),
            if (selected)
              const Text(
                'NOW',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${(index * 6).toString().padLeft(2, '0')}:00–${((index + 1) * 6).toString().padLeft(2, '0')}:00',
          style: const TextStyle(fontSize: 12, color: GameColors.muted),
        ),
        Text(activity.label),
      ],
    ),
  );
}

class _UnitDetails extends StatelessWidget {
  const _UnitDetails({required this.view, required this.model});
  final TenantActivityViewModel view;
  final DistrictViewModel model;
  @override
  Widget build(BuildContext context) {
    final building = view.building;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GameColors.surface,
        border: Border.all(color: GameColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            view.isFoodCourt ? 'Floor activity' : 'Unit status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(view.status),
          const Divider(height: 28),
          if (view.isFoodCourt) ...[
            const Text(
              'Building totals',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('Visits today: ${building.visitsToday} parties'),
            Text(
              'Sales awaiting midnight: ${formatMoney(building.salesToday)}',
            ),
            Text(
              'Visitor parking awaiting midnight: ${formatMoney(building.parkingToday)}',
            ),
            const SizedBox(height: 12),
            const Text(
              'Parties turn over every six hours. Sales and parking settle at 24:00.',
            ),
          ] else ...[
            Text(
              'Parking: ${view.active ? building.type.baysPerUnit(building.footprint.tiles) : 0} reserved ${building.type == BuildingType.office ? 'bays' : 'bay'}',
            ),
            Text('Happiness: ${building.happiness} / 100'),
            const SizedBox(height: 12),
            Text(switch (building.type) {
              BuildingType.apartment =>
                'Weekly room rent: ${formatMoney(StarterCatalog.weeklyRent)}',
              BuildingType.hotel => 'Daily base rate: ${formatMoney(16000)}',
              BuildingType.office =>
                'Daily base lease: ${formatMoney(18000 * building.footprint.tiles)}',
              BuildingType.foodCourt => '',
            }),
            Text(switch (building.type) {
              BuildingType.apartment => 'Rent accrues for occupied days and is paid Sunday at 24:00. Departed tenants keep their earned rent in the building ledger.',
              BuildingType.hotel => 'Guests refresh next Morning. Daily room income settles at 24:00.',
              _ => 'This tenant leases the whole floor. Daily lease income settles at 24:00.',
            }),
            if (building.type == BuildingType.apartment) ...[
              const Divider(height: 28),
              Text(
                'Building uncollected rent: ${formatMoney(building.pendingRent)}',
              ),
            ],
          ],
          const SizedBox(height: 12),
          Text(
            'Building parking: ${building.usedBays} / ${building.bays} bays',
          ),
          Text(
            'Luxury level ${building.luxury} · ${building.standardLifts} standard lifts · ${building.executiveLifts} executive lifts',
          ),
          if (model.error != null) ...[
            const Divider(height: 28),
            Text(
              model.error!,
              style: const TextStyle(color: GameColors.danger),
            ),
            TextButton(
              onPressed: model.busy ? null : () => model.save(),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InteriorScene extends StatefulWidget {
  const _InteriorScene({required this.view});
  final TenantActivityViewModel view;
  @override
  State<_InteriorScene> createState() => _InteriorSceneState();
}

class _InteriorSceneState extends State<_InteriorScene>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = .5;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: ColoredBox(
      color: widget.view.building.type.color.withValues(alpha: .16),
      child: AspectRatio(
        aspectRatio: 10 / 7,
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final view = widget.view;
              final width = constraints.maxWidth,
                  height = constraints.maxHeight;
              final t = _motion.value;
              final walking = t < .25 || t > .75;
              final position = t < .25
                  ? t * 4
                  : t > .75
                  ? (1 - t) * 4
                  : 1.0;
              final x =
                  .12 +
                  (view.current.x - .12) * Curves.easeInOut.transform(position);
              return Semantics(
                label: view.active
                    ? '${view.current.label} in ${view.current.zone}'
                    : 'Unoccupied interior',
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        key: const ValueKey('tenant-interior-art'),
                        !view.isFoodCourt && !view.active
                            ? view.building.type.vacantArtwork
                            : view.building.type.roomArtwork,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                    if (view.showPeople)
                      for (
                        var i = 0;
                        i < (view.isFoodCourt ? math.min(3, view.visitors) : 1);
                        i++
                      )
                        Positioned(
                          left:
                              width * (i == 0 ? x : .20 + i * .17) -
                              width * .085,
                          bottom: height * .085,
                          child: Transform.flip(
                            flipX: i == 0 && t > .75,
                            child: AssetAnimation(
                              path: view.building.type.actor,
                              sequence: i == 0 && walking ? 'walk' : 'idle',
                              width: width * .17,
                              height: width * .255,
                            ),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
