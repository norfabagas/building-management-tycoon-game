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
  Size? _sceneSize;
  List<ApartmentBuilding> _open = [];
  final _routes = <int, List<MapActivityRoute>>{};

  void _prepare(Size size) {
    final viewport = Offset.zero & size;
    final visible = _depthSorted(game)
        .where(
          (b) => projection
              .buildingRect(b.footprint, type: b.type)
              .inflate(projection.tile)
              .overlaps(viewport),
        )
        .toList();
    _open = visible
        .where((b) => b.stage == ConstructionStage.ready)
        .take(24)
        .toList();
    for (final building in _open) {
      _routes[building.id] = [
        MapActivityRoute(building.footprint, vehicle: false),
        MapActivityRoute(building.footprint, vehicle: true),
      ];
    }
    _sceneSize = size;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_sceneSize != size) _prepare(size);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final actors =
        <
          ({
            Offset point,
            Offset direction,
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
          direction: Offset(vector.dx - vector.dy, (vector.dx + vector.dy) / 2),
          building: building,
          actor: actor,
        ));
      }
    }
    actors.sort((a, b) => a.point.dy.compareTo(b.point.dy));
    for (final actor in actors) {
      final car = actor.actor == 2;
      final image =
          images[car
              ? ProductionAssets.transportCar
              : actor.building.type.actor];
      if (image == null) continue;
      final zoom = projection.zoom;
      canvas.save();
      canvas.translate(actor.point.dx, actor.point.dy);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -zoom),
          width: (car ? 25 : 8) * zoom,
          height: (car ? 7 : 3) * zoom,
        ),
        Paint()..color = const Color(0x330E3540),
      );
      if (car) {
        // Keep the body upright while its wheelbase follows the isometric lane.
        final direction = actor.direction / actor.direction.distance;
        final sign = direction.dx < 0 ? -1.0 : 1.0;
        canvas.transform(
          Float64List.fromList([
            direction.dx.abs(),
            direction.dy * sign,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
          ]),
        );
        canvas.scale(sign, 1);
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(-21 * zoom, -23.625 * zoom, 42 * zoom, 23.625 * zoom),
          Paint()..filterQuality = FilterQuality.low,
        );
      } else {
        // manifest: 4 columns, 256×384 frames, walk 4–11 at 8 fps;
        // pivot y=364/384 keeps feet on the pavement at every decode size.
        final frame =
            4 +
            ((clock.value * 8).floor() + actor.actor * 3 + actor.building.id) %
                8;
        final width = image.width / 4, height = image.height / 4;
        canvas.scale(actor.direction.dx < 0 ? -1 : 1, 1);
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(frame % 4 * width, frame ~/ 4 * height, width, height),
          Rect.fromLTWH(-10 * zoom, -28.4375 * zoom, 20 * zoom, 30 * zoom),
          Paint()..filterQuality = FilterQuality.low,
        );
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MapActivityPainter old) =>
      old.game != game || old.projection != projection || old.images != images;
}
