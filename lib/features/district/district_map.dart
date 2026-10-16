import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../app/game_theme.dart';
import '../../app/production_assets.dart';
import '../../domain/district_game.dart';
import 'map_camera_view_model.dart';
import 'daylight.dart';

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
  });
  final DistrictGame game;
  final bool drawing;
  final Footprint? preview;
  final int? selected;
  final int reset;
  final int elapsedMilliseconds;
  final ValueChanged<Footprint> onFootprint;
  final VoidCallback? onCancelFootprint;
  final ValueChanged<int> onSelect;
  @override
  State<DistrictMap> createState() => _DistrictMapState();
}

class _DistrictMapState extends State<DistrictMap> {
  final _camera = MapCameraViewModel();
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
    _load();
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
    if (oldWidget.reset != widget.reset) _camera.center();
  }

  @override
  void dispose() {
    _camera.dispose();
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
                  ? 'Draw apartment footprint by dragging on the map.'
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
                                .buildingRect(building.footprint)
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
                          child: CustomPaint(
                            painter: _DistrictPainter(
                              widget.game,
                              projection,
                              _images,
                              widget.preview,
                              widget.selected,
                              widget.elapsedMilliseconds,
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
                              child: Text(
                                widget.drawing
                                    ? 'Drag to select land · Pinch to zoom'
                                    : 'Drag to pan · Pinch to zoom · Tap a building',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: GameColors.ink,
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
  double get tile => (size.width < 500 ? 54 : 80) * zoom;
  Offset get origin =>
      Offset(size.width / 2, size.height / 2 - tile * 1.5) + pan;
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

  double buildingHeight(Footprint site) =>
      math.min(site.width, site.length) * tile * .7;

  List<Offset> buildingCorners(Footprint site, {bool roof = false}) => [
    point(site.x, site.y),
    point(site.x + site.width, site.y),
    point(site.x + site.width, site.y + site.length),
    point(site.x, site.y + site.length),
  ].map((p) => p - Offset(0, roof ? buildingHeight(site) : 0)).toList();

  /// Square references retain their sprite; rectangular geometry follows land.
  Rect buildingRect(Footprint site) {
    final bounds = footprint(site).getBounds();
    if (site.width != site.length) {
      return Rect.fromLTRB(
        bounds.left,
        bounds.top - buildingHeight(site),
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
  );
  final DistrictGame game;
  final MapProjection projection;
  final Map<String, ui.Image> images;
  final Footprint? preview;
  final int? selected;
  final int elapsedMilliseconds;

  @override
  void paint(Canvas canvas, Size size) {
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
    final roads = game.roads;
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
        if (roads.contains(cell)) {
          var mask = 0;
          if (roads.contains(LandCell(x, y - 1))) mask |= 1;
          if (roads.contains(LandCell(x + 1, y))) mask |= 2;
          if (roads.contains(LandCell(x, y + 1))) mask |= 4;
          if (roads.contains(LandCell(x - 1, y))) mask |= 8;
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
              ..color = roads.contains(cell)
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
          images.containsKey(ProductionAssets.buildingsApartment)) {
        _apartment(canvas, site);
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
              ? 'Apartment ${building.id}'
              : 'Apartment ${building.id} · ${building.upgrade != null ? 'Upgrade · ' : ''}${(progress * 100).floor()}%',
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
    if (preview case final site?) {
      final valid = DistrictSimulation.placementError(game, site) == null;
      final color = valid ? GameColors.primary : GameColors.danger;
      for (final cell in site.roadRing) {
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
  void _apartment(Canvas canvas, Footprint site) {
    final image = images[ProductionAssets.buildingsApartment]!;
    if (site.width != site.length) {
      final base = projection.buildingCorners(site);
      final roof = projection.buildingCorners(site, roof: true);
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

      wall(3, 2, site.width, const [
        Offset(105, 105),
        Offset(306, 150),
        Offset(306, 455),
        Offset(105, 365),
      ]);
      wall(2, 1, site.length, const [
        Offset(306, 150),
        Offset(424, 103),
        Offset(424, 407),
        Offset(306, 455),
      ]);
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
            Offset(0, projection.buildingHeight(site));
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
      oldDelegate.game != game ||
      oldDelegate.images != images ||
      oldDelegate.projection.size != projection.size ||
      oldDelegate.projection.pan != projection.pan ||
      oldDelegate.projection.zoom != projection.zoom ||
      oldDelegate.preview != preview ||
      oldDelegate.selected != selected ||
      oldDelegate.elapsedMilliseconds != elapsedMilliseconds;
}
