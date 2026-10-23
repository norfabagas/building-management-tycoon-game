part of 'district_map.dart';

enum CityVehicle { car, bus, truck, van }

/// Actual XYZ geometry, projected by the same isometric camera as the streets.
class CityVertex {
  const CityVertex(this.x, this.y, this.z);
  final double x, y, z;
  CityVertex operator +(CityVertex b) => CityVertex(x + b.x, y + b.y, z + b.z);
  CityVertex operator -(CityVertex b) => CityVertex(x - b.x, y - b.y, z - b.z);
  CityVertex operator *(double s) => CityVertex(x * s, y * s, z * s);
  double dot(CityVertex b) => x * b.x + y * b.y + z * b.z;
  CityVertex cross(CityVertex b) =>
      CityVertex(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);
  CityVertex get unit => this * (1 / math.sqrt(dot(this)));
  CityVertex turn(double angle) => CityVertex(
    x * math.cos(angle) - y * math.sin(angle),
    x * math.sin(angle) + y * math.cos(angle),
    z,
  );
  Offset project(double tile) =>
      Offset((x - y) * tile / 2, (x + y) * tile / 4 - z * tile / 2);
}

class CityFace {
  CityFace(this.vertices, this.normal, this.color);
  final List<CityVertex> vertices;
  final CityVertex normal;
  final Color color;
  double get depth =>
      vertices.fold<double>(0, (sum, p) => sum + p.x + p.y + p.z) /
      vertices.length;
}

class CityFigure {
  CityFigure._(this.faces);
  final List<CityFace> faces;
  Rect bounds(double tile) {
    final p = faces.expand((f) => f.vertices).map((p) => p.project(tile));
    return Rect.fromLTRB(
      p.map((v) => v.dx).reduce(math.min),
      p.map((v) => v.dy).reduce(math.min),
      p.map((v) => v.dx).reduce(math.max),
      p.map((v) => v.dy).reduce(math.max),
    );
  }

  factory CityFigure.walker(BuildingType type, double heading, double stride) {
    final model = _FigureBuilder();
    final shirt = switch (type) {
      BuildingType.apartment => const Color(0xFF39AFC0),
      BuildingType.hotel => const Color(0xFFEBAA55),
      BuildingType.office => const Color(0xFF416B89),
      BuildingType.foodCourt => const Color(0xFFCE745D),
    };
    const skin = Color(0xFFE4B283),
        pants = Color(0xFF344E60),
        shoe = Color(0xFF243D3E);
    final bob = .008 * (1 - math.cos(stride * 2));
    for (final side in [-1.0, 1.0]) {
      final step = math.sin(stride + (side < 0 ? math.pi : 0));
      final foot = CityVertex(
        step * .105,
        side * .06,
        .035 + math.max(0, math.cos(stride + (side < 0 ? math.pi : 0))) * .025,
      );
      final hip = CityVertex(0, side * .06, .36 + bob);
      final knee = CityVertex(step * .05 + .025, side * .06, .20 + bob);
      model.limb(hip, knee, .037, pants);
      model.limb(knee, foot, .033, pants);
      model.box(
        foot + const CityVertex(.025, 0, 0),
        const CityVertex(.13, .085, .055),
        shoe,
      );
      final shoulder = CityVertex(0, side * .142, .58 + bob);
      final elbow = CityVertex(-step * .045, side * .15, .46 + bob);
      final hand = CityVertex(-step * .095, side * .145, .36 + bob);
      model.limb(shoulder, elbow, .038, shirt);
      model.limb(elbow, hand, .029, skin);
    }
    model.box(
      CityVertex(0, 0, .46 + bob),
      const CityVertex(.15, .24, .23),
      shirt,
    );
    model.box(
      CityVertex(0, 0, .355 + bob),
      const CityVertex(.145, .20, .09),
      pants,
    );
    model.sphere(CityVertex(0, 0, .668 + bob), .105, skin);
    model.sphere(
      CityVertex(-.014, 0, .724 + bob),
      .093,
      const Color(0xFF514334),
      upperOnly: true,
    );
    // Nose and eyes live on the forward side of the head, rotating with it.
    model.box(
      CityVertex(.102, 0, .668 + bob),
      const CityVertex(.035, .045, .035),
      skin,
    );
    for (final side in [-1.0, 1.0]) {
      model.box(
        CityVertex(.094, side * .039, .695 + bob),
        const CityVertex(.015, .018, .018),
        shoe,
      );
    }
    if (type == BuildingType.office) {
      model.box(
        CityVertex(.079, 0, .50 + bob),
        const CityVertex(.012, .025, .13),
        const Color(0xFFFFFCF1),
      );
    }
    return model.finish(heading);
  }

