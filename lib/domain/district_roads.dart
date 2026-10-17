part of 'district_game.dart';

/// Inclusive tile-centre street segments; long legacy links stay compact.
class RoadSegment {
  const RoadSegment(this.x1, this.y1, this.x2, this.y2);
  final int x1, y1, x2, y2;
  int get left => math.min(x1, x2);
  int get right => math.max(x1, x2);
  int get top => math.min(y1, y2);
  int get bottom => math.max(y1, y2);
  bool contains(LandCell cell) =>
      cell.x >= left && cell.x <= right && cell.y >= top && cell.y <= bottom;
  bool intersects(Footprint site) =>
      left < site.x + site.width &&
      right >= site.x &&
      top < site.y + site.length &&
      bottom >= site.y;
  bool touches(RoadSegment other) {
    final dx = math.max(0, math.max(left - other.right, other.left - right));
    final dy = math.max(0, math.max(top - other.bottom, other.top - bottom));
    return dx + dy <= 1;
  }

  List<int> toJson() => [x1, y1, x2, y2];
  factory RoadSegment.fromJson(List<dynamic> value) {
    if (value.length != 4 ||
        value.any((v) => v is! int) ||
        (value[0] != value[2] && value[1] != value[3])) {
      throw const FormatException('Invalid street segment');
    }
    return RoadSegment(
      value[0] as int,
      value[1] as int,
      value[2] as int,
      value[3] as int,
    );
  }
  static List<RoadSegment> ring(Footprint site) => [
    RoadSegment(site.x - 1, site.y - 1, site.x + site.width, site.y - 1),
    RoadSegment(
      site.x + site.width,
      site.y - 1,
      site.x + site.width,
      site.y + site.length,
    ),
    RoadSegment(
      site.x - 1,
      site.y + site.length,
      site.x + site.width,
      site.y + site.length,
    ),
    RoadSegment(site.x - 1, site.y - 1, site.x - 1, site.y + site.length),
  ];
}

class DistrictRoadNetwork {
  DistrictRoadNetwork({
    this.mainRow = -3,
    Iterable<RoadSegment> streets = const [],
  }) : streets = streets.toList();
  final int mainRow;
  final List<RoadSegment> streets;
  int? _connectedKey;
  List<RoadSegment> _connected = const [];
  bool isMain(LandCell cell) => cell.y == mainRow || cell.y == mainRow + 1;
  bool contains(LandCell cell) =>
      isMain(cell) || streets.any((s) => s.contains(cell));
  bool blocks(Footprint site) =>
      (site.y <= mainRow + 1 && site.y + site.length > mainRow) ||
      streets.any((s) => s.intersects(site));
  bool _touchesMain(RoadSegment s) =>
      s.top <= mainRow + 2 && s.bottom >= mainRow - 1;

  List<RoadSegment> connected(Iterable<ApartmentBuilding> buildings) {
    final all = [
      ...streets,
      for (final building in buildings) ...RoadSegment.ring(building.footprint),
    ];
    final key = Object.hash(
      mainRow,
      Object.hashAll(all.map((s) => Object.hash(s.x1, s.y1, s.x2, s.y2))),
    );
    if (_connectedKey == key) return _connected;
    final reached = <int>{};
    final queue = <int>[];
    for (var i = 0; i < all.length; i++) {
      if (_touchesMain(all[i])) {
        reached.add(i);
        queue.add(i);
      }
    }
    for (var cursor = 0; cursor < queue.length; cursor++) {
      for (var i = 0; i < all.length; i++) {
        if (!reached.contains(i) && all[queue[cursor]].touches(all[i])) {
          reached.add(i);
          queue.add(i);
        }
      }
    }
    _connectedKey = key;
    return _connected = List.unmodifiable(queue.map((i) => all[i]));
  }

  bool serves(Footprint site, Iterable<ApartmentBuilding> buildings) {
    final reached = connected(buildings);
    return RoadSegment.ring(site)
        .any((s) => _touchesMain(s) || reached.any(s.touches));
  }

  Map<String, Object> toJson() => {
    'mainRow': mainRow,
    'streets': streets.map((s) => s.toJson()).toList(),
  };
  factory DistrictRoadNetwork.fromJson(Map<String, dynamic> json) =>
      DistrictRoadNetwork(
        mainRow: json['mainRow'] as int,
        streets: (json['streets'] as List).map(
          (s) => RoadSegment.fromJson(s as List),
        ),
      );

  /// One-time import of existing districts, routing outside saved plots/decor.
  static DistrictRoadNetwork forExisting(
    List<ApartmentBuilding> buildings,
    List<DistrictDecoration> decorations,
  ) {
    final obstacles = [
      for (final b in buildings) b.footprint,
      for (final d in decorations) Footprint(d.cell.x, d.cell.y, 1, 1),
    ];
    if (obstacles.isEmpty) return DistrictRoadNetwork();
    final network = DistrictRoadNetwork(
      mainRow: obstacles.map((o) => o.y).reduce(math.min) - 3,
    );
    final router = _LegacyStreetRouter(obstacles, network.mainRow + 1);
    final ordered = buildings.toList()..sort((a, b) => a.id.compareTo(b.id));
    for (final building in ordered) {
      if (!network.serves(building.footprint, buildings)) {
        network.streets.addAll(
          router.route(
            LandCell(building.footprint.x - 1, building.footprint.y - 1),
          ),
        );
      }
    }
    return network;
  }
}

/// Sparse rectilinear grid: coordinate distance does not allocate extra cells.
class _LegacyStreetRouter {
  _LegacyStreetRouter(this.obstacles, this.targetY) {
    xs = {
      for (final o in obstacles) ...[o.x - 1, o.x + o.width],
    }.toList()..sort();
    ys = {
      targetY,
      for (final o in obstacles) ...[o.y - 1, o.y + o.length],
    }.toList()..sort();
  }
  final List<Footprint> obstacles;
  final int targetY;
  late final List<int> xs, ys;
  List<RoadSegment> route(LandCell start) {
    final first = ys.indexOf(start.y) * xs.length + xs.indexOf(start.x);
    final queue = [first];
    final previous = <int, int>{first: -1};
    LandCell point(int node) =>
        LandCell(xs[node % xs.length], ys[node ~/ xs.length]);
    int? goal;
    for (var cursor = 0; cursor < queue.length; cursor++) {
      final node = queue[cursor], x = node % xs.length, y = node ~/ xs.length;
      if (ys[y] == targetY) {
        goal = node;
        break;
      }
      for (final next in [
        if (y > 0) node - xs.length,
        if (x > 0) node - 1,
        if (x + 1 < xs.length) node + 1,
        if (y + 1 < ys.length) node + xs.length,
      ]) {
        if (previous.containsKey(next)) continue;
        final a = point(node), b = point(next);
        final edge = RoadSegment(a.x, a.y, b.x, b.y);
        if (obstacles.any(edge.intersects)) continue;
        previous[next] = node;
        queue.add(next);
      }
    }
    if (goal == null) {
      throw const FormatException(
        'Existing district has no safe street access',
      );
    }
    final path = <LandCell>[];
    for (var node = goal; node != -1; node = previous[node]!) {
      path.add(point(node));
    }
    final result = <RoadSegment>[];
    for (var i = path.length - 1; i > 0; i--) {
      final a = path[i], b = path[i - 1];
      result.add(RoadSegment(a.x, a.y, b.x, b.y));
    }
    return result;
  }
}
