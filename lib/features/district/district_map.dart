import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import '../../app/game_theme.dart';
import '../../app/production_assets.dart';
import '../../domain/district_game.dart';
import 'map_camera_view_model.dart';
import 'daylight.dart';
import 'building_presentation.dart';

part 'map_activity.dart';
part 'city_figure.dart';

class DistrictMap extends StatefulWidget {
  const DistrictMap({
    super.key,
    required this.game,
    required this.drawing,
    required this.onFootprint,
    required this.onSelect,
    this.preview,
    this.selected,
    this.reset = 0,
    this.onCancelFootprint,
    this.elapsedMilliseconds = 0,
    this.previewValid,
    this.decorationPreview = false,
    this.camera,
    this.controlInsets = EdgeInsets.zero,
    this.immersive = false,
  });
  final DistrictGame game;
  final bool drawing;
  final Footprint? preview;
  final int? selected;
  final int reset;
  final int elapsedMilliseconds;
  final bool? previewValid;
  final bool decorationPreview;
  final MapCameraViewModel? camera;
  final EdgeInsets controlInsets;
  final bool immersive;
  final ValueChanged<Footprint> onFootprint;
  final VoidCallback? onCancelFootprint;
  final ValueChanged<int> onSelect;
  @override
  State<DistrictMap> createState() => _DistrictMapState();
}

