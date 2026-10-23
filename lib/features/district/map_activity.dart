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

/// Infinite, stable lane slots; panning never respawns or teleports a vehicle.
class HighwayTraffic {
  static ({Offset position, Offset direction, CityVehicle kind}) sample(
    int mainRow,
    int lane,
    int slot,
    double seconds,
  ) {
    final direction = lane == 0 ? 1.0 : -1.0;
    final jitter = ((slot * 37 + lane * 19) % 11) / 10;
    return (
      position: Offset(
        slot * 7 + jitter + seconds * direction * 1.5,
        mainRow + .5 + lane,
      ),
      direction: Offset(direction, 0),
      kind: CityVehicle.values[(slot * 13 + lane) % CityVehicle.values.length],
    );
  }
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
    final visible = _depthSorted(game, projection)
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
      projection.rotation,
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
            ApartmentBuilding? building,
            int actor,
          })
        >[];
    for (final building in _open) {
      for (var actor = 0; actor < 5; actor++) {
        final car = actor >= 2;
        final route = _routes[building.id]![car ? 1 : 0];
        final speed = car
            ? .85 + ((building.id * 7 + actor * 3) % 6) * .12
            : .42;
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
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map(projection.worldAt);
    final minX = corners.map((p) => p.dx).reduce(math.min) - 2;
    final maxX = corners.map((p) => p.dx).reduce(math.max) + 2;
    for (var lane = 0; lane < 2; lane++) {
      final shift = clock.value * (lane == 0 ? 1.5 : -1.5);
      final first = ((minX - shift - 1) / 7).floor();
      final last = ((maxX - shift) / 7).ceil();
      for (var slot = first; slot <= last && slot < first + 64; slot++) {
        final pose = HighwayTraffic.sample(
          game.roadNetwork.mainRow,
          lane,
          slot,
          clock.value,
        );
        final point = projection.point(pose.position.dx, pose.position.dy);
        if (!Rect.fromLTWH(
          -80,
          -80,
          size.width + 160,
          size.height + 160,
        ).contains(point)) {
          continue;
        }
        actors.add((
          point: point,
          direction: pose.direction,
          world: pose.position,
          building: null,
          actor: 2 + pose.kind.index,
        ));
      }
    }
    actors.sort((a, b) => a.point.dy.compareTo(b.point.dy));
    for (final actor in actors) {
      final car = actor.actor >= 2;
      final zoom = projection.zoom;
      canvas.save();
      // A front-side pedestrian must stay in front of the facade. Clip only
      // buildings lying between its world position and the isometric camera.
      final behind = _occluders
          .where((b) => projection.occludesPoint(b.footprint, actor.world))
          .toList();
      final heading =
          math.atan2(actor.direction.dy, actor.direction.dx) +
          projection.rotation;
      final mesh = car
          ? CityFigure.car(
              heading,
              kind: CityVehicle
                  .values[((actor.building?.id ?? 0) + actor.actor - 2) % 4],
              color: const [
                Color(0xFF328FAE),
                Color(0xFFEBAA55),
                Color(0xFFCE745D),
                Color(0xFF65A284),
              ][((actor.building?.id ?? 0) * 3 + actor.actor) % 4],
            )
          : CityFigure.walker(
              actor.building!.type,
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
