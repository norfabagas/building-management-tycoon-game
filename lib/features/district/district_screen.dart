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
import '../../shared/game_audio.dart';
import 'building_upgrade_panel.dart';
import 'district_map.dart';
import 'district_view_model.dart';
import 'building_presentation.dart';
import 'building_type_picker.dart';
import 'district_tools_panel.dart';
import 'acceleration_button.dart';
import 'vertical_transport.dart';
import 'map_camera_view_model.dart';
import 'tenant_activity_screen.dart';
import 'tenant_management_screen.dart';

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
  bool _upgrades = false;
  bool _tenants = false, _districtUpgrades = false;
  BuildingType _buildType = BuildingType.apartment;
  int _initialFloors = 1;
  String? _collection;
  DecorationKind _decorationKind = DecorationKind.tree;
  int? _movingDecoration;
  final _audio = GameAudio();
  final _mapCamera = MapCameraViewModel();
  int? _seenClosing;
  int _cashFeedback = 0;
  int _seenAction = 0;
  Set<String>? _seenJobs;
  bool _audioBusy = false;
  Footprint? _preview;
  int? get _selected => _model.selectedBuildingId;
  set _selected(int? id) {
    _upgrades = false;
    _model.selectBuilding(id);
  }

  int _reset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_model.load());
    _model.addListener(_onGameChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_audio.setEnabled(false));
    }
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      unawaited(_model.save());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.removeListener(_onGameChanged);
    _mapCamera.dispose();
    unawaited(_audio.dispose());
    _model.dispose();
    super.dispose();
  }

  void _chooseBuild() => setState(() {
    _buildMenu = true;
    _drawing = false;
    _review = false;
    _finance = false;
    _tenants = false;
    _districtUpgrades = false;
    _collection = null;
    _selected = null;
    _preview = null;
    _initialFloors = 1;
  });
  void _closePanel() => setState(() {
    _buildMenu = false;
    _drawing = false;
    _review = false;
    _finance = false;
    _tenants = false;
    _districtUpgrades = false;
    _collection = null;
    _selected = null;
    _preview = null;
  });
  Future<void> _confirm() async {
    final site = _preview;
    if (site == null) return;
    final success = await _model.save(
      (state) => DistrictSimulation.place(
        state,
        site,
        type: _buildType,
        floors: _initialFloors,
      ),
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
      actions: [
        AnimatedBuilder(
          animation: _model,
          builder: (context, _) => IconButton(
            tooltip: _audio.enabled
                ? 'Mute sound'
                : _model.game?.soundEnabled == true
                ? 'Resume sound'
                : 'Enable sound',
            onPressed: _model.game == null || _model.busy || _audioBusy
                ? null
                : _toggleSound,
            icon: Icon(_audio.enabled ? Icons.volume_up : Icons.volume_off),
          ),
        ),
      ],
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
              final activePanel =
                  _buildMenu ||
                  _finance ||
                  _tenants ||
                  _districtUpgrades ||
                  _collection != null;
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
                    if (smallHeight && constraints.maxWidth >= 600)
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.profile.areaName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  ' · ${game.weekdayLabel}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          for (final stat in [
                            _stat(
                              ProductionAssets.iconsDollar,
                              'Balance',
                              formatMoney(game.balance),
                              compact: true,
                            ),
                            _stat(
                              ProductionAssets.iconsClock,
                              'Day ${game.day}',
                              _model.clockLabel,
                              compact: true,
                            ),
                            _stat(
                              ProductionAssets.iconsGem,
                              'Gems',
                              '${game.gems}',
                              compact: true,
                            ),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: stat,
                            ),
                        ],
                      )
                    else ...[
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
                            game.weekdayLabel,
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
                            'Balance',
                            formatMoney(game.balance),
                          ),
                          _stat(
                            ProductionAssets.iconsClock,
                            'Day ${game.day}',
                            _model.clockLabel,
                          ),
                          _stat(
                            ProductionAssets.iconsGem,
                            'Gems',
                            '${game.gems}',
                          ),
                        ],
                      ),
                    ],
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
                            offstage:
                                _selected != null || (_buildMenu && !_drawing),
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
                          if (_selected == null && _buildMenu && !_drawing)
                            Material(
                              color: GameColors.surface,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: GameColors.border,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: _buildPanel(game),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selected != null)
                      _floorNavigation()
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          GameButton(
                            label: 'Build',
                            onPressed: blocked ? null : _chooseBuild,
                          ),
                          GameButton(
                            label: 'Tenants',
                            secondary: true,
                            onPressed: () => _showDirectory(tenants: true),
                          ),
                          GameButton(
                            label: 'Upgrades',
                            secondary: true,
                            onPressed: () => _showDirectory(tenants: false),
                          ),
                          GameButton(
                            label: 'Finances',
                            secondary: true,
                            onPressed: () => setState(() {
                              _finance = true;
                              _tenants = false;
                              _districtUpgrades = false;
                              _collection = null;
                              _buildMenu = false;
                              _drawing = false;
                              _preview = null;
                              _selected = null;
                            }),
                          ),
                          IconButton(
                            tooltip: 'Center map',
                            onPressed: () => setState(() => _reset++),
                            icon: const Icon(Icons.center_focus_strong),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'District activities',
                            onSelected: (value) => setState(() {
                              _closePlanning();
                              _tenants = false;
                              _districtUpgrades = false;
                              _collection = value;
                            }),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'Achievements',
                                child: Text('Achievements'),
                              ),
                              PopupMenuItem(
                                value: 'Decorations',
                                child: Text('Decorations'),
                              ),
                            ],
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

  void _onGameChanged() {
    final game = _model.game;
    if (game == null) return;
    String? cue;
    if (_seenClosing != null &&
        game.lastClosing > _seenClosing! &&
        (game.statement?.gross ?? 0) > 0) {
      _cashFeedback++;
      cue = ProductionAssets.audioFinancialClosing;
    }
    _seenClosing = game.lastClosing;
    if (_seenAction != _model.actionFeedback) {
      cue ??= _model.actionSucceeded
          ? ProductionAssets.audioUiConfirm
          : ProductionAssets.audioUiError;
      _seenAction = _model.actionFeedback;
    }
    final jobs = <String>{};
    for (final building in game.buildings) {
      if (building.stage == ConstructionStage.shell ||
          building.stage == ConstructionStage.basement ||
          building.upgrade?.stage == UpgradeStage.building) {
        final job =
            '${building.id}-${building.stage}-${building.startedDay}-${building.upgrade?.kind}-${building.upgrade?.startedDay}';
        jobs.add(job);
        if (_seenJobs != null && !_seenJobs!.contains(job)) {
          cue ??=
              building.stage == ConstructionStage.basement ||
                  building.upgrade?.kind == BuildingUpgrade.basement
              ? ProductionAssets.audioConstructionDrill
              : ProductionAssets.audioConstructionHammer;
        }
      }
    }
    _seenJobs = jobs;
    if (cue != null) {
      unawaited(_audio.effect(cue));
    }
    unawaited(
      _audio.updateMusic(
        game.buildings.where((b) => b.stage == ConstructionStage.ready).length,
      ),
    );
  }

  Future<void> _toggleSound() async {
    if (_audioBusy) return;
    setState(() => _audioBusy = true);
    try {
      final enabled = !_audio.enabled;
      final started = await _audio.setEnabled(
        enabled,
        businesses: _model.game!.buildings
            .where((b) => b.stage == ConstructionStage.ready)
            .length,
      );
      if (!mounted) return;
      if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sound could not start. Tap the sound control to retry.',
            ),
          ),
        );
        return;
      }
      final saved = await _model.save((state) => state.soundEnabled = enabled);
      if (!saved) await _audio.setEnabled(false);
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _audioBusy = false);
    }
  }

  void _showDirectory({required bool tenants}) => setState(() {
    _closePlanning();
    _collection = null;
    _tenants = tenants;
    _districtUpgrades = !tenants;
  });

  void _closePlanning() {
    _buildMenu = false;
    _drawing = false;
    _review = false;
    _finance = false;
    _preview = null;
    _selected = null;
  }

  void _openDirectoryBuilding(int id, {int floor = 1, bool upgrades = false}) =>
      setState(() {
        _upgrades = false;
        _model.selectBuilding(id, floor: floor);
        _upgrades = upgrades;
      });

  Widget _map(DistrictGame game) {
    final ready = game.buildings
        .where((b) => b.stage == ConstructionStage.parkingDone)
        .firstOrNull;
    return TickerMode(
      enabled: _selected == null && !(_buildMenu && !_drawing),
      child: Stack(
        children: [
          Positioned.fill(
            child: DistrictMap(
              camera: _mapCamera,
              game: game,
              elapsedMilliseconds: _model.elapsedMilliseconds,
              drawing: _drawing && !_review && _model.error == null,
              preview: _preview,
              previewValid: _preview == null
                  ? null
                  : _collection == 'Decorations'
                  ? _decorationError(game, _preview!) == null
                  : DistrictSimulation.placementError(
                          game,
                          _preview!,
                          type: _buildType,
                          floors: _initialFloors,
                        ) ==
                        null,
              decorationPreview: _collection == 'Decorations',
              selected: _selected,
              reset: _reset,
              onFootprint: (site) => setState(
                () => _preview = _collection == 'Decorations'
                    ? Footprint(site.x, site.y, 1, 1)
                    : site,
              ),
              onCancelFootprint: () => setState(() => _preview = null),
              onSelect: (id) => setState(() {
                _selected = id;
                _buildMenu = false;
                _drawing = false;
                _preview = null;
                _finance = false;
                _tenants = false;
                _districtUpgrades = false;
                _collection = null;
              }),
            ),
          ),
          if (ready != null && !_drawing && !_buildMenu)
            Positioned(
              left: 12,
              bottom: 12,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: GameButton(
                  label: 'Open ${ready.name}',
                  onPressed: _model.busy || _model.error != null
                      ? null
                      : () => setState(() {
                          _closePlanning();
                          _tenants = false;
                          _districtUpgrades = false;
                          _collection = null;
                          _selected = ready.id;
                        }),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
              onPressed: () => setState(() => _selected = null),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GameButton(
              label: 'Go up',
              onPressed: _model.canGoUp
                  ? () => setState(() {
                      _upgrades = false;
                      _model.goUp();
                    })
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GameButton(
              label: 'Go down',
              onPressed: _model.canGoDown
                  ? () => setState(() {
                      _upgrades = false;
                      _model.goDown();
                    })
                  : null,
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
      key: ValueKey(
        'floor-$_selected-${_model.currentFloor}-$_upgrades-${_model.selectedBuilding?.stage == ConstructionStage.ready}',
      ),
      padding: const EdgeInsets.all(16),
      child: _upgrades && _model.selectedBuilding != null
          ? BuildingUpgradePanel(
              model: _model,
              building: _model.selectedBuilding!,
              onClose: () => setState(() => _upgrades = false),
            )
          : _buildingPanel(game),
    ),
  );

  Widget _stat(
    String asset,
    String label,
    String value, {
    bool compact = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: GameColors.surface,
      border: Border.all(color: GameColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 25,
          height: 25,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                asset,
                width: 25,
                height: 25,
                excludeFromSemantics: true,
              ),
              if (label == 'Balance' &&
                  _cashFeedback > 0 &&
                  !MediaQuery.disableAnimationsOf(context))
                Positioned(
                  left: -4,
                  top: -4,
                  child: AssetAnimation(
                    key: ValueKey('cash-$_cashFeedback'),
                    path: ProductionAssets.effectsCoin,
                    sequence: 'play',
                    width: 32,
                    height: 32,
                    hideWhenComplete: true,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        if (compact)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: GameColors.muted),
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: GameColors.muted),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
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
          : _collection != null
          ? _collectionPanel(game)
          : _tenants || _districtUpgrades
          ? _directoryPanel(game)
          : _buildMenu
          ? _buildPanel(game)
          : _welcome(game),
    ),
  );

  Widget _heading(String title, {Widget? action}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null) Flexible(child: action),
      if (_buildMenu ||
          _finance ||
          _tenants ||
          _districtUpgrades ||
          _collection != null ||
          _selected != null)
        IconButton(
          tooltip: 'Close panel',
          onPressed: _closePanel,
          icon: const Icon(Icons.close),
        ),
    ],
  );

  String? _decorationError(DistrictGame game, Footprint site) =>
      DistrictProgression.decorationError(
        game,
        LandCell(site.x, site.y),
        ignore: _movingDecoration == null
            ? null
            : game.decorations[_movingDecoration!],
      );

  Widget _collectionPanel(DistrictGame game) {
    final blocked = _model.busy || _model.error != null;
    final site = _preview;
    final moving = _movingDecoration != null;
    final error = site == null ? null : _decorationError(game, site);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(_collection!),
        const SizedBox(height: 8),
        if (_collection == 'Decorations' && _drawing) ...[
          Image.asset(
            _decorationKind.artwork,
            height: 100,
            width: 100,
            fit: BoxFit.contain,
          ),
          Text(
            '${moving ? 'Move' : 'Place'} ${_decorationKind.label.toLowerCase()}',
          ),
          const Text('Tap one free land tile on the map.'),
          _line('Tile', site == null ? 'Choose on map' : '${site.x},${site.y}'),
          _line(
            'Price',
            moving ? 'Free move' : '${_decorationKind.price} gems',
          ),
          if (error != null)
            Text(error, style: const TextStyle(color: GameColors.danger)),
          GameButton(
            label: _review ? 'Confirm placement' : 'Review placement',
            onPressed: blocked || site == null || error != null
                ? null
                : () async {
                    if (!_review) {
                      setState(() => _review = true);
                      return;
                    }
                    final success = await _model.save((state) {
                      final cell = LandCell(site.x, site.y);
                      if (moving) {
                        DistrictProgression.moveDecoration(
                          state,
                          _movingDecoration!,
                          cell,
                        );
                      } else {
                        DistrictProgression.placeDecoration(
                          state,
                          _decorationKind,
                          cell,
                        );
                      }
                    });
                    if (success && mounted) {
                      setState(() {
                        _drawing = false;
                        _review = false;
                        _preview = null;
                        _movingDecoration = null;
                      });
                    }
                  },
          ),
          TextButton(
            onPressed: () => setState(() {
              _drawing = false;
              _review = false;
              _preview = null;
              _movingDecoration = null;
            }),
            child: const Text('Cancel placement'),
          ),
        ] else
          DistrictToolsPanel(
            game: game,
            achievements: _collection == 'Achievements',
            onChooseDecoration: blocked
                ? null
                : (kind) => setState(() {
                    _decorationKind = kind;
                    _movingDecoration = null;
                    _drawing = true;
                    _review = false;
                    _preview = null;
                  }),
            onMoveDecoration: blocked
                ? null
                : (index) => setState(() {
                    _movingDecoration = index;
                    _decorationKind = game.decorations[index].kind;
                    _drawing = true;
                    _review = false;
                    _preview = null;
                  }),
          ),
      ],
    );
  }

  Widget _directoryPanel(DistrictGame game) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(_tenants ? 'District tenants' : 'District upgrades'),
      const SizedBox(height: 8),
      Text(
        _tenants
            ? 'Choose a tenant to see inside their unit. Vacancies need a free parking bay before the next Morning admission.'
            : 'Choose a building to review levels, parking and lifts.',
      ),
      const SizedBox(height: 12),
      if (game.buildings.isEmpty)
        const Text('No buildings yet. Use Build to start your district.'),
      for (final building in game.buildings) ...[
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Image.asset(
            building.type.exterior,
            width: 48,
            height: 56,
            excludeFromSemantics: true,
          ),
          title: Text(building.name),
          subtitle: Text(
            _tenants
                ? '${building.type == BuildingType.foodCourt ? building.currentVisitors : building.occupied.length} ${building.type.unitLabel} · ${building.bays} bays'
                : '${building.completedFloors} floors · ${building.completedBasements} basements · ${building.upgrade?.kind.label ?? building.stage.label}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              _openDirectoryBuilding(building.id, upgrades: _districtUpgrades),
        ),
        if (_tenants && building.type == BuildingType.foodCourt)
          ListTile(
            title: Text(
              '${building.currentVisitors} parties visiting · ${building.visitsToday} visits today',
            ),
            subtitle: const Text('View dining activity'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openDirectoryBuilding(building.id);
              _openTenant(building.id, 0);
            },
          ),
        if (_tenants &&
            building.occupied.isEmpty &&
            building.type != BuildingType.foodCourt)
          Text(
            building.stage == ConstructionStage.ready
                ? 'No tenants yet.'
                : 'Open this building after construction to admit tenants.',
          ),
        if (_tenants)
          for (final room in building.occupied.toList()..sort())
            ListTile(
              key: ValueKey('tenant-${building.id}-$room'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(
                '${building.type == BuildingType.office ? 'Lease' : 'Room'} ${room + 1} · ${building.type.role}',
              ),
              subtitle: Text(
                'Floor ${room ~/ building.unitsPerFloor + 1} · ${building.type.baysPerUnit(building.footprint.tiles)} reserved parking bays',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _openDirectoryBuilding(
                  building.id,
                  floor: room ~/ building.unitsPerFloor + 1,
                );
                _openTenant(building.id, room);
              },
            ),
      ],
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: value.startsWith('−') ? GameColors.danger : null,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _welcome(DistrictGame game) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        game.buildings.isEmpty ? 'Your first building' : 'Your district',
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final type in BuildingType.values)
            Expanded(
              child: Image.asset(
                type.exterior,
                height: 100,
                fit: BoxFit.contain,
                semanticLabel: type.label,
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      const Text(
        'Tap Build, choose a type and draw beside the main road or a connected street. Open completed buildings to welcome tenants and visitors.',
      ),
      const SizedBox(height: 12),
      const Text(
        'Apartments pay Sunday; other income pays daily. 1 game hour = 1 second. Close at 24:00.',
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
          title: Text(building.name),
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
        : DistrictSimulation.placementError(
            game,
            site,
            type: _buildType,
            floors: _initialFloors,
          );
    final blocked = _model.busy || _model.error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          !_drawing
              ? 'Choose a building'
              : _review
              ? 'Review ${_buildType.label.toLowerCase()}'
              : 'Draw your footprint',
        ),
        if (!_drawing) ...[
          const Text('1 Type  ›  2 Footprint  ›  3 Floors  ›  4 Review'),
          const SizedBox(height: 10),
          BuildingTypePicker(
            onChoose: blocked
                ? null
                : (type) => setState(() {
                    _buildType = type;
                    _drawing = true;
                  }),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            _review
                ? 'The footprint cannot be changed later. Add floors through upgrades.'
                : 'Draw beside the main road or a connected street. Green: available. Red: blocked or too expensive.',
          ),
          const SizedBox(height: 12),
          _line(
            'Footprint',
            site == null
                ? 'Draw on the map'
                : '${site.width} × ${site.length} tiles',
          ),
          Row(
            children: [
              const Expanded(child: Text('Above-ground floors')),
              IconButton(
                key: const ValueKey('initial-floor-minus'),
                tooltip: 'Fewer floors',
                onPressed: blocked || _review || _initialFloors == 1
                    ? null
                    : () => setState(() => _initialFloors--),
                icon: const Icon(Icons.remove),
              ),
              Text(
                '$_initialFloors',
                key: const ValueKey('initial-floor-count'),
              ),
              IconButton(
                key: const ValueKey('initial-floor-plus'),
                tooltip: 'More floors',
                onPressed: blocked || _review || _initialFloors == 10
                    ? null
                    : () => setState(() => _initialFloors++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          _line(
            'Calculated ${_buildType.unitLabel}',
            '${site == null ? 0 : _buildType.unitsPerFloor(site.tiles) * _initialFloors}',
          ),
          _line('B1 parking bays', '${site?.bays ?? 0}'),
          _line(
            'Shell · ${_buildType.shellDays * _initialFloors} game days',
            formatMoney(
              (site?.tiles ?? 0) * _buildType.shellPerTile * _initialFloors,
            ),
          ),
          _line('B1 · 1 game day', formatMoney(site?.basementCost ?? 0)),
          _line('Surrounding road', 'Included · 1 tile wide'),
          _line(
            'Road access',
            site == null
                ? 'Required'
                : game.roadNetwork.serves(site, game.buildings)
                ? 'Connected to main road'
                : 'Not connected',
          ),
          const Divider(),
          _line(
            'Total cost',
            formatMoney(
              site == null ? 0 : _buildType.quote(site.tiles, _initialFloors),
            ),
          ),
          if (site != null) ...[
            _line(
              'Balance after purchase',
              formatMoney(
                game.balance - _buildType.quote(site.tiles, _initialFloors),
              ),
            ),
            _line(
              'Capacity with B1',
              '${math.min(_buildType.unitsPerFloor(site.tiles) * _initialFloors, site.bays ~/ _buildType.baysPerUnit(site.tiles))} / ${_buildType.unitsPerFloor(site.tiles) * _initialFloors} ${_buildType.unitLabel}',
            ),
            Text(
              _buildType.baseRevenueLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Text(
              'Base income before demand, bonuses and tax. Parking limits occupancy.',
              style: TextStyle(color: GameColors.muted, fontSize: 13),
            ),
          ],
          _line(
            'Completed daily upkeep',
            formatMoney(
              _initialFloors * _buildType.floorMaintenance +
                  StarterCatalog.maintenancePerBasement,
            ),
          ),
          _line(
            'Parking per ${_buildType == BuildingType.office ? 'lease' : 'unit'}',
            '${_buildType.baysPerUnit(site?.tiles ?? 0)} ${_buildType.baysPerUnit(site?.tiles ?? 0) == 1 ? 'bay' : 'bays'}',
          ),
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
          Text(
            'Charged immediately. Construction: ${_buildType.shellDays * _initialFloors} game days, plus 1 for parking. Default stairs included.',
            style: const TextStyle(color: GameColors.muted, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _financePanel(DistrictGame game) {
    final closing = game.statement;
    final projected = DistrictSimulation.projectClosing(game);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Finances'),
        _line('Pending apartment rent', formatMoney(game.pendingRent)),
        _line('Next rent', 'Sunday · Day ${game.nextSunday}'),
        _line('Next 24:00 cash estimate', formatMoney(projected.gross)),
        _line('Projected operating net', formatMoney(projected.net)),
        const Text(
          'Estimate assumes no further player changes today.',
          style: TextStyle(color: GameColors.muted, fontSize: 13),
        ),
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
          _line('Hotel room income', formatMoney(closing.hotel)),
          _line('Office leases', formatMoney(closing.office)),
          _line('Food court sales', formatMoney(closing.sales)),
          _line('Parking received', formatMoney(closing.parking)),
          _line('Maintenance', formatMoney(-closing.maintenance)),
          _line('Tax', formatMoney(-closing.tax)),
          const Divider(),
          _line('Operating net', formatMoney(closing.net)),
          if (closing.net < 0)
            const Text(
              'Loss today: expenses exceeded cash received. Pending apartment rent is paid on Sunday.',
              style: TextStyle(color: GameColors.danger),
            ),
          _line('Purchases', formatMoney(-closing.purchases)),
          _line('Refunds', formatMoney(closing.refunds)),
        ],
        const SizedBox(height: 12),
        _line('Total earned', formatMoney(game.earned)),
        if (_model.returnSummary case final summary?) ...[
          const Divider(),
          Text(summary),
        ],
        const SizedBox(height: 10),
        const Text(
          '24-hour clock: 1 hour = 1 second. Books close at 24:00. Your district keeps running while you are away.',
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
    final firstRoom = (_model.currentFloor - 1) * building.unitsPerFloor;
    final lastRoom = firstRoom + building.unitsPerFloor;
    final floorTenants = building.occupied
        .where((room) => room >= firstRoom && room < lastRoom)
        .length;
    final floorVisitors =
        (building.currentVisitors -
                (_model.currentFloor - 1) * building.unitsPerFloor)
            .clamp(0, building.unitsPerFloor);
    final usedBays =
        (building.usedBays -
                (-_model.currentFloor - 1) * building.footprint.bays)
            .clamp(0, building.footprint.bays);
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortLandscape =
            constraints.maxWidth >= 700 &&
            MediaQuery.sizeOf(context).height < 500;
        final floorHeading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Row(
              children: [
                Image.asset(ProductionAssets.iconsHome, width: 30, height: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_model.floorLabel} · ${building.type == BuildingType.office
                        ? 'Whole-floor lease'
                        : building.type == BuildingType.foodCourt
                        ? 'Food court'
                        : 'Rooms'}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _line(
              switch (building.type) {
                BuildingType.foodCourt => 'Visiting parties',
                BuildingType.hotel => 'Guests',
                BuildingType.office => 'Leased floors',
                BuildingType.apartment => 'Tenants',
              },
              building.type == BuildingType.foodCourt
                  ? '$floorVisitors / ${building.unitsPerFloor} parties'
                  : '$floorTenants / ${building.unitsPerFloor} ${building.type.unitLabel}',
            ),
          ],
        );
        final overview = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading(
              building.name,
              action: TextButton.icon(
                onPressed: () => setState(() => _upgrades = true),
                icon: Image.asset(
                  ProductionAssets.iconsUpgrade,
                  width: 22,
                  height: 22,
                  excludeFromSemantics: true,
                ),
                label: const Text('Upgrade building'),
              ),
            ),
            Text(
              building.status,
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
            AccelerationButton(model: _model, building: building),
            if (building.happiness < 100)
              const Text(
                'Needs better vertical access. Add lifts to improve new demand.',
                style: TextStyle(color: GameColors.danger),
              ),
            if (building.upgrade case final upgrade?) ...[
              const SizedBox(height: 8),
              Text(
                '${upgrade.kind.label} · ${upgrade.stage.label} · ${(_model.upgradeProgress(building) * 100).floor()}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _model.upgradeProgress(building),
                minHeight: 8,
                semanticsLabel: 'Upgrade progress',
                semanticsValue:
                    '${(_model.upgradeProgress(building) * 100).floor()}%',
              ),
            ],
            if (!ready) ...[
              const SizedBox(height: 10),
              Text(switch (building.stage) {
                ConstructionStage.reserved => 'Paid. Construction queued.',
                ConstructionStage.paid => 'Paid. Construction starts tomorrow.',
                ConstructionStage.shell =>
                  'Building ${building.type.label.toLowerCase()} · Days ${building.startedDay}–${building.startedDay + building.initialShellDays - 1}.',
                ConstructionStage.shellDone =>
                  'Floors complete. Parking starts tomorrow.',
                ConstructionStage.basement =>
                  'Building parking · Day ${building.startedDay}.',
                ConstructionStage.parkingDone =>
                  'Construction complete. Ready to open.',
                ConstructionStage.ready => '',
              }),
              const SizedBox(height: 14),
              Text('Full refund: ${formatMoney(building.originalQuote)}'),
              const SizedBox(height: 8),
              GameButton(
                label: 'Cancel building',
                secondary: true,
                onPressed: _model.busy || _model.error != null
                    ? null
                    : () => unawaited(_cancel(building.id)),
              ),
            ],
            if (shortLandscape && _model.currentFloor > 0) floorHeading,
          ],
        );
        final floor = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_model.currentFloor > 0) ...[
              if (!shortLandscape) floorHeading,
              if (ready && building.type == BuildingType.foodCourt) ...[
                InkWell(
                  onTap: () => _openTenant(building.id, firstRoom),
                  child: Column(
                    children: [
                      Image.asset(
                        building.type.roomArtwork,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Tap to see dining activity',
                          style: TextStyle(color: GameColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                _line('Visits today', '${building.visitsToday} parties'),
                _line(
                  'Sales awaiting midnight',
                  formatMoney(building.salesToday),
                ),
                _line(
                  'Visitor parking awaiting midnight',
                  formatMoney(building.parkingToday),
                ),
                const Text(
                  'Each party reserves one bay. Bays turn over every six hours; daily sales and parking settle at 24:00.',
                ),
                if (floorVisitors > 0)
                  AssetAnimation(
                    path: building.type.actor,
                    sequence: 'walk',
                    width: 44,
                    height: 66,
                  ),
              ] else if (ready)
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
                        for (var room = firstRoom; room < lastRoom; room++)
                          SizedBox(width: width, child: _room(building, room)),
                      ],
                    );
                  },
                )
              else
                const Text(
                  'Open the building after construction to welcome tenants.',
                ),
              _line(
                switch (building.type) {
                  BuildingType.foodCourt => 'Building visitors',
                  BuildingType.hotel => 'Building guests',
                  BuildingType.office => 'Building leases',
                  BuildingType.apartment => 'Building tenants',
                },
                '${building.type == BuildingType.foodCourt ? building.currentVisitors : building.occupied.length} / ${building.rooms} ${building.type.unitLabel}',
              ),
              _line(
                'Building parking',
                '${building.usedBays} / ${building.bays} bays used',
              ),
              if (building.type == BuildingType.apartment) ...[
                _line('Pending weekly rent', formatMoney(building.pendingRent)),
                _line(
                  'Weekly rent per room',
                  formatMoney(StarterCatalog.weeklyRent),
                ),
              ] else if (building.type == BuildingType.hotel)
                _line('Daily base room rate', formatMoney(16000))
              else if (building.type == BuildingType.office)
                _line(
                  'Daily base floor lease',
                  formatMoney(18000 * building.footprint.tiles),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: 150,
                height: 100,
                child: Stack(
                  children: [
                    Image.asset(
                      ProductionAssets.transportStairs,
                      height: 90,
                      width: 140,
                      excludeFromSemantics: true,
                    ),
                    if (building.occupied.isNotEmpty ||
                        building.currentVisitors > 0)
                      Positioned(
                        left: 56,
                        bottom: 12,
                        child: AssetAnimation(
                          path: building.type.actor,
                          sequence: _model.travelDirection == 0
                              ? 'walk'
                              : 'stairs',
                          width: 32,
                          height: 48,
                        ),
                      ),
                  ],
                ),
              ),
              if (building.standardLifts > 0 || building.executiveLifts > 0)
                Wrap(
                  spacing: 12,
                  children: [
                    if (building.standardLifts > 0)
                      _lift(
                        ProductionAssets.transportStandardLift,
                        '${building.standardLifts} standard ${building.standardLifts == 1 ? 'lift' : 'lifts'}',
                      ),
                    if (building.executiveLifts > 0)
                      _lift(
                        ProductionAssets.transportExecutiveLift,
                        '1 executive lift',
                      ),
                  ],
                ),
              Text(
                building.parkingComplete
                    ? 'Go down for parking.'
                    : 'Parking not ready.',
              ),
            ] else ...[
              const Divider(),
              Text(
                '${_model.floorLabel} · Parking only',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Image.asset(
                usedBays == 0
                    ? ProductionAssets.transportParkingEmpty
                    : ProductionAssets.transportParkingOccupied,
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              _line('Parking capacity', '${building.footprint.bays} bays'),
              _line(
                building.type == BuildingType.foodCourt
                    ? 'Visitor bays used'
                    : building.type == BuildingType.hotel
                    ? 'Guest bays used'
                    : 'Tenant bays used',
                '$usedBays',
              ),
              _line('Available bays', '${building.footprint.bays - usedBays}'),
              const Text(
                'Parking limits concurrent tenants or visitor parties.',
                style: TextStyle(fontSize: 13, color: GameColors.muted),
              ),
            ],
            const Divider(),
            ExpansionTile(
              key: PageStorageKey('building-details-${building.id}'),
              tilePadding: EdgeInsets.zero,
              title: const Text('Building details'),
              subtitle: Text(
                '${building.footprint.width} × ${building.footprint.length} tiles · Tier ${building.luxury} · Happiness ${building.happiness}%',
              ),
              children: [
                const SizedBox(height: 10),
                _line(
                  'Permanent footprint',
                  '${building.footprint.width} × ${building.footprint.length} tiles',
                ),
                _line(
                  'Floors / basements',
                  '${building.completedFloors} / ${building.completedBasements}',
                ),
                _line(
                  'Lifts / executive lifts',
                  '${building.standardLifts} / ${building.executiveLifts}',
                ),
                _line('Luxury', 'Tier ${building.luxury} / 3'),
                _line('Happiness', '${building.happiness} / 100'),
                _line(
                  'Synergy',
                  '+${DistrictSimulation.synergyPercent(game, building)}% new rent/sales',
                ),
              ],
            ),
          ],
        );
        if (shortLandscape) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, child: overview),
              const SizedBox(width: 16),
              Expanded(child: floor),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [overview, floor],
        );
      },
    );
  }

  Widget _lift(String asset, String label) => Column(
    children: [
      VerticalTransport(
        key: ValueKey('lift-$_selected-${_model.currentFloor}-$asset'),
        executive: asset == ProductionAssets.transportExecutiveLift,
        direction: _model.travelDirection,
        onArrival: () =>
            unawaited(_audio.effect(ProductionAssets.audioLiftDing)),
      ),
      SizedBox(width: 150, child: Text(label, textAlign: TextAlign.center)),
    ],
  );

  Widget _constructionProgress(ApartmentBuilding building) {
    final progress = _model.constructionProgress(building);
    final percent = (progress * 100).floor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (building.stage == ConstructionStage.shell ||
            building.stage == ConstructionStage.basement)
          Row(
            children: [
              const AssetAnimation(
                path: ProductionAssets.charactersMaintenanceAnimation,
                sequence: 'walk',
                width: 38,
                height: 57,
              ),
              if (!MediaQuery.disableAnimationsOf(context))
                AssetAnimation(
                  key: ValueKey('dust-${building.id}-${building.stage}'),
                  path: ProductionAssets.effectsDust,
                  sequence: 'play',
                  width: 48,
                  height: 48,
                  hideWhenComplete: true,
                ),
            ],
          ),
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
        onTap: () => _openTenant(building.id, room),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              SizedBox(
                key: ValueKey('room-artwork-${building.id}-$room'),
                width: 140,
                height: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      occupied
                          ? building.type.roomArtwork
                          : building.type.vacantArtwork,
                      fit: BoxFit.contain,
                    ),
                    if (occupied)
                      Positioned(
                        right: 8,
                        bottom: 4,
                        child: AssetAnimation(
                          path: building.type.actor,
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
                      '${building.type == BuildingType.office ? 'Lease' : 'Room'} ${room + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      occupied
                          ? 'Occupied · ${building.type.baysPerUnit(building.footprint.tiles)} ${building.type.baysPerUnit(building.footprint.tiles) == 1 ? 'bay' : 'bays'}'
                          : 'Vacant',
                      style: const TextStyle(
                        fontSize: 12,
                        color: GameColors.muted,
                      ),
                    ),
                    if (occupied)
                      const Text(
                        'Tap to see inside',
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

  Future<void> _openTenant(int buildingId, int unit) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TenantActivityScreen(
            model: _model,
            buildingId: buildingId,
            unit: unit,
            onManage: () => _vacate(buildingId, unit),
          ),
        ),
      );

  Future<void> _vacate(int id, int room) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) =>
          TenantManagementScreen(model: _model, buildingId: id, unit: room),
    ),
  );
}
