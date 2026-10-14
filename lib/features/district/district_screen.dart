import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
  int? get _selected => _model.selectedBuildingId;
  set _selected(int? id) => _model.selectBuilding(id);
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
              final activePanel = _buildMenu || _finance;
              return Padding(
                // Keep floor controls above the hosted Web footer badge.
                padding: EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  _selected != null && kIsWeb ? 64 : 12,
                ),
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Offstage(
                            offstage: _selected != null,
                            child: sidePanel
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                          if (_selected != null) _floorView(game),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selected != null)
                      _floorNavigation()
                    else
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
    elapsedMilliseconds: _model.elapsedMilliseconds,
    drawing: _drawing && !_review && _model.error == null,
    preview: _preview,
    selected: _selected,
    reset: _reset,
    onFootprint: (site) => setState(() => _preview = site),
    onCancelFootprint: () => setState(() => _preview = null),
    onSelect: (id) => setState(() {
      _selected = id;
      _buildMenu = false;
      _drawing = false;
      _preview = null;
      _finance = false;
    }),
  );

  Widget _floorNavigation() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        liveRegion: true,
        child: Text(
          'Current floor: ${_model.floorLabel}',
          key: const ValueKey('current-floor'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: GameButton(
              label: 'Exit building',
              secondary: true,
              onPressed: _closePanel,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GameButton(
              label: 'Go up',
              onPressed: _model.canGoUp ? _model.goUp : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GameButton(
              label: 'Go down',
              onPressed: _model.canGoDown ? _model.goDown : null,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _floorView(DistrictGame game) => Material(
    key: const ValueKey('building-floor-view'),
    color: GameColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: GameColors.border, width: 2),
      borderRadius: BorderRadius.circular(18),
    ),
    child: SingleChildScrollView(
      key: ValueKey('floor-$_selected-${_model.currentFloor}'),
      padding: const EdgeInsets.all(16),
      child: _buildingPanel(game),
    ),
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
        'Tap Build and drag to select land. Open completed buildings to welcome tenants.',
      ),
      const SizedBox(height: 12),
      const Text(
        'Rent: weekly. Parking: daily. One game day takes 25 seconds.',
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
          subtitle: Text(
            building.stage == ConstructionStage.ready
                ? building.stage.label
                : '${building.stage.label} · ${(_model.constructionProgress(building) * 100).floor()}%',
          ),
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
            'Coming soon.',
            style: TextStyle(color: GameColors.muted, fontSize: 14),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            _review ? 'Building size cannot be changed later.' : 'Drag to select land. Green: available. Red: blocked or too expensive.',
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
            'Construction: 2 game days, plus 1 for parking.',
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
        _line('Next rent', 'Sunday · Day ${game.nextSunday}'),
        const SizedBox(height: 8),
        const Text(
          'Rent is collected on Sundays.',
          style: TextStyle(color: GameColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Text(
          closing == null ? 'No transactions yet' : 'Day ${closing.day} totals',
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
        _line('Total earned', formatMoney(game.earned)),
        if (_model.returnSummary case final summary?) ...[
          const Divider(),
          Text(summary),
        ],
        const SizedBox(height: 10),
        const Text(
          'Phases change every 5 seconds. Your district keeps running while you are away.',
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
        if (!ready) ...[
          const SizedBox(height: 12),
          _constructionProgress(building),
          if (building.stage == ConstructionStage.parkingDone) ...[
            const SizedBox(height: 12),
            GameButton(
              label: 'Open to Business',
              onPressed: _model.busy || _model.error != null
                  ? null
                  : () => unawaited(_model.openBusiness(building.id)),
            ),
          ],
        ],
        const SizedBox(height: 10),
        _line(
          'Permanent footprint',
          '${building.footprint.width} × ${building.footprint.length} tiles',
        ),
        if (!ready) ...[
          const SizedBox(height: 10),
          Text(switch (building.stage) {
            ConstructionStage.reserved =>
              'Construction queued. Funds are reserved.',
            ConstructionStage.paid => 'Paid. Construction starts tomorrow.',
            ConstructionStage.shell =>
              'Building apartments · Days ${building.startedDay}–${building.startedDay + 1}.',
            ConstructionStage.shellDone =>
              'Apartments complete. Parking starts tomorrow.',
            ConstructionStage.basement =>
              'Building parking · Day ${building.startedDay}.',
            ConstructionStage.parkingDone =>
              'Construction complete. Ready to open.',
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
        ],
        if (_model.currentFloor == 1) ...[
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
          _line(
            'Tenants',
            '${building.occupied.length} / ${building.footprint.rooms} rooms',
          ),
          _line('Pending weekly rent', formatMoney(building.pendingRent)),
          _line('Weekly rent per room', formatMoney(StarterCatalog.weeklyRent)),
          if (ready)
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = math.max(
                  1,
                  (constraints.maxWidth / 300).floor(),
                );
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var room = 0; room < building.footprint.rooms; room++)
                      SizedBox(width: width, child: _room(building, room)),
                  ],
                );
              },
            )
          else
            const Text(
              'Open the building after construction to welcome tenants.',
            ),
          const SizedBox(height: 16),
          Image.asset(
            ProductionAssets.transportStairs,
            height: 90,
            excludeFromSemantics: true,
          ),
          Text(
            building.parkingComplete
                ? 'Go down for parking.'
                : 'Parking not ready.',
          ),
        ] else ...[
          const Divider(),
          const Text(
            'B1 · Parking only',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Image.asset(
            building.occupied.isEmpty
                ? ProductionAssets.transportParkingEmpty
                : ProductionAssets.transportParkingOccupied,
            height: 220,
            width: double.infinity,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          _line('Parking capacity', '${building.footprint.bays} bays'),
          _line('Tenant bays used', '${building.occupied.length}'),
          _line(
            'Available bays',
            '${building.footprint.bays - building.occupied.length}',
          ),
          const Text(
            'Parking is reserved for tenants.',
            style: TextStyle(fontSize: 13, color: GameColors.muted),
          ),
        ],
        const SizedBox(height: 14),
        const Text(
          'Building upgrades coming soon.',
          style: TextStyle(fontSize: 13, color: GameColors.muted),
        ),
      ],
    );
  }

  Widget _constructionProgress(ApartmentBuilding building) {
    final progress = _model.constructionProgress(building);
    final percent = (progress * 100).floor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Construction · $percent%',
          key: const ValueKey('construction-percent'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          key: const ValueKey('construction-progress'),
          value: progress,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
          semanticsLabel: 'Construction progress',
          semanticsValue: '$percent%',
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
                      occupied ? 'Occupied · 1 bay' : 'Vacant',
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
          'Remove this tenant? Uncollected rent is kept. A new tenant can move in tomorrow.',
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
