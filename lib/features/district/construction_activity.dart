part of 'district_map.dart';

/// Presentation of existing jobs; it never advances construction or charges money.
class BuildingWork {
  const BuildingWork({
    required this.working,
    required this.elevated,
    required this.label,
  });
  final bool working, elevated;
  final String label;

  static BuildingWork? forBuilding(ApartmentBuilding building) {
    final upgrade = building.upgrade;
    if (upgrade != null) {
      return BuildingWork(
        working: upgrade.stage == UpgradeStage.building,
        elevated: upgrade.kind != BuildingUpgrade.basement,
        label: '${upgrade.kind.label} · ${upgrade.stage.label}',
      );
    }
    if (building.stage.index >= ConstructionStage.parkingDone.index) {
      return null;
    }
    return BuildingWork(
      working:
          building.stage == ConstructionStage.shell ||
          building.stage == ConstructionStage.basement,
      elevated: building.stage.index <= ConstructionStage.shell.index,
      label: building.status,
    );
  }
}

class ConstructionActivityPainter extends CustomPainter {
  ConstructionActivityPainter(this.game, this.projection, this.clock)
    : super(repaint: clock);
  final DistrictGame game;
  final MapProjection projection;
  final ValueListenable<double> clock;

  Iterable<ApartmentBuilding> _visible(Size size) =>
      _depthSorted(game, projection).where(
        (b) =>
            BuildingWork.forBuilding(b) != null &&
            projection
                .buildingRect(
                  b.footprint,
                  type: b.type,
                  floors: b.completedFloors,
                )
                .inflate(projection.tile * 2)
                .overlaps(Offset.zero & size),
      );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final building in _visible(size)) {
      canvas.save();
      final centre = Offset(
        building.footprint.x + building.footprint.width / 2,
        building.footprint.y + building.footprint.length / 2,
      );
      for (final other in game.buildings) {
        if (other.id != building.id &&
            other.shellComplete &&
            projection.occludesPoint(other.footprint, centre)) {
          final silhouette = projection.buildingSilhouette(
            other.footprint,
            type: other.type,
            floors: other.completedFloors,
          );
          canvas.clipPath(
            Path.combine(
              ui.PathOperation.difference,
              Path()..addRect(Offset.zero & size),
              silhouette,
            ),
          );
        }
      }
      final work = BuildingWork.forBuilding(building)!;
      final tile = projection.tile;
      final base = projection.buildingCorners(building.footprint);
      final height = work.elevated
          ? projection.buildingHeight(
                  building.footprint,
                  type: building.type,
                  floors: math.max(1, building.completedFloors),
                ) +
                (building.upgrade?.kind == BuildingUpgrade.floor
                    ? tile * .45
                    : 0)
          : tile * .35;
      final frame = Paint()
        ..color = const Color(0xDDDEA849)
        ..strokeWidth = 1.5 * projection.zoom
        ..strokeCap = StrokeCap.round;
      // Open front scaffolding keeps the actual completed facade visible.
      for (final edge in [1, 2]) {
        final a = base[edge], b = base[edge + 1];
        canvas.drawLine(a, a - Offset(0, height), frame);
        canvas.drawLine(b, b - Offset(0, height), frame);
        for (var level = 1; level <= 3; level++) {
          final lift = Offset(0, height * level / 3);
          canvas.drawLine(a - lift, b - lift, frame);
          canvas.drawLine(
            a - lift,
            b - Offset(0, height * (level - 1) / 3),
            frame..color = const Color(0x99968B69),
          );
          frame.color = const Color(0xDDDEA849);
        }
      }
      final phase = clock.value + building.id * .63;
      final motion = work.working ? phase : 0.0;
      final mastBase = base[3] + Offset(-tile * .16, 0);
      final mastTop = mastBase - Offset(0, height + tile * .65);
      final arm =
          mastTop +
          Offset(tile * (.65 + .07 * math.sin(motion * 1.7)), -tile * .1);
      frame
        ..color = const Color(0xFFE6B04D)
        ..strokeWidth = 3 * projection.zoom;
      canvas.drawLine(mastBase, mastTop, frame);
      canvas.drawLine(mastTop - Offset(tile * .16, 0), arm, frame);
      canvas.drawLine(
        mastTop - Offset(0, tile * .18),
        arm,
        frame..strokeWidth = projection.zoom,
      );
      final ropeStart = Offset.lerp(mastTop, arm, .72)!;
      final hook =
          ropeStart + Offset(0, tile * (.30 + .09 * math.sin(motion * 2.2)));
      canvas.drawLine(
        ropeStart,
        hook,
        Paint()
          ..color = GameColors.ink
          ..strokeWidth = projection.zoom,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: hook,
          width: 7 * projection.zoom,
          height: 8 * projection.zoom,
        ),
        0,
        math.pi * 1.3,
        false,
        Paint()
          ..color = GameColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * projection.zoom,
      );
      final glow = .4 + .2 * math.sin(phase * 2);
      canvas.drawCircle(
        mastTop,
        5 * projection.zoom,
        Paint()..color = const Color(0xFFFFD875).withValues(alpha: glow),
      );
      if (work.working) {
        for (var i = 0; i < 3; i++) {
          final age = (phase * .6 + i / 3) % 1;
          final point =
              base[2] +
              Offset(
                (i - 1) * 7 * projection.zoom + math.sin(phase + i) * 3,
                -age * 18 * projection.zoom,
              );
          canvas.drawCircle(
            point,
            (2 + age * 3) * projection.zoom,
            Paint()
              ..color = const Color(0xFFD4C7A5)
                  .withValues(alpha: .32 * math.sin(age * math.pi)),
          );
        }
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final building in _visible(size))
          CustomPainterSemantics(
            rect: projection
                .buildingRect(
                  building.footprint,
                  type: building.type,
                  floors: building.completedFloors,
                )
                .inflate(projection.tile * 2)
                .intersect(Offset.zero & size),
            properties: SemanticsProperties(
              label:
                  '${building.name}: ${BuildingWork.forBuilding(building)!.label}',
              textDirection: TextDirection.ltr,
            ),
          ),
      ];

  @override
  bool shouldRepaint(ConstructionActivityPainter old) =>
      old.game != game || old.projection != projection || old.clock != clock;
}
