import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../domain/district_game.dart';
import '../../shared/widgets/asset_animation.dart';
import '../../shared/widgets/game_button.dart';
import 'building_presentation.dart';
import 'district_view_model.dart';
import 'tenant_activity_view_model.dart';

/// A game-styled review page, kept in the unit's navigation stack.
class TenantManagementScreen extends StatefulWidget {
  const TenantManagementScreen({
    super.key,
    required this.model,
    required this.buildingId,
    required this.unit,
  });
  final DistrictViewModel model;
  final int buildingId, unit;
  @override
  State<TenantManagementScreen> createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends State<TenantManagementScreen> {
  bool _submitting = false;

  Future<void> _release() async {
    if (_submitting || widget.model.busy) return;
    setState(() => _submitting = true);
    final success = await widget.model.save(
      (state) =>
          DistrictSimulation.vacate(state, widget.buildingId, widget.unit),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.model,
    builder: (context, _) {
      final building = widget.model.game?.buildings
          .where((b) => b.id == widget.buildingId)
          .firstOrNull;
      final view = building == null
          ? null
          : TenantActivityViewModel(widget.model.game!, building, widget.unit);
      final available =
          view != null &&
          !view.isFoodCourt &&
          widget.unit >= 0 &&
          widget.unit < view.building.rooms &&
          view.building.stage == ConstructionStage.ready;
      final occupied = available && view.active;
      final blocked = _submitting || widget.model.busy;
      return PopScope(
        canPop: !_submitting,
        child: Scaffold(
          key: const ValueKey('tenant-management-page'),
          backgroundColor: GameColors.canvas,
          appBar: AppBar(
            leading: BackButton(
              onPressed: _submitting ? null : () => Navigator.pop(context),
            ),
            title: const Text(
              'Tenant management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, kIsWeb ? 64 : 16),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final keep = GameButton(
                        label: occupied ? 'Keep tenant' : 'Back to interior',
                        secondary: true,
                        onPressed: _submitting
                            ? null
                            : () => Navigator.pop(context),
                      );
                      final release = occupied
                          ? _ReleaseButton(
                              label: _submitting
                                  ? 'Releasing…'
                                  : widget.model.error != null
                                  ? 'Retry release'
                                  : switch (building!.type) {
                                      BuildingType.hotel => 'Check out guest',
                                      BuildingType.office => 'End floor lease',
                                      _ => 'Vacate room',
                                    },
                              busy: _submitting,
                              onPressed: blocked ? null : _release,
                            )
                          : null;
                      if (constraints.maxWidth < 560 &&
                          !(constraints.maxWidth >= 480 &&
                              MediaQuery.sizeOf(context).height < 450)) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (release != null) ...[
                              release,
                              const SizedBox(height: 10),
                            ],
                            keep,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          if (constraints.maxWidth >= 760) ...[
                            Expanded(
                              child: Text(
                                available
                                    ? '${building!.name} · ${view.title}'
                                    : 'Unit unavailable',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: GameColors.muted),
                              ),
                            ),
                            const SizedBox(width: 20),
                          ],
                          Expanded(child: keep),
                          if (release != null) ...[
                            const SizedBox(width: 12),
                            Expanded(child: release),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: !available
                ? const Center(
                    child: Text(
                      'This unit is no longer available. Return to the building.',
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final previews = _UnitPreviews(view: view);
                      final review = _ReleaseReview(
                        view: view,
                        model: widget.model,
                      );
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1160),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Text(
                                      '${building!.name} · Floor ${view.floor}',
                                      style: const TextStyle(
                                        color: GameColors.muted,
                                      ),
                                    ),
                                    Text(
                                      'Day ${widget.model.game!.day} · ${widget.model.clockLabel}',
                                      style: const TextStyle(
                                        color: GameColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  occupied
                                      ? switch (building.type) {
                                          BuildingType.hotel =>
                                            'Check out this guest',
                                          BuildingType.office =>
                                            'Release this floor lease',
                                          _ => 'Set this room vacant',
                                        }
                                      : 'This unit is already vacant',
                                  style: TextStyle(
                                    fontSize: constraints.maxWidth < 560
                                        ? 26
                                        : 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  view.title,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 22),
                                if (constraints.maxWidth >= 820)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: previews),
                                      const SizedBox(width: 24),
                                      Expanded(flex: 2, child: review),
                                    ],
                                  )
                                else ...[
                                  previews,
                                  const SizedBox(height: 20),
                                  review,
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      );
    },
  );
}

class _UnitPreviews extends StatelessWidget {
  const _UnitPreviews({required this.view});
  final TenantActivityViewModel view;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GameColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GameColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(color: GameColors.border, offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.home_work_outlined, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Current unit',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusPill(occupied: view.active),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AspectRatio(
                  aspectRatio: 10 / 7,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          view.active
                              ? view.building.type.roomArtwork
                              : view.building.type.vacantArtwork,
                          key: const ValueKey('management-current-art'),
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                      if (view.showPeople)
                        Positioned(
                          right: 32,
                          bottom: 14,
                          child: AssetAnimation(
                            path: view.building.type.actor,
                            width: 52,
                            height: 78,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GameColors.mint.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GameColors.border),
        ),
        child: Row(
          children: [
            Image.asset(
              view.building.type.vacantArtwork,
              key: const ValueKey('management-vacant-art'),
              width: 94,
              height: 66,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.active ? 'After release' : 'Available unit',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vacant',
                    style: TextStyle(
                      color: GameColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    view.building.type == BuildingType.office
                        ? 'The whole floor becomes available.'
                        : 'The room becomes available.',
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              color: GameColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.occupied});
  final bool occupied;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: occupied ? GameColors.mint : GameColors.canvas,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      occupied ? 'Occupied' : 'Vacant',
      style: const TextStyle(
        color: GameColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ReleaseReview extends StatelessWidget {
  const _ReleaseReview({required this.view, required this.model});
  final TenantActivityViewModel view;
  final DistrictViewModel model;
  @override
  Widget build(BuildContext context) {
    final building = view.building;
    final bays = view.active
        ? building.type.baysPerUnit(building.footprint.tiles)
        : 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameColors.surface,
        border: Border.all(color: GameColors.border, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Release summary',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review the change before confirming.',
            style: TextStyle(color: GameColors.muted),
          ),
          const Divider(height: 28),
          _Impact(
            icon: Icons.local_parking,
            title:
                '$bays ${bays == 1 ? 'parking bay' : 'parking bays'} released',
            detail:
                'Parking: $bays reserved ${building.type == BuildingType.office ? 'bays' : 'bay'}',
          ),
          _Impact(
            icon: Icons.receipt_long_outlined,
            title: building.type == BuildingType.apartment
                ? 'Earned rent is kept'
                : 'No release charge',
            detail: switch (building.type) {
              BuildingType.apartment =>
                'Building uncollected rent: ${formatMoney(building.pendingRent)}. Already accrued rent remains payable on Sunday.',
              BuildingType.hotel =>
                'Daily base rate: ${formatMoney(16000)}. Room income follows occupancy at the daily closing.',
              _ =>
                'Daily base lease: ${formatMoney(18000 * building.footprint.tiles)}. Lease income follows occupancy at the daily closing.',
            },
          ),
          _Impact(
            icon: Icons.wb_sunny_outlined,
            title: 'Next admission: Morning',
            detail:
                'A new ${building.type == BuildingType.hotel ? 'guest' : 'tenant'} can arrive within demand and parking limits.',
          ),
          const Divider(height: 16),
          Text(
            'Happiness: ${building.happiness} / 100',
            style: const TextStyle(color: GameColors.muted, fontSize: 12),
          ),
          if (model.error != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                model.error!,
                style: const TextStyle(color: GameColors.danger),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: model.busy ? null : () => model.save(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh unit'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Impact extends StatelessWidget {
  const _Impact({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title, detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: GameColors.mint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: GameColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(color: GameColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReleaseButton extends StatelessWidget {
  const _ReleaseButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: onPressed == null
          ? null
          : const [BoxShadow(color: GameColors.ink, offset: Offset(0, 4))],
    ),
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: GameColors.danger,
        foregroundColor: GameColors.surface,
        disabledBackgroundColor: GameColors.border,
        minimumSize: const Size(120, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: GameColors.ink, width: 2),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: GameColors.surface,
              ),
            )
          : const Icon(Icons.logout),
      label: Text(label),
    ),
  );
}