  factory CityFigure.car(
    double heading, {
    CityVehicle kind = CityVehicle.car,
    Color color = const Color(0xFF328FAE),
  }) {
    final model = _FigureBuilder();
    final blue = color;
    const glass = Color(0xFFA6D7D5);
    if (kind != CityVehicle.car) {
      final length = kind == CityVehicle.bus ? 1.12 : .94;
      model.box(
        const CityVertex(0, 0, .15),
        CityVertex(length, .36, .18),
        blue,
      );
      if (kind == CityVehicle.truck) {
        model.box(
          const CityVertex(-.14, 0, .36),
          const CityVertex(.62, .35, .35),
          const Color(0xFFF2E8CD),
        );
        model.box(
          const CityVertex(.33, 0, .31),
          const CityVertex(.27, .33, .24),
          blue,
        );
      } else {
        model.box(
          const CityVertex(-.02, 0, .35),
          CityVertex(length - .08, .33, .30),
          blue,
        );
      }
      model.box(
        CityVertex(length / 2 - .035, 0, .39),
        const CityVertex(.014, .28, .13),
        glass,
      );
      for (final side in [-1.0, 1.0]) {
        for (var i = 0; i < (kind == CityVehicle.bus ? 5 : 1); i++) {
          model.box(
            CityVertex(length / 2 - .15 - i * .18, side * .173, .40),
            const CityVertex(.13, .012, .13),
            glass,
          );
        }
        for (final x in [-length * .32, length * .32]) {
          model.limb(
            CityVertex(x, side * .18 - .025, .08),
            CityVertex(x, side * .18 + .025, .08),
            .08,
            const Color(0xFF243D3E),
          );
        }
        model.box(
          CityVertex(length / 2, side * .11, .18),
          const CityVertex(.016, .07, .045),
          const Color(0xFFFFF1BE),
        );
      }
      return model.finish(heading);
    }

    model.box(
      const CityVertex(0, 0, .12),
      const CityVertex(.78, .35, .15),
      blue,
    );
    model.box(
      const CityVertex(-.04, 0, .245),
      const CityVertex(.39, .30, .16),
      blue,
    );
    model.box(
      const CityVertex(-.04, -.156, .25),
      const CityVertex(.30, .012, .10),
      glass,
    );
    model.box(
      const CityVertex(-.04, .156, .25),
      const CityVertex(.30, .012, .10),
      glass,
    );
    model.box(
      const CityVertex(.161, 0, .25),
      const CityVertex(.014, .25, .10),
      glass,
    );
    for (final x in [-.25, .25]) {
      for (final y in [-.18, .18]) {
        model.limb(
          CityVertex(x, y - .026, .077),
          CityVertex(x, y + .026, .077),
          .078,
          const Color(0xFF243D3E),
        );
      }
    }
    for (final side in [-1.0, 1.0]) {
      model.box(
        CityVertex(.397, side * .11, .13),
        const CityVertex(.015, .075, .045),
        const Color(0xFFFFF1BE),
      );
      model.box(
        CityVertex(-.397, side * .11, .13),
        const CityVertex(.015, .07, .04),
        const Color(0xFFD97961),
      );
    }
    return model.finish(heading);
  }

