import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all initial stages and upgrade kinds have truthful work states', () {
    for (final type in BuildingType.values) {
      final building = ApartmentBuilding(
        id: 1,
        type: type,
        footprint: const Footprint(0, 0, 2, 3),
      );
      for (final stage in ConstructionStage.values) {
        building.stage = stage;
        final work = BuildingWork.forBuilding(building);
        if (stage.index >= ConstructionStage.parkingDone.index) {
          expect(work, isNull);
        } else {
          expect(work, isNotNull);
          expect(
            work!.working,
            stage == ConstructionStage.shell ||
                stage == ConstructionStage.basement,
          );
        }
      }
      for (final kind in BuildingUpgrade.values) {
        for (final stage in UpgradeStage.values) {
          building.upgrade = UpgradeOrder(kind: kind, stage: stage);
          final work = BuildingWork.forBuilding(building)!;
          expect(work.working, stage == UpgradeStage.building);
          expect(work.elevated, kind != BuildingUpgrade.basement);
          expect(work.label, contains(kind.label));
        }
      }
    }
  });

  testWidgets(
    'initial construction animates, pauses when hidden/reduced and stops when complete',
    (tester) async {
      final building = ApartmentBuilding(
        id: 1,
        footprint: const Footprint(0, 0, 2, 3),
        stage: ConstructionStage.shell,
        startedDay: 1,
      );
      final game = DistrictGame(
        watermark: 0,
        buildings: [building],
        nextBuildingId: 2,
      );
      Widget app({bool reduced = false, bool visible = true}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: visible,
            child: DistrictMap(
              game: game,
              drawing: false,
              onFootprint: (_) {},
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      var paints = 0;
      final painter = tester
          .widget<CustomPaint>(
            find.byKey(const ValueKey('map-construction-activity')),
          )
          .painter!;
      painter.addListener(() => paints++);
      await tester.pump(const Duration(milliseconds: 250));
      expect(paints, greaterThan(0));
      await tester.pumpWidget(app(reduced: true));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(app(visible: false));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      building.stage = ConstructionStage.parkingDone;
      await tester.pumpWidget(app());
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'work overlay changes pixels at different times and every camera bearing without mutating state',
    (tester) async {
      final building = ApartmentBuilding(
        id: 1,
        footprint: const Footprint(0, 0, 2, 3),
        stage: ConstructionStage.ready,
        upgrade: UpgradeOrder(
          kind: BuildingUpgrade.floor,
          stage: UpgradeStage.building,
          startedDay: 1,
        ),
      );
      final game = DistrictGame(
        watermark: 0,
        buildings: [building],
        nextBuildingId: 2,
      );
      final before = game.toJson();
      final clock = ValueNotifier<double>(0);
      Future<List<int>> pixels(double time, double rotation) async {
        clock.value = time;
        final recorder = ui.PictureRecorder();
        ConstructionActivityPainter(
          game,
          MapProjection(const Size(400, 400), Offset.zero, rotation: rotation),
          clock,
        ).paint(Canvas(recorder), const Size(400, 400));
        final picture = recorder.endRecording();
        final image = await picture.toImage(400, 400);
        final bytes = (await image.toByteData())!.buffer.asUint8List().toList();
        image.dispose();
        picture.dispose();
        return bytes;
      }

      for (final angle in [0.0, math.pi / 2, math.pi, math.pi * 1.5]) {
        final a = (await tester.runAsync(() => pixels(0, angle)))!;
        final b = (await tester.runAsync(() => pixels(.9, angle)))!;
        expect(a, isNot(equals(b)));
        expect(a.any((byte) => byte != 0), true);
      }
      expect(game.toJson(), before);
      building.upgrade = null;
      final clear = (await tester.runAsync(() => pixels(0, 0)))!;
      expect(clear.every((byte) => byte == 0), true);
      clock.dispose();
    },
  );
}
