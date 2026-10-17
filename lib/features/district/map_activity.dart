part of 'district_map.dart';

/// Cosmetic routes in land coordinates. Their clock never changes game income.
class MapActivityRoute {
  MapActivityRoute(Footprint site, {required bool vehicle}) {
    final inset = vehicle ? .62 : .23;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            site.x - inset,
            site.y - inset,
            site.x + site.width + inset,
            site.y + site.length + inset,
          ),
          Radius.circular(vehicle ? .3 : .16),
        ),
      );
    _metric = path.computeMetrics().first;
  }
  late final ui.PathMetric _metric;
  double get length => _metric.length;
  ui.Tangent pose(double distance) =>
      _metric.getTangentForOffset(distance % length)!;
}

class _MapActivityPainter extends CustomPainter {
  _MapActivityPainter(this.game, this.projection, this.images, this.clock)
    : super(repaint: clock);
  final DistrictGame game;
  final MapProjection projection;
  final Map<String, ui.Image> images;
  final ValueNotifier<double> clock;
  int? _sceneKey;
  List<ApartmentBuilding> _open = [];
  final _routes = <int, List<MapActivityRoute>>{};
  List<ApartmentBuilding> _occluders = [];
  final _silhouettes = <int, Path>{};

  void _prepare(Size size) {
    _routes.clear();
    _silhouettes.clear();
    final viewport = Offset.zero & size;
    final visible = _depthSorted(game)
        .where(
          (b) => projection
              .buildingRect(
                b.footprint,
                type: b.type,
                floors: b.completedFloors,
              )
              .inflate(projection.tile)
              .overlaps(viewport),
        )
        .toList();
    _occluders = visible;
    for (final b in visible) {
      _silhouettes[b.id] = projection.buildingSilhouette(
        b.footprint,
        type: b.type,
        floors: b.completedFloors,
      );
    }
    _open = visible
        .where((b) => b.stage == ConstructionStage.ready)
        .take(12)
        .toList();
    for (final building in _open) {
      _routes[building.id] = [
        MapActivityRoute(building.footprint, vehicle: false),
        MapActivityRoute(building.footprint, vehicle: true),
      ];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final key = Object.hash(
      size,
      projection.pan,
      projection.zoom,
      Object.hashAll(
        game.buildings.map(
          (b) => Object.hash(
            b.id,
            b.type,
            b.stage,
            b.completedFloors,
            b.footprint.x,
            b.footprint.y,
            b.footprint.width,
            b.footprint.length,
          ),
        ),
      ),
    );
    if (_sceneKey != key) {
      _sceneKey = key;
      _prepare(size);
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final actors =
        <
          ({
            Offset point,
            Offset direction,
            Offset world,
            ApartmentBuilding building,
            int actor,
          })
        >[];
    for (final building in _open) {
      for (var actor = 0; actor < 3; actor++) {
        final car = actor == 2;
        final route = _routes[building.id]![car ? 1 : 0];
        final speed = car ? 1.2 : .42;
        final reverse = actor == 1 ? -1 : 1;
        final tangent = route.pose(
          route.length * ((building.id * .173 + actor * .37) % 1) +
              clock.value * speed * reverse,
        );
        final vector = tangent.vector * reverse.toDouble();
        actors.add((
          point: projection.point(tangent.position.dx, tangent.position.dy),
          direction: vector,
          world: tangent.position,
          building: building,
          actor: actor,
        ));
      }
    }
    actors.sort((a, b) => a.point.dy.compareTo(b.point.dy));
    for (final actor in actors) {
      final car = actor.actor == 2;
      final zoom = projection.zoom;
      canvas.save();
      // A front-side pedestrian must stay in front of the facade. Clip only
      // buildings lying between its world position and the isometric camera.
      final behind = _occluders
          .where(
            (b) =>
                actor.world.dx < b.footprint.x + b.footprint.width &&
                actor.world.dy < b.footprint.y + b.footprint.length,
          )
          .toList();
      final heading = math.atan2(actor.direction.dy, actor.direction.dx);
      final mesh = car
          ? CityFigure.car(heading)
          : CityFigure.walker(
              actor.building.type,
              heading,
              clock.value * 6 + actor.actor * math.pi,
            );
      final scale = projection.tile * (car ? 1 : .72);
      final shadow = Rect.fromCenter(
        center: actor.point,
        width: (car ? 29 : 11) * zoom,
        height: (car ? 10 : 5) * zoom,
      );
      final bounds = mesh
          .bounds(scale)
          .shift(actor.point)
          .expandToInclude(shadow)
          .inflate(2);
      // Clear occluded pixels on a small transparent actor layer. This avoids
      // backend-dependent differences from a compound inverse clip path.
      canvas.saveLayer(bounds, Paint());
      canvas.save();
      canvas.translate(actor.point.dx, actor.point.dy);
      canvas.drawOval(
        shadow.shift(-actor.point),
        Paint()..color = const Color(0x330E3540),
      );
      mesh.paint(canvas, scale);
      canvas.restore();
      final erase = Paint()..blendMode = BlendMode.dstOut;
      for (final b in behind) {
        final silhouette = _silhouettes[b.id]!;
        if (silhouette.getBounds().overlaps(bounds)) {
          canvas.drawPath(silhouette, erase);
        }
      }
      canvas.restore();
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MapActivityPainter old) =>
      old.game != game || old.projection != projection || old.images != images;
}
