import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

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
  final ValueChanged<Footprint> onFootprint;
  final VoidCallback? onCancelFootprint;
  final ValueChanged<int> onSelect;
  @override
  State<DistrictMap> createState() => _DistrictMapState();
}

class _DistrictMapState extends State<DistrictMap>
    with SingleTickerProviderStateMixin {
  final _activityClock = ValueNotifier<double>(0);
  late final Ticker _activityTicker;
  double _carriedSeconds = 0;
  late final _ownedCamera = MapCameraViewModel();
  MapCameraViewModel get _camera => widget.camera ?? _ownedCamera;
  LandCell? _start;
  int? _drawingPointer;
  final _pointers = <int>{};
  bool _hadMultiTouch = false;
  Footprint? _previousPreview;
  double _gestureZoom = 1, _gestureScale = 1;
  int _scalePointers = 0;
  Offset _previousFocal = Offset.zero;
  Map<String, ui.Image> _images = {};
  static Future<Map<String, ui.Image>>? _art;

  @override
  void initState() {
    super.initState();
    _activityTicker = createTicker((elapsed) {
      _activityClock.value = _carriedSeconds + elapsed.inMicroseconds / 1000000;
    });
    _load();
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
      ProductionAssets.transportCar,
      for (final type in BuildingType.values) type.actor,
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
          targetWidth: path.contains('animation.png') ? 512 : null,
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
    if (oldWidget.reset != widget.reset) _camera.center();
    _syncActivity();
  }

  @override
  void dispose() {
    _activityTicker.dispose();
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
        final projection = MapProjection(size, _camera.pan, zoom: _camera.zoom);
        return Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              label: widget.drawing
                  ? 'Draw a footprint or select a decoration tile on the map.'
                  : 'District map. Drag to pan, pinch to zoom, tap a building.',
              child: Listener(
                onPointerDown: (event) {
                  if (_pointers.isEmpty) {
                    _hadMultiTouch = false;
                    _previousPreview = widget.preview;
                  }
                  _pointers.add(event.pointer);
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
                    _scalePointers = details.pointerCount;
                    _previousFocal = details.localFocalPoint;
                  },
                  onScaleUpdate: (details) {
                    if (_scalePointers != details.pointerCount) {
                      _gestureZoom = _camera.zoom;
                      _gestureScale = details.scale;
                      _scalePointers = details.pointerCount;
                      _previousFocal = details.localFocalPoint;
                    }
                    if (details.pointerCount >= 2 ||
                        details.pointerCount == 0) {
                      final centre = size.center(Offset.zero);
                      _camera.transform(
                        zoom: _gestureZoom * details.scale / _gestureScale,
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
                      ).reversed) {
                        final facadeHit =
                            building.shellComplete &&
                            projection
                                .buildingRect(
                                  building.footprint,
                                  type: building.type,
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
                                width: math.min(310, size.width - 104),
                                child: Text(
                                  widget.drawing
                                      ? 'Road access required · Pinch to zoom'
                                      : 'Drag to pan · Pinch to zoom · Tap a building',
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
              right: 12,
              top: 12,
              child: Material(
                color: GameColors.surface,
                borderRadius: BorderRadius.circular(8),
                child: IconButton(
                  key: const ValueKey('map-main-road'),
                  tooltip: 'Main road',
                  onPressed: () {
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
              right: 12,
              bottom: 12,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const ValueKey('map-zoom-out'),
                        tooltip: 'Zoom out',
                        constraints: const BoxConstraints.tightFor(
                          width: 48,
                          height: 48,
                        ),
                        onPressed: _camera.canZoomOut ? _camera.zoomOut : null,
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
                        onPressed: _camera.canZoomIn ? _camera.zoomIn : null,
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
  MapProjection(this.size, this.pan, {this.zoom = 1});
  final Size size;
  final Offset pan;
  final double zoom;
  double get _baseTile => size.width < 500 ? 54 : 80;
  double get tile => _baseTile * zoom;
  // Keep the starting street/plot below the hint in short viewports. This
  // offset scales with zoom, preserving the camera's focal-point transform.
  Offset get origin =>
      size.center(Offset.zero) +
      Offset(0, -math.min(_baseTile * 1.5, size.height / 2 - 64) * zoom) +
      pan;
  Offset point(num x, num y) =>
      origin + Offset((x - y) * tile / 2, (x + y) * tile / 4);
  LandCell cellAt(Offset screen) {
    final local = screen - origin;
    return LandCell(
      (local.dx / tile + 2 * local.dy / tile).floor(),
      (2 * local.dy / tile - local.dx / tile).floor(),
    );
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

  double buildingHeight(
    Footprint site, {
    BuildingType type = BuildingType.apartment,
  }) =>
      math.min(site.width, site.length) *
      tile *
      (type == BuildingType.foodCourt ? .38 : .7);

  List<Offset> buildingCorners(
    Footprint site, {
    bool roof = false,
    BuildingType type = BuildingType.apartment,
  }) =>
      [
            point(site.x, site.y),
            point(site.x + site.width, site.y),
            point(site.x + site.width, site.y + site.length),
            point(site.x, site.y + site.length),
          ]
          .map(
            (p) => p - Offset(0, roof ? buildingHeight(site, type: type) : 0),
          )
          .toList();

  /// Square references retain their sprite; rectangular geometry follows land.
  Rect buildingRect(
    Footprint site, {
    BuildingType type = BuildingType.apartment,
  }) {
    final bounds = footprint(site).getBounds();
    if (site.width != site.length) {
      return Rect.fromLTRB(
        bounds.left,
        bounds.top - buildingHeight(site, type: type),
        bounds.right,
        bounds.bottom,
      );
    }
    return Rect.fromLTWH(
      bounds.left,
      bounds.bottom - bounds.width,
      bounds.width,
      bounds.width,
    );
  }
}

List<ApartmentBuilding> _depthSorted(DistrictGame game) =>
    game.buildings.toList()..sort(
      (a, b) =>
          (a.footprint.x +
                  a.footprint.y +
                  a.footprint.width +
                  a.footprint.length)
              .compareTo(
                b.footprint.x +
                    b.footprint.y +
                    b.footprint.width +
                    b.footprint.length,
              ),
    );

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
  });
  final bool terrainOnly, structuresOnly;
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
    if (!structuresOnly) {
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
      for (var diagonal = minX + minY; diagonal <= maxX + maxY; diagonal++) {
        for (var x = minX; x <= maxX; x++) {
          final y = diagonal - x;
          if (y < minY || y > maxY) continue;
          final cell = LandCell(x, y);
          final top = projection.point(x, y);
          if (top.dx < -projection.tile ||
              top.dx > size.width + projection.tile ||
              top.dy < -projection.tile ||
              top.dy > size.height + projection.tile) {
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
            canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                0,
                0,
                image.width.toDouble(),
                image.height.toDouble(),
              ),
              Rect.fromLTWH(
                top.dx - 130 * scale,
                top.dy - 4 * scale,
                260 * scale,
                148 * scale,
              ),
              Paint()..filterQuality = FilterQuality.low,
            );
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
    final buildings = _depthSorted(game);
    for (final building in buildings) {
      final site = building.footprint;
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
    if (site.width != site.length) {
      final base = projection.buildingCorners(site);
      final roof = projection.buildingCorners(
        site,
        roof: true,
        type: building.type,
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
        for (var i = 0; i < bays; i++) {
          final a = i / bays, b = (i + 1) / bays;
          quad([
            Offset.lerp(roof[start], roof[end], a)!,
            Offset.lerp(roof[start], roof[end], b)!,
            Offset.lerp(base[start], base[end], b)!,
            Offset.lerp(base[start], base[end], a)!,
          ], uv);
        }
      }

      wall(
        3,
        2,
        site.width,
        building.type == BuildingType.foodCourt
            ? const [
                Offset(85, 150),
                Offset(330, 225),
                Offset(330, 365),
                Offset(85, 300),
              ]
            : const [
                Offset(105, 105),
                Offset(306, 150),
                Offset(306, 455),
                Offset(105, 365),
              ],
      );
      wall(
        2,
        1,
        site.length,
        building.type == BuildingType.foodCourt
            ? const [
                Offset(330, 225),
                Offset(440, 170),
                Offset(440, 300),
                Offset(330, 365),
              ]
            : const [
                Offset(306, 150),
                Offset(424, 103),
                Offset(424, 407),
                Offset(306, 455),
              ],
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
            Offset(0, projection.buildingHeight(site, type: building.type));
      }
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
      return;
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      projection.buildingRect(site),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_DistrictPainter oldDelegate) =>
      oldDelegate.terrainOnly != terrainOnly ||
      oldDelegate.structuresOnly != structuresOnly ||
      oldDelegate.game != game ||
      oldDelegate.images != images ||
      oldDelegate.projection.size != projection.size ||
      oldDelegate.projection.pan != projection.pan ||
      oldDelegate.projection.zoom != projection.zoom ||
      oldDelegate.preview != preview ||
      oldDelegate.selected != selected ||
      oldDelegate.elapsedMilliseconds != elapsedMilliseconds ||
      oldDelegate.previewValid != previewValid ||
      oldDelegate.decorationPreview != decorationPreview;
}