class _DistrictMapState extends State<DistrictMap>
    with TickerProviderStateMixin {
  late final AnimationController _rotationAnimation;
  double _rotationFrom = 0, _rotationDelta = 0;
  Offset _rotationOrigin = Offset.zero;
  final _activityClock = ValueNotifier<double>(0);
  late final Ticker _activityTicker;
  double _carriedSeconds = 0;
  double _lastActivitySeconds = -1;
  late final _ownedCamera = MapCameraViewModel();
  MapCameraViewModel get _camera => widget.camera ?? _ownedCamera;
  LandCell? _start;
  int? _drawingPointer;
  final _pointers = <int>{};
  final _pointerPositions = <int, Offset>{};
  Offset? _multiStartFocal;
  bool _hadMultiTouch = false;
  Footprint? _previousPreview;
  double _gestureZoom = 1, _gestureScale = 1;
  double _gestureRotation = 0, _rotationOffset = 0;
  int _scalePointers = 0;
  Offset _previousFocal = Offset.zero;
  Map<String, ui.Image> _images = {};
  static Future<Map<String, ui.Image>>? _art;

  @override
  void initState() {
    super.initState();
    _rotationAnimation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
        )..addListener(() {
          _camera.transform(
            zoom: _camera.zoom,
            rotation:
                _rotationFrom +
                _rotationDelta *
                    Curves.easeInOutCubic.transform(_rotationAnimation.value),
            fromFocal: Offset.zero,
            toFocal: Offset.zero,
            originOffset: _rotationOrigin,
          );
        });
    _activityTicker = createTicker((elapsed) {
      final seconds = _carriedSeconds + elapsed.inMicroseconds / 1000000;
      if (seconds - _lastActivitySeconds >= 1 / 30) {
        _lastActivitySeconds = seconds;
        _activityClock.value = seconds;
      }
    });
    _load();
  }

  void _rotate(double delta, Offset origin) {
    _rotationAnimation.stop();
    if (MediaQuery.disableAnimationsOf(context)) {
      _camera.rotateBy(delta, originOffset: origin);
      return;
    }
    _rotationFrom = _camera.rotation;
    _rotationDelta = delta;
    _rotationOrigin = origin;
    _rotationAnimation.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncActivity();
  }

  void _syncActivity() {
    final active =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        widget.game.buildings.any((b) => b.stage == ConstructionStage.ready);
    if (active && !_activityTicker.isActive) _activityTicker.start();
    if (!active && _activityTicker.isActive) {
      _carriedSeconds = _activityClock.value;
      _activityTicker.stop();
    }
  }

  Future<void> _load() async {
    try {
      final images = await (_art ??= _loadImages());
      if (mounted) setState(() => _images = images);
    } catch (_) {
      _art = null;
      // The native grid remains usable when an image fails to decode.
    }
  }

  static Future<Map<String, ui.Image>> _loadImages() async {
    final paths = [
      ProductionAssets.tilesLand,
      ProductionAssets.buildingsApartment,
      ProductionAssets.buildingsHotel,
      ProductionAssets.buildingsOffice,
      ProductionAssets.buildingsFoodCourt,
      for (final kind in DecorationKind.values) kind.artwork,
      ProductionAssets.buildingsConstructionFenced,
      ProductionAssets.buildingsConstructionFrame,
      for (var i = 0; i < 16; i++)
        'assets/game/tiles/road-${i.toRadixString(2).padLeft(4, '0')}.png',
    ];
    final images = await Future.wait(
      paths.map((path) async {
        final bytes = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        return MapEntry(path, frame.image);
      }),
    );
    return Map.fromEntries(images);
  }

  @override
  void didUpdateWidget(DistrictMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reset != widget.reset) {
      _rotationAnimation.stop();
      _camera.center();
    }
    _syncActivity();
  }

  @override
  void dispose() {
    _activityTicker.dispose();
    _rotationAnimation.dispose();
    _activityClock.dispose();
    if (widget.camera == null) _ownedCamera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _camera,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final leftZoom =
            widget.immersive &&
            size.height - widget.controlInsets.vertical < 180;
        final projection = MapProjection(
          size,
          _camera.pan,
          zoom: _camera.zoom,
          rotation: _camera.rotation,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              label: widget.drawing
                  ? 'Draw a footprint or select a decoration tile on the map.'
                  : 'District map. Drag to pan, pinch to zoom, tap a building.',
              child: Listener(
                onPointerDown: (event) {
                  _rotationAnimation.stop();
                  if (_pointers.isEmpty) {
                    _hadMultiTouch = false;
                    _previousPreview = widget.preview;
                    _multiStartFocal = null;
                  }
                  _pointers.add(event.pointer);
                  _pointerPositions[event.pointer] = event.localPosition;
                  if (_pointers.length == 2) {
                    _multiStartFocal =
                        _pointerPositions.values.reduce((a, b) => a + b) / 2;
                  }
                  if (_pointers.length > 1) {
                    _hadMultiTouch = true;
                    _start = null;
                    _drawingPointer = null;
                    if (widget.drawing) {
                      final previous = _previousPreview;
                      if (previous == null) {
                        widget.onCancelFootprint?.call();
                      } else {
                        widget.onFootprint(previous);
                      }
                    }
                  }
                  if (widget.drawing &&
                      !_hadMultiTouch &&
                      _drawingPointer == null) {
                    _drawingPointer = event.pointer;
                    _start = projection.cellAt(event.localPosition);
                    widget.onFootprint(Footprint.between(_start!, _start!));
                  }
                },
                onPointerMove: (event) {
                  _pointerPositions[event.pointer] = event.localPosition;
                  if (_drawingPointer == event.pointer && _start != null) {
                    widget.onFootprint(
                      Footprint.between(
                        _start!,
                        projection.cellAt(event.localPosition),
                      ),
                    );
                  }
                },
                onPointerUp: (event) {
                  _pointers.remove(event.pointer);
                  _pointerPositions.remove(event.pointer);
                  if (_drawingPointer == event.pointer && _start != null) {
                    widget.onFootprint(
                      Footprint.between(
                        _start!,
                        projection.cellAt(event.localPosition),
                      ),
                    );
                    _start = null;
                    _drawingPointer = null;
                  }
                },
                onPointerCancel: (event) {
                  _pointers.remove(event.pointer);
                  _pointerPositions.remove(event.pointer);
                  if (_drawingPointer == event.pointer) {
                    _start = null;
                    _drawingPointer = null;
                  }
                },
                child: GestureDetector(
                  excludeFromSemantics: true,
                  dragStartBehavior: DragStartBehavior.down,
                  key: const ValueKey('district-map'),
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    _gestureZoom = _camera.zoom;
                    _gestureScale = 1;
                    _gestureRotation = _camera.rotation;
                    _rotationOffset = 0;
                    _scalePointers = details.pointerCount;
                    _previousFocal = details.pointerCount >= 2
                        ? _multiStartFocal ?? details.localFocalPoint
                        : details.localFocalPoint;
                  },
                  onScaleUpdate: (details) {
                    if (_scalePointers != details.pointerCount) {
                      _gestureZoom = _camera.zoom;
                      _gestureScale = details.scale;
                      _gestureRotation = _camera.rotation;
                      _rotationOffset = details.rotation;
                      _scalePointers = details.pointerCount;
                      _previousFocal = details.pointerCount >= 2
                          ? _multiStartFocal ?? details.localFocalPoint
                          : details.localFocalPoint;
                    }
                    if (details.pointerCount >= 2 ||
                        details.pointerCount == 0) {
                      final centre = size.center(Offset.zero);
                      _camera.transform(
                        zoom: _gestureZoom * details.scale / _gestureScale,
                        rotation:
                            _gestureRotation +
                            details.rotation -
                            _rotationOffset,
                        originOffset:
                            projection.originOffset *
                            (_camera.zoom / projection.zoom),
                        fromFocal: _previousFocal - centre,
                        toFocal: details.localFocalPoint - centre,
                      );
                    } else if (!widget.drawing && !_hadMultiTouch) {
                      _camera.panBy(details.focalPointDelta);
                    }
                    _previousFocal = details.localFocalPoint;
                  },
                  onTapUp: (details) {
                    final cell = projection.cellAt(details.localPosition);
                    if (!widget.drawing && !_hadMultiTouch) {
                      for (final building in _depthSorted(
                        widget.game,
                        projection,
                      ).reversed) {
                        final facadeHit =
                            building.shellComplete &&
                            projection
                                .buildingSilhouette(
                                  building.footprint,
                                  type: building.type,
                                  floors: building.completedFloors,
                                )
                                .contains(details.localPosition);
                        if (facadeHit || building.footprint.contains(cell)) {
                          widget.onSelect(building.id);
                          break;
                        }
                      }
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: GameColors.surface,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _DistrictPainter(
                                widget.game,
                                projection,
                                _images,
                                widget.preview,
                                widget.selected,
                                widget.elapsedMilliseconds,
                                widget.previewValid,
                                widget.decorationPreview,
                                terrainOnly: true,
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _DistrictPainter(
                                widget.game,
                                projection,
                                _images,
                                widget.preview,
                                widget.selected,
                                widget.elapsedMilliseconds,
                                widget.previewValid,
                                widget.decorationPreview,
                                structuresOnly: true,
                                hideLabels: true,
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: ExcludeSemantics(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                key: const ValueKey('map-activity'),
                                painter: _MapActivityPainter(
                                  widget.game,
                                  projection,
                                  _images,
                                  _activityClock,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _DistrictPainter(
                                widget.game,
                                projection,
                                _images,
                                widget.preview,
                                widget.selected,
                                widget.elapsedMilliseconds,
                                widget.previewValid,
                                widget.decorationPreview,
                                structuresOnly: true,
                                labelsOnly: true,
                              ),
                            ),
                          ),
                        ),
                        DaylightOverlay(
                          milliseconds:
                              ((widget.game.day - 1) *
                                          StarterCatalog.dayMilliseconds +
                                      widget.game.timeOfDayMilliseconds +
                                      widget.elapsedMilliseconds)
                                  .toDouble(),
                        ),
                        if (!widget.immersive)
                          Positioned(
                            left: 14,
                            top: 12,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: GameColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: SizedBox(
                                  width: math.max(
                                    40,
                                    math.min(310, size.width - 164),
                                  ),
                                  child: Text(
                                    widget.drawing
                                        ? 'Road access required · Pinch / twist'
                                        : 'Drag to pan · Pinch / twist · Tap a building',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: GameColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 68,
              top: 12 + widget.controlInsets.top,
              child: Material(
                color: GameColors.surface,
                borderRadius: BorderRadius.circular(8),
                child: PopupMenuButton<String>(
                  key: const ValueKey('map-rotation'),
                  tooltip: 'Rotate map',
                  constraints: const BoxConstraints(minWidth: 220),
                  icon: Transform.rotate(
                    angle: _camera.rotation,
                    child: const Icon(Icons.explore_outlined),
                  ),
                  onSelected: (value) {
                    if (value == 'reset') {
                      final delta =
                          (-_camera.rotation + math.pi) % (2 * math.pi) -
                          math.pi;
                      _rotate(delta, projection.originOffset);
                    } else {
                      _rotate(
                        (value == 'left' ? -1 : 1) * math.pi / 2,
                        projection.originOffset,
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text('Map bearing ${_camera.bearing}°'),
                    ),
                    const PopupMenuItem(
                      value: 'left',
                      height: 48,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.rotate_left),
                        title: Text('Rotate left'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'right',
                      height: 48,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.rotate_right),
                        title: Text('Rotate right'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset',
                      height: 48,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.north),
                        title: Text('Reset rotation'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12 + widget.controlInsets.top,
              child: Material(
                color: GameColors.surface,
                borderRadius: BorderRadius.circular(8),
                child: IconButton(
                  key: const ValueKey('map-main-road'),
                  tooltip: 'Main road',
                  onPressed: () {
                    _rotationAnimation.stop();
                    final road = projection.point(
                      0,
                      widget.game.roadNetwork.mainRow + 1,
                    );
                    _camera.panBy(size.center(Offset.zero) - road);
                  },
                  icon: const Icon(Icons.add_road),
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              left: leftZoom ? 12 : null,
              right: leftZoom ? null : 12,
              bottom: 12 + widget.controlInsets.bottom,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: GameColors.ink, offset: Offset(0, 3)),
                  ],
                ),
                child: Material(
                  color: GameColors.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: GameColors.ink, width: 2),
                  ),
                  child: Flex(
                    direction: size.width < 400 && size.height < 260
                        ? Axis.vertical
                        : Axis.horizontal,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const ValueKey('map-zoom-out'),
                        tooltip: 'Zoom out',
                        constraints: const BoxConstraints.tightFor(
                          width: 48,
                          height: 48,
                        ),
                        onPressed: _camera.canZoomOut
                            ? () {
                                _rotationAnimation.stop();
                                _camera.zoomOut();
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 54,
                        child: Semantics(
                          label: 'Map zoom ${_camera.percent} percent',
                          excludeSemantics: true,
                          child: Text(
                            '${_camera.percent}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('map-zoom-in'),
                        tooltip: 'Zoom in',
                        constraints: const BoxConstraints.tightFor(
                          width: 48,
                          height: 48,
                        ),
                        onPressed: _camera.canZoomIn
                            ? () {
                                _rotationAnimation.stop();
                                _camera.zoomIn();
                              }
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class MapProjection {
  MapProjection(this.size, this.pan, {this.zoom = 1, this.rotation = 0});
  final Size size;
  final Offset pan;
  final double zoom;
  final double rotation;
  double get _baseTile => size.width < 500 ? 54 : 80;
  double get tile => _baseTile * zoom;
  // Keep the starting street/plot below the hint in short viewports. This
  // offset scales with zoom, preserving the camera's focal-point transform.
  Offset get originOffset =>
      Offset(0, -math.min(_baseTile * 1.5, size.height / 2 - 64) * zoom);
  Offset get origin => size.center(Offset.zero) + originOffset + pan;
  Offset turn(Offset p) => Offset(
    p.dx * math.cos(rotation) - p.dy * math.sin(rotation),
    p.dx * math.sin(rotation) + p.dy * math.cos(rotation),
  );
  Offset point(num x, num y) {
    final view = turn(Offset(x.toDouble(), y.toDouble()));
    return origin +
        Offset((view.dx - view.dy) * tile / 2, (view.dx + view.dy) * tile / 4);
  }

  Offset worldAt(Offset screen) {
    final local = screen - origin;
    final x = local.dx / tile + 2 * local.dy / tile;
    final y = 2 * local.dy / tile - local.dx / tile;
    return Offset(
      x * math.cos(rotation) + y * math.sin(rotation),
      -x * math.sin(rotation) + y * math.cos(rotation),
    );
  }

  LandCell cellAt(Offset screen) {
    final world = worldAt(screen);
    return LandCell(world.dx.floor(), world.dy.floor());
  }

  List<Offset> orderCorners(List<Offset> points) {
    var back = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].dy < points[back].dy - 0.000001) back = i;
    }
    return [
      for (var i = 0; i < points.length; i++)
        points[(back + i) % points.length],
    ];
  }

  /// A ray toward the camera must cross the footprint to hide this actor.
  bool occludesPoint(Footprint site, Offset world) {
    final direction = Offset(
      math.cos(rotation) + math.sin(rotation),
      math.cos(rotation) - math.sin(rotation),
    );
    var near = 0.0, far = double.infinity;
    for (final axis in [
      (
        world.dx,
        direction.dx,
        site.x.toDouble(),
        (site.x + site.width).toDouble(),
      ),
      (
        world.dy,
        direction.dy,
        site.y.toDouble(),
        (site.y + site.length).toDouble(),
      ),
    ]) {
      if (axis.$2.abs() < 0.000001) {
        if (axis.$1 <= axis.$3 || axis.$1 >= axis.$4) return false;
      } else {
        final a = (axis.$3 - axis.$1) / axis.$2;
        final b = (axis.$4 - axis.$1) / axis.$2;
        near = math.max(near, math.min(a, b));
        far = math.min(far, math.max(a, b));
      }
    }
    return far > near && far > 0;
  }

  Path footprint(Footprint site, [double lift = 0]) {
    final points = [
      point(site.x, site.y),
      point(site.x + site.width, site.y),
      point(site.x + site.width, site.y + site.length),
      point(site.x, site.y + site.length),
    ].map((p) => p - Offset(0, lift)).toList();
    return Path()..addPolygon(points, true);
  }

  // One architectural storey keeps its world height on every plot.
  double storeyHeight({BuildingType type = BuildingType.apartment}) =>
      tile * (type == BuildingType.foodCourt ? .46 : .34);

  double buildingHeight(
    Footprint site, {
    BuildingType type = BuildingType.apartment,
    int floors = 1,
  }) => storeyHeight(type: type) * math.max(1, floors);

  List<Offset> buildingCorners(
    Footprint site, {
    bool roof = false,
    BuildingType type = BuildingType.apartment,
    int floors = 1,
  }) => orderCorners(
    [
          point(site.x, site.y),
          point(site.x + site.width, site.y),
          point(site.x + site.width, site.y + site.length),
          point(site.x, site.y + site.length),
        ]
        .map(
          (p) =>
              p -
              Offset(
                0,
                roof ? buildingHeight(site, type: type, floors: floors) : 0,
              ),
        )
        .toList(),
  );

  Path buildingSilhouette(
    Footprint site, {
    BuildingType type = BuildingType.apartment,
    int floors = 1,
  }) {
    final base = buildingCorners(site);
    final roof = buildingCorners(site, roof: true, type: type, floors: floors);
    return Path()..addPolygon([
      roof[0],
      roof[1],
      base[1],
      base[2],
      base[3],
      roof[3],
    ], true);
  }

  Rect buildingRect(
    Footprint site, {
    BuildingType type = BuildingType.apartment,
    int floors = 1,
  }) => buildingSilhouette(site, type: type, floors: floors).getBounds();
}

List<ApartmentBuilding> _depthSorted(
  DistrictGame game,
  MapProjection projection,
) => game.buildings.toList()
  ..sort((a, b) {
    final depth = projection
        .footprint(a.footprint)
        .getBounds()
        .bottom
        .compareTo(projection.footprint(b.footprint).getBounds().bottom);
    return depth == 0 ? a.id.compareTo(b.id) : depth;
  });

class _DistrictPainter extends CustomPainter {
  _DistrictPainter(
    this.game,
    this.projection,
    this.images,
    this.preview,
    this.selected,
    this.elapsedMilliseconds,
    this.previewValid,
    this.decorationPreview, {
    this.terrainOnly = false,
    this.structuresOnly = false,
    this.labelsOnly = false,
    this.hideLabels = false,
  });
  final bool terrainOnly, structuresOnly, labelsOnly, hideLabels;
  final DistrictGame game;
  final MapProjection projection;
  final Map<String, ui.Image> images;
  final Footprint? preview;
  final int? selected;
  final int elapsedMilliseconds;
  final bool? previewValid;
  final bool decorationPreview;

  void _mainRoad(
    Canvas canvas,
    int left,
    int right,
    bool Function(LandCell) road,
  ) {
    final y = game.roadNetwork.mainRow;
    final bounds = Footprint(left - 2, y, right - left + 5, 2);
    canvas.drawPath(
      projection.footprint(bounds),
      Paint()..color = const Color(0xFFE6D5B5),
    );
    final asphalt = Path()
      ..addPolygon([
        projection.point(left - 2, y + .15),
        projection.point(right + 3, y + .15),
        projection.point(right + 3, y + 1.85),
        projection.point(left - 2, y + 1.85),
      ], true);
    canvas.drawPath(asphalt, Paint()..color = const Color(0xFF626F70));
    final line = Paint()
      ..color = const Color(0xFFFFF3D4)
      ..strokeWidth = 2 * projection.zoom;
    for (var x = left - 2; x < right + 3; x++) {
      // Open the curb where a neighbourhood street meets the highway.
      for (final edge in [y - 1, y + 2]) {
        if (!road(LandCell(x, edge))) continue;
        final from = edge < y ? y - .25 : y + 1.7;
        final to = edge < y ? y + .3 : y + 2.25;
        canvas.drawPath(
          Path()..addPolygon([
            projection.point(x + .18, from),
            projection.point(x + .82, from),
            projection.point(x + .82, to),
            projection.point(x + .18, to),
          ], true),
          Paint()..color = const Color(0xFF626F70),
        );
      }
      canvas.drawLine(
        projection.point(x + .15, y + 1),
        projection.point(x + .7, y + 1),
        line,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!structuresOnly && !labelsOnly) {
      final corners = [
        Offset.zero,
        Offset(size.width, 0),
        Offset(0, size.height),
        Offset(size.width, size.height),
      ].map(projection.cellAt).toList();
      final minX = corners.map((c) => c.x).reduce(math.min) - 2;
      final maxX = corners.map((c) => c.x).reduce(math.max) + 2;
      final minY = corners.map((c) => c.y).reduce(math.min) - 2;
      final maxY = corners.map((c) => c.y).reduce(math.max) + 2;
      final localRoads = game.roads;
      bool road(LandCell cell) =>
          localRoads.contains(cell) || game.roadNetwork.contains(cell);
      final scale = projection.tile / 256;
      final c = math.cos(projection.rotation),
          s = math.sin(projection.rotation);
      final groundTransform =
          (Matrix4.identity()
                ..setEntry(0, 0, c)
                ..setEntry(0, 1, -2 * s)
                ..setEntry(1, 0, s / 2)
                ..setEntry(1, 1, c))
              .storage;
      for (var diagonal = minX + minY; diagonal <= maxX + maxY; diagonal++) {
        for (var x = minX; x <= maxX; x++) {
          final y = diagonal - x;
          if (y < minY || y > maxY) continue;
          final cell = LandCell(x, y);
          final top = projection.point(x, y);
          if (top.dx < -projection.tile * 2 ||
              top.dx > size.width + projection.tile * 2 ||
              top.dy < -projection.tile * 2 ||
              top.dy > size.height + projection.tile * 2) {
            continue;
          }
          var path = ProductionAssets.tilesLand;
          if (road(cell) && !game.roadNetwork.isMain(cell)) {
            var mask = 0;
            if (road(LandCell(x, y - 1))) mask |= 1;
            if (road(LandCell(x + 1, y))) mask |= 2;
            if (road(LandCell(x, y + 1))) mask |= 4;
            if (road(LandCell(x - 1, y))) mask |= 8;
            path =
                'assets/game/tiles/road-${mask.toRadixString(2).padLeft(4, '0')}.png';
          }
          final image = images[path];
          if (image != null) {
            canvas.save();
            canvas.translate(top.dx, top.dy);
            canvas.transform(groundTransform);
            canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                0,
                0,
                image.width.toDouble(),
                image.height.toDouble(),
              ),
              Rect.fromLTWH(-130 * scale, -4 * scale, 260 * scale, 148 * scale),
              Paint()..filterQuality = FilterQuality.low,
            );
            canvas.restore();
          } else {
            final tile = projection.footprint(Footprint(x, y, 1, 1));
            canvas.drawPath(
              tile,
              Paint()
                ..color = road(cell)
                    ? const Color(0xFF626F70)
                    : GameColors.land,
            );
            canvas.drawPath(
              tile,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = const Color(0xFF97B675),
            );
          }
        }
      }
      _mainRoad(canvas, minX, maxX, road);
    }
    if (terrainOnly) return;
    final buildings = _depthSorted(game, projection);
    for (final building in buildings) {
      final site = building.footprint;
      if (!labelsOnly) {
        final path = projection.footprint(site);
        canvas.drawPath(path, Paint()..color = const Color(0xFFE6D5B5));
        if (building.id == selected) {
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = GameColors.primary,
          );
        }
        if (building.shellComplete &&
            images.containsKey(building.type.exterior)) {
          _building(canvas, building);
        } else {
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = GameColors.ink,
          );
          final image =
              images[building.stage == ConstructionStage.shell
                  ? ProductionAssets.buildingsConstructionFrame
                  : ProductionAssets.buildingsConstructionFenced];
          if (image != null) {
            final center = projection.point(
              site.x + site.width / 2,
              site.y + site.length / 2,
            );
            final width = math.min(
              (site.width + site.length) * projection.tile / 2,
              180.0 * projection.zoom,
            );
            final height = width * image.height / image.width;
            canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                0,
                0,
                image.width.toDouble(),
                image.height.toDouble(),
              ),
              Rect.fromLTWH(
                center.dx - width / 2,
                center.dy - height / 2,
                width,
                height,
              ),
              Paint()..filterQuality = FilterQuality.low,
            );
          }
        }
      }
      if (hideLabels) continue;
      final working =
          building.stage != ConstructionStage.ready || building.upgrade != null;
      final progress = building.upgrade != null
          ? DistrictSimulation.upgradeProgress(
              game,
              building,
              elapsedMilliseconds: elapsedMilliseconds,
            )
          : DistrictSimulation.constructionProgress(
              game,
              building,
              elapsedMilliseconds: elapsedMilliseconds,
            );
      final label = TextPainter(
        text: TextSpan(
          text: !working
              ? '${building.name}${building.luxury > 1 ? ' · Luxury ${building.luxury}' : ''}'
              : '${building.name} · ${building.upgrade != null ? 'Upgrade · ' : ''}${(progress * 100).floor()}%',
          style: const TextStyle(
            color: GameColors.ink,
            fontSize: 13,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final landBounds = projection.footprint(site).getBounds();
      final position = Offset(
        landBounds.center.dx - label.width / 2,
        landBounds.bottom + 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            position.dx - 6,
            position.dy - 3,
            label.width + 12,
            label.height + 6,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = GameColors.surface,
      );
      label.paint(canvas, position);
      if (working) {
        final track = Rect.fromLTWH(
          position.dx - 6,
          position.dy + label.height + 5,
          label.width + 12,
          8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(track, const Radius.circular(4)),
          Paint()..color = GameColors.border,
        );
        if (progress > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                track.left,
                track.top,
                track.width * progress,
                track.height,
              ),
              const Radius.circular(4),
            ),
            Paint()..color = GameColors.primary,
          );
        }
      }
    }
    if (labelsOnly) return;
    for (final decoration in game.decorations) {
      final image = images[decoration.kind.artwork];
      if (image == null) continue;
      final anchor = projection.point(
        decoration.cell.x + .5,
        decoration.cell.y + .5,
      );
      final width = projection.tile * .8;
      final height = width * image.height / image.width;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(anchor.dx - width / 2, anchor.dy - height, width, height),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    if (preview case final site?) {
      final valid =
          previewValid ?? DistrictSimulation.placementError(game, site) == null;
      final color = valid ? GameColors.primary : GameColors.danger;
      for (final cell in decorationPreview ? <LandCell>[] : site.roadRing) {
        final path = projection.footprint(Footprint(cell.x, cell.y, 1, 1));
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: .18));
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      canvas.drawPath(
        projection.footprint(site),
        Paint()..color = color.withValues(alpha: .3),
      );
      canvas.drawPath(
        projection.footprint(site),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  /// Extend approved facade bays along the actual isometric footprint axes.
  void _building(Canvas canvas, ApartmentBuilding building) {
    final site = building.footprint;
    final image = images[building.type.exterior]!;
    {
      final base = projection.buildingCorners(site);
      final roof = projection.buildingCorners(
        site,
        roof: true,
        type: building.type,
        floors: building.completedFloors,
      );
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..shader = ImageShader(
          image,
          TileMode.clamp,
          TileMode.clamp,
          Matrix4.identity().storage,
        );
      void quad(List<Offset> points, List<Offset> texture) {
        canvas.drawVertices(
          ui.Vertices(
            ui.VertexMode.triangles,
            points,
            textureCoordinates: texture,
            indices: [0, 1, 2, 0, 2, 3],
          ),
          BlendMode.srcOver,
          paint,
        );
      }

      void wall(int start, int end, int tiles, List<Offset> uv) {
        final bays = (tiles / 2).ceil();
        final floors = math.max(1, building.completedFloors);
        final sourceFloors = building.type == BuildingType.foodCourt
            ? 1
            : building.type == BuildingType.office
            ? 5
            : 4;
        final step = projection.storeyHeight(type: building.type);
        for (var floor = 0; floor < floors; floor++) {
          // Keep the entrance at ground level; repeat an upper-storey bay,
          // rather than stretching a whole four-storey image taller.
          final from = floor == 0
              ? 1 - 1 / sourceFloors
              : sourceFloors == 1
              ? 0.0
              : 1 / sourceFloors;
          final to = from + 1 / sourceFloors;
          final texture = [
            Offset.lerp(uv[0], uv[3], from)!,
            Offset.lerp(uv[1], uv[2], from)!,
            Offset.lerp(uv[1], uv[2], to)!,
            Offset.lerp(uv[0], uv[3], to)!,
          ];
          for (var i = 0; i < bays; i++) {
            final a = i / bays, b = (i + 1) / bays;
            final left = Offset.lerp(base[start], base[end], a)!;
            final right = Offset.lerp(base[start], base[end], b)!;
            quad([
              left - Offset(0, (floor + 1) * step),
              right - Offset(0, (floor + 1) * step),
              right - Offset(0, floor * step),
              left - Offset(0, floor * step),
            ], texture);
          }
          canvas.drawLine(
            base[start] - Offset(0, (floor + 1) * step),
            base[end] - Offset(0, (floor + 1) * step),
            Paint()
              ..color = const Color(0xFFE6D5B5)
              ..strokeWidth = 1.5 * projection.zoom,
          );
        }
      }

      final leftUv = switch (building.type) {
        BuildingType.apartment => const [
          Offset(105, 105),
          Offset(306, 150),
          Offset(306, 455),
          Offset(105, 365),
        ],
        BuildingType.hotel => const [
          Offset(95, 105),
          Offset(285, 175),
          Offset(285, 455),
          Offset(95, 365),
        ],
        BuildingType.office => const [
          Offset(100, 95),
          Offset(315, 166),
          Offset(315, 448),
          Offset(100, 365),
        ],
        BuildingType.foodCourt => const [
          Offset(85, 183),
          Offset(312, 268),
          Offset(312, 367),
          Offset(85, 287),
        ],
      };
      final rightUv = switch (building.type) {
        BuildingType.apartment => const [
          Offset(306, 150),
          Offset(424, 103),
          Offset(424, 407),
          Offset(306, 455),
        ],
        BuildingType.hotel => const [
          Offset(285, 175),
          Offset(415, 105),
          Offset(415, 365),
          Offset(285, 455),
        ],
        BuildingType.office => const [
          Offset(315, 166),
          Offset(424, 110),
          Offset(424, 375),
          Offset(315, 448),
        ],
        BuildingType.foodCourt => const [
          Offset(312, 268),
          Offset(435, 211),
          Offset(435, 310),
          Offset(312, 367),
        ],
      };
      wall(
        3,
        2,
        (projection.worldAt(base[3]) - projection.worldAt(base[2])).distance
            .round(),
        leftUv,
      );
      wall(
        2,
        1,
        (projection.worldAt(base[2]) - projection.worldAt(base[1])).distance
            .round(),
        rightUv,
      );
      final roofPath = Path()..addPolygon(roof, true);
      canvas.drawPath(
        roofPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFB5BCB6), Color(0xFF929E98)],
          ).createShader(roofPath.getBounds()),
      );
      canvas.drawPath(
        Path()..addPolygon(roof, true),
        Paint()
          ..color = const Color(0xFFE6D5B5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * projection.zoom,
      );
      // A compact service unit keeps its own proportions on either long axis.
      final unit = math.min(site.width, site.length) * .28;
      final x = site.x + site.width / 2 - unit / 2;
      final y = site.y + site.length / 2 - unit / 2;
      final bottom = projection.buildingCorners(Footprint(0, 0, 1, 1));
      for (var i = 0; i < 4; i++) {
        final dx = i == 1 || i == 2 ? unit : 0;
        final dy = i == 2 || i == 3 ? unit : 0;
        bottom[i] =
            projection.point(x + dx, y + dy) -
            Offset(
              0,
              projection.buildingHeight(
                site,
                type: building.type,
                floors: building.completedFloors,
              ),
            );
      }
      bottom.setAll(0, projection.orderCorners(bottom));
      final top = bottom
          .map((p) => p - Offset(0, projection.tile * .22))
          .toList();
      void face(List<Offset> points, Color color) {
        final path = Path()..addPolygon(points, true);
        canvas.drawPath(path, Paint()..color = color);
        canvas.drawPath(
          path,
          Paint()
            ..color = GameColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = projection.zoom,
        );
      }

      face([top[3], top[2], bottom[2], bottom[3]], const Color(0xFFD8C796));
      face([top[2], top[1], bottom[1], bottom[2]], const Color(0xFFB7AB84));
      face(top, const Color(0xFFFFFCF1));
    }
  }

  @override
  bool shouldRepaint(_DistrictPainter oldDelegate) =>
      oldDelegate.labelsOnly != labelsOnly ||
      oldDelegate.hideLabels != hideLabels ||
      oldDelegate.terrainOnly != terrainOnly ||
      oldDelegate.structuresOnly != structuresOnly ||
      oldDelegate.game != game ||
      oldDelegate.images != images ||
      oldDelegate.projection.size != projection.size ||
      oldDelegate.projection.pan != projection.pan ||
      oldDelegate.projection.zoom != projection.zoom ||
      oldDelegate.projection.rotation != projection.rotation ||
      oldDelegate.preview != preview ||
      oldDelegate.selected != selected ||
      oldDelegate.elapsedMilliseconds != elapsedMilliseconds ||
      oldDelegate.previewValid != previewValid ||
      oldDelegate.decorationPreview != decorationPreview;
}
