import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../app/production_assets.dart';
import '../../data/game_repository.dart';
import '../../domain/district_game.dart';
import '../../domain/local_profile.dart';
import '../../shared/widgets/asset_animation.dart';
import '../../shared/widgets/game_brand.dart';
import '../../shared/widgets/game_button.dart';
import 'district_map.dart';
import 'district_view_model.dart';

class DistrictScreen extends StatefulWidget {
  const DistrictScreen({
    super.key,
    required this.profile,
    required this.repository,
  });
  final LocalProfile profile;
  final GameRepository repository;
  @override
  State<DistrictScreen> createState() => _DistrictScreenState();
}

class _DistrictScreenState extends State<DistrictScreen>
    with WidgetsBindingObserver {
  late final DistrictViewModel _model = DistrictViewModel(
    widget.profile,
    widget.repository,
  );
  bool _buildMenu = false, _drawing = false, _review = false, _finance = false;
  Footprint? _preview;
  int? _selected;
  int _reset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_model.load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      unawaited(_model.save());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.dispose();
    super.dispose();
  }

  void _chooseBuild() => setState(() {
    _buildMenu = true;
    _drawing = false;
    _review = false;
    _finance = false;
    _selected = null;
    _preview = null;
  });
  void _closePanel() => setState(() {
    _buildMenu = false;
    _drawing = false;
    _review = false;
    _finance = false;
    _selected = null;
    _preview = null;
  });
  Future<void> _confirm() async {
    final site = _preview;
    if (site == null) return;
    final success = await _model.save(
      (state) => DistrictSimulation.place(state, site),
    );
    if (success && mounted) {
      setState(() {
        _selected = _model.game!.buildings.last.id;
        _buildMenu = false;
        _drawing = false;
        _review = false;
        _preview = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 52,
      title: const GameBrand(size: 30, fontSize: 16),
    ),
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _model,
        builder: (context, _) {
          final game = _model.game;
          if (game == null) {
            return Center(
              child: _model.error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_model.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          GameButton(
                            label: 'Retry',
                            onPressed: _model.busy
                                ? null
                                : () => unawaited(_model.load()),
                          ),
                        ],
                      ),
                    ),
            );
          }
          final blocked = _model.busy || _model.error != null;
          return LayoutBuilder(
            builder: (context, constraints) {
              final sidePanel = constraints.maxWidth >= 700;
              final smallHeight = constraints.maxHeight < 450;
              final activePanel = _buildMenu || _selected != null || _finance;
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.profile.areaName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: smallHeight ? 20 : 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${game.weekdayLabel} · ${game.phase.label}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _stat(
                          ProductionAssets.iconsDollar,
                          'Dollars',
                          formatMoney(game.balance),
                        ),
                        _stat(
                          ProductionAssets.iconsBuild,
                          'Available',
                          formatMoney(game.available),
                        ),
                        _stat(
                          ProductionAssets.iconsSunday,
                          'Pending rent',
                          formatMoney(game.pendingRent),
                        ),
                        _stat(
                          ProductionAssets.iconsClock,
                          'Day ${game.day}',
                          '${_model.secondsRemaining}s to next phase',
                        ),
                      ],
                    ),
                    if (_model.error case final error?)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                error,
                                style: const TextStyle(
                                  color: GameColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _model.busy
                                  ? null
                                  : () => unawaited(_model.save()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: sidePanel
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _map(game)),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: constraints.maxWidth >= 1100
                                      ? 340
                                      : 280,
                                  child: _panel(game),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(child: _map(game)),
                                if (activePanel) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: math.min(
                                      270,
                                      constraints.maxHeight * .42,
                                    ),
                                    child: _panel(game),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GameButton(
                          label: 'Build',
                          onPressed: blocked ? null : _chooseBuild,
                        ),
                        const SizedBox(width: 10),
                        GameButton(
                          label: 'Finances',
                          secondary: true,
                          onPressed: () => setState(() {
                            _finance = true;
                            _buildMenu = false;
                            _drawing = false;
                            _preview = null;
                            _selected = null;
                          }),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Center map',
                          onPressed: () => setState(() => _reset++),
                          icon: const Icon(Icons.center_focus_strong),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    ),
  );

  Widget _map(DistrictGame game) => DistrictMap(
    game: game,
    drawing: _drawing && !_review && !_model.busy && _model.error == null,
    preview: _preview,
    selected: _selected,
    reset: _reset,
    onFootprint: (site) => setState(() => _preview = site),
    onSelect: (id) => setState(() {
      _selected = id;
      _buildMenu = false;
      _drawing = false;
      _preview = null;
      _finance = false;
    }),
  );

  Widget _stat(String asset, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: GameColors.surface,
      border: Border.all(color: GameColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(asset, width: 25, height: 25, excludeFromSemantics: true),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: GameColors.muted),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _panel(DistrictGame game) => Material(
    color: GameColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: GameColors.border, width: 2),
      borderRadius: BorderRadius.circular(18),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _finance
          ? _financePanel(game)
          : _buildMenu
          ? _buildPanel(game)
          : _selected != null
          ? _buildingPanel(game)
          : _welcome(game),
    ),
  );

  Widget _heading(String title) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
      ),
      if (_buildMenu || _finance || _selected != null)
        IconButton(
          tooltip: 'Close panel',
          onPressed: _closePanel,
          icon: const Icon(Icons.close),
        ),
    ],
  );
  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: GameColors.muted, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _welcome(DistrictGame game) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        game.buildings.isEmpty ? 'Your first apartment' : 'Your district',
      ),
      const SizedBox(height: 8),
      Image.asset(
        ProductionAssets.roomsApartment,
        height: 150,
        width: double.infinity,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
      const SizedBox(height: 10),
      const Text(
        'Choose Build, then draw the footprint on the land. Your apartment needs its included B1 parking before tenants can move in.',
      ),
      const SizedBox(height: 12),
      const Text(
        'Apartment rent pays on Sunday at Noon. Parking pays daily. One game day takes five minutes.',
        style: TextStyle(color: GameColors.muted, fontSize: 14),
      ),
      if (_model.returnSummary case final summary?) ...[
        const Divider(),
        Text(summary),
      ],
      const SizedBox(height: 18),
      for (final building in game.buildings)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Apartment ${building.id}'),
          subtitle: Text(building.stage.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => _selected = building.id),
        ),
    ],
  );

  Widget _buildPanel(DistrictGame game) {
    final site = _preview;
    final error = site == null
        ? null
        : DistrictSimulation.placementError(game, site);
    final blocked = _model.busy || _model.error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          !_drawing
              ? 'Choose a building'
              : _review
              ? 'Review apartment'
              : 'Draw your footprint',
        ),
        if (!_drawing) ...[
          const SizedBox(height: 10),
          Image.asset(
            ProductionAssets.buildingsApartment,
            height: 120,
            width: double.infinity,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const Text(
            'Apartment',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('One floor · Default stairs · B1 parking included'),
          const SizedBox(height: 12),
          GameButton(
            label: 'Choose apartment',
            onPressed: blocked ? null : () => setState(() => _drawing = true),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const Text(
            'Hotel, Office and Food court',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Available in a later release after their prices and demand rules are defined.',
            style: TextStyle(color: GameColors.muted, fontSize: 14),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            _review
                ? 'This footprint and above-ground floor count are permanent.'
                : 'Drag across the land. Green is valid; red shows a conflict or an unaffordable plan.',
          ),
          const SizedBox(height: 12),
          _line(
            'Footprint',
            site == null
                ? 'Draw on the map'
                : '${site.width} × ${site.length} tiles',
          ),
          _line('Above-ground floors', '1'),
          _line('Calculated rooms', '${site?.rooms ?? 0}'),
          _line('B1 parking bays', '${site?.bays ?? 0}'),
          _line('Shell · 2 game days', formatMoney(site?.shellCost ?? 0)),
          _line('B1 · 1 game day', formatMoney(site?.basementCost ?? 0)),
          _line('Surrounding road', 'Included · 1 tile wide'),
          const Divider(),
          _line('Total reserved', formatMoney(site?.quote ?? 0)),
          _line('Available dollars', formatMoney(game.available)),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                error,
                style: const TextStyle(color: GameColors.danger),
              ),
            ),
          const SizedBox(height: 12),
          GameButton(
            label: _review ? 'Confirm construction' : 'Review cost',
            onPressed: blocked || site == null || error != null
                ? null
                : _review
                ? () => unawaited(_confirm())
                : () => setState(() => _review = true),
          ),
          if (_review)
            TextButton(
              onPressed: blocked ? null : () => setState(() => _review = false),
              child: const Text('Redraw footprint'),
            ),
          const SizedBox(height: 12),
          const Text(
            'Dollars settle at Noon. Building starts next Morning. Tenant admissions begin after both jobs finish.',
            style: TextStyle(color: GameColors.muted, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _financePanel(DistrictGame game) {
    final closing = game.statement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Finances'),
        _line('Dollars', formatMoney(game.balance)),
        _line('Reserved purchases', formatMoney(game.reserved)),
        _line('Available to spend', formatMoney(game.available)),
        const Divider(),
        _line('Pending apartment rent', formatMoney(game.pendingRent)),
        _line('Next rent payment', 'Sunday · Day ${game.nextSunday} · Noon'),
        const SizedBox(height: 8),
        const Text(
          'Pending rent is earned income. It becomes spendable when collected on Sunday.',
          style: TextStyle(color: GameColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Text(
          closing == null
              ? 'First closing is still ahead'
              : 'Last closing · Day ${closing.day}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (closing != null) ...[
          _line('Apartment rent received', formatMoney(closing.rent)),
          _line('Parking received', formatMoney(closing.parking)),
          _line('Maintenance', formatMoney(-closing.maintenance)),
          _line('Tax', formatMoney(-closing.tax)),
          const Divider(),
          _line('Operating net', formatMoney(closing.net)),
          _line('Purchase payments', formatMoney(-closing.purchases)),
        ],
        const SizedBox(height: 12),
        _line('Cumulative earned revenue', formatMoney(game.earned)),
        if (_model.returnSummary case final summary?) ...[
          const Divider(),
          Text(summary),
        ],
        const SizedBox(height: 10),
        const Text(
          'One minute per phase: Morning → Day → Afternoon → Night → Noon. Missed time is settled when you return.',
          style: TextStyle(fontSize: 13, color: GameColors.muted),
        ),
      ],
    );
  }

  Widget _buildingPanel(DistrictGame game) {
    final matches = game.buildings.where((b) => b.id == _selected);
    if (matches.isEmpty) return _welcome(game);
    final building = matches.first;
    final ready = building.stage == ConstructionStage.ready;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Apartment ${building.id}'),
        Text(
          building.stage.label,
          style: const TextStyle(
            color: GameColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _line(
          'Permanent footprint',
          '${building.footprint.width} × ${building.footprint.length} tiles',
        ),
        _line('Above ground', '1 floor · Stairs'),
        _line(
          'Tenants',
          '${building.occupied.length} / ${building.footprint.rooms} rooms',
        ),
        _line(
          'B1 parking',
          building.parkingComplete
              ? '${building.occupied.length} / ${building.footprint.bays} bays used'
              : 'Waiting for construction',
        ),
        _line('Pending weekly rent', formatMoney(building.pendingRent)),
        _line('Weekly rent per room', formatMoney(StarterCatalog.weeklyRent)),
        if (!ready) ...[
          const SizedBox(height: 10),
          Text(switch (building.stage) {
            ConstructionStage.reserved =>
              'The quote is reserved. Payment happens at the next Noon.',
            ConstructionStage.paid =>
              'Payment is complete. Shell construction starts next Morning.',
            ConstructionStage.shell =>
              'Shell construction: game days ${building.startedDay}–${building.startedDay + 1}. B1 follows next Morning.',
            ConstructionStage.shellDone =>
              'The shell is complete. B1 parking starts next Morning.',
            ConstructionStage.basement =>
              'B1 parking finishes at Noon on Day ${building.startedDay}.',
            ConstructionStage.parkingDone =>
              'Parking is complete. Tenants can arrive next Morning.',
            ConstructionStage.ready => '',
          }),
          if (building.stage == ConstructionStage.reserved) ...[
            const SizedBox(height: 14),
            GameButton(
              label: 'Cancel unpaid order',
              secondary: true,
              onPressed: _model.busy || _model.error != null
                  ? null
                  : () => unawaited(_cancel(building.id)),
            ),
          ],
        ] else ...[
          const Divider(),
          Row(
            children: [
              Image.asset(ProductionAssets.iconsHome, width: 30, height: 30),
              const SizedBox(width: 8),
              const Text(
                'Floor 1 · Rooms',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var room = 0; room < building.footprint.rooms; room++) ...[
            _room(building, room),
            const SizedBox(height: 8),
          ],
          const Divider(),
          Image.asset(
            ProductionAssets.transportParkingEmpty,
            height: 100,
            width: double.infinity,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          _line('B1 · Parking only', '${building.footprint.bays} bays'),
          const Text(
            'Tenant bays are allocated before visitors. Apartments in this release have no visitor traffic.',
            style: TextStyle(fontSize: 13, color: GameColors.muted),
          ),
        ],
        const SizedBox(height: 14),
        const Text(
          'Additional basements, lifts and luxury upgrades are not available in this starter release.',
          style: TextStyle(fontSize: 13, color: GameColors.muted),
        ),
      ],
    );
  }

  Widget _room(ApartmentBuilding building, int room) {
    final occupied = building.occupied.contains(room);
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: GameColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: occupied && !_model.busy && _model.error == null
            ? () => _vacate(building.id, room)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              SizedBox(
                width: 102,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      occupied
                          ? ProductionAssets.roomsApartment
                          : ProductionAssets.roomsApartmentVacantShell,
                      fit: BoxFit.contain,
                    ),
                    if (occupied)
                      const Positioned(
                        right: 8,
                        bottom: 4,
                        child: AssetAnimation(
                          path: ProductionAssets.charactersResidentAnimation,
                          width: 26,
                          height: 39,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room ${room + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      occupied
                          ? 'Occupied · 1 bay'
                          : 'Vacant · Next Morning admission',
                      style: const TextStyle(
                        fontSize: 12,
                        color: GameColors.muted,
                      ),
                    ),
                    if (occupied)
                      const Text(
                        'Tap to manage tenant',
                        style: TextStyle(
                          fontSize: 11,
                          color: GameColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(int id) async {
    if (await _model.save((state) => DistrictSimulation.cancel(state, id)) &&
        mounted) {
      setState(() => _selected = null);
    }
  }

  Future<void> _vacate(int id, int room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Room ${room + 1}'),
        content: const Text(
          'Vacate this room? Already earned rent stays pending until Sunday. A new tenant can arrive at a later Morning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep tenant'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vacate room'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _model.save((state) => DistrictSimulation.vacate(state, id, room));
    }
  }
}