  void paint(Canvas canvas, double tile) {
    const light = CityVertex(-.45, -.65, .9);
    final paint = Paint()..isAntiAlias = true;
    for (final face in faces) {
      // Cull back faces. XYZ normals preserve volume at every road heading.
      if (face.normal.dot(const CityVertex(1, 1, 1)) <= .001) continue;
      final shade = (.76 + .28 * face.normal.dot(light.unit)).clamp(.48, 1.0);
      final c = face.color;
      paint.color = Color.fromARGB(
        255,
        (c.r * 255 * shade).round(),
        (c.g * 255 * shade).round(),
        (c.b * 255 * shade).round(),
      );
      canvas.drawPath(
        Path()..addPolygon(
          face.vertices.map((v) => v.project(tile)).toList(),
          true,
        ),
        paint,
      );
    }
  }
}

class _FigureBuilder {
  final faces = <CityFace>[];
  void face(List<CityVertex> points, Color color, CityVertex centre) {
    var normal = (points[1] - points[0]).cross(points[2] - points[0]).unit;
    if (normal.dot(points[0] - centre) < 0) normal = normal * -1;
    faces.add(CityFace(points, normal, color));
  }

  void box(CityVertex centre, CityVertex size, Color color) {
    final p = [
      for (final z in [-1.0, 1.0])
        for (final xy in [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)])
          centre +
              CityVertex(
                xy.$1 * size.x / 2,
                xy.$2 * size.y / 2,
                z * size.z / 2,
              ),
    ];
    for (final indices in [
      [0, 1, 2, 3],
      [4, 5, 6, 7],
      [0, 1, 5, 4],
      [1, 2, 6, 5],
      [2, 3, 7, 6],
      [3, 0, 4, 7],
    ]) {
      face(indices.map((i) => p[i]).toList(), color, centre);
    }
  }

  void limb(CityVertex a, CityVertex b, double radius, Color color) {
    final axis = (b - a).unit;
    final u = axis
        .cross(
          axis.z.abs() < .9
              ? const CityVertex(0, 0, 1)
              : const CityVertex(1, 0, 0),
        )
        .unit;
    final v = axis.cross(u).unit;
    CityVertex rim(CityVertex p, int i) =>
        p +
        (u * math.cos(i * math.pi / 3) + v * math.sin(i * math.pi / 3)) *
            radius;
    final centre = (a + b) * .5;
    for (var i = 0; i < 6; i++) {
      face([rim(a, i), rim(a, i + 1), rim(b, i + 1), rim(b, i)], color, centre);
    }
    face([for (var i = 0; i < 6; i++) rim(a, i)], color, centre);
    face([for (var i = 0; i < 6; i++) rim(b, i)], color, centre);
  }

  void sphere(
    CityVertex centre,
    double radius,
    Color color, {
    bool upperOnly = false,
  }) {
    CityVertex point(int ring, int i) {
      final angle = -.5 * math.pi + ring * math.pi / 4;
      // Tiny polar caps avoid degenerate polygons and unstable normals.
      final r = math.max(.001, math.cos(angle)) * radius;
      return centre +
          CityVertex(
            math.cos(i * math.pi / 4) * r,
            math.sin(i * math.pi / 4) * r,
            math.sin(angle) * radius,
          );
    }

    for (var ring = upperOnly ? 2 : 0; ring < 4; ring++) {
      for (var i = 0; i < 8; i++) {
        face(
          [
            point(ring, i),
            point(ring, i + 1),
            point(ring + 1, i + 1),
            point(ring + 1, i),
          ],
          color,
          centre,
        );
      }
    }
  }

  CityFigure finish(double heading) {
    final rotated =
        faces
            .map(
              (f) => CityFace(
                f.vertices.map((p) => p.turn(heading)).toList(),
                f.normal.turn(heading),
                f.color,
              ),
            )
            .toList()
          ..sort((a, b) => a.depth.compareTo(b.depth));
    return CityFigure._(rotated);
  }
}
