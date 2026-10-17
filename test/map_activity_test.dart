import 'dart:convert';

import 'package:building_management_tycoon/app/production_assets.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/building_presentation.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('walk and vehicle paths stay on the ring, wrap continuously and follow long plots', () {
    for (final site in [
      const Footprint(0, 0, 2, 2),
      const Footprint(-5, 3, 2, 12),
      const Footprint(3, -8, 15, 2),
    ]) {
      for (final car in [false, true]) {
        final route = MapActivityRoute(site, vehicle: car);
        final positions = <Offset>[];
        for (var i = 0; i < 200; i++) {
          final pose = route.pose(route.length * i / 200);
          final point = pose.position;
          positions.add(point);
          expect(
            site.contains(LandCell(point.dx.floor(), point.dy.floor())),
            isFalse,
          );
          expect(
            site.roadRing,
            contains(LandCell(point.dx.floor(), point.dy.floor())),
          );
          expect(pose.vector.distance, closeTo(1, .001));
        }
        final bounds = Rect.fromPoints(
          Offset(
            positions.map((p) => p.dx).reduce((a, b) => a < b ? a : b),
            positions.map((p) => p.dy).reduce((a, b) => a < b ? a : b),
          ),
          Offset(
            positions.map((p) => p.dx).reduce((a, b) => a > b ? a : b),
            positions.map((p) => p.dy).reduce((a, b) => a > b ? a : b),
          ),
        );
        expect(
          bounds.width - site.width,
          closeTo(bounds.height - site.length, .02),
        );
        expect(
          (route.pose(route.length - .001).position - route.pose(.001).position)
              .distance,
          lessThan(.003),
        );
        expect(
          route.pose(-.5).position,
          route.pose(route.length - .5).position,
        );
      }
    }
  });

  testWidgets(
    'only open businesses tick; reduced motion and hidden maps suspend activity',
    (tester) async {
      final building = ApartmentBuilding(
        id: 1,
        footprint: const Footprint(0, 0, 2, 2),
        stage: ConstructionStage.parkingDone,
      );
      final game = DistrictGame(
        watermark: 0,
        nextBuildingId: 2,
        buildings: [building],
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
      expect(tester.binding.transientCallbackCount, 0);
      DistrictSimulation.openBusiness(game, 1);
      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      final painter = tester
          .widget<CustomPaint>(find.byKey(const ValueKey('map-activity')))
          .painter!;
      var repaints = 0;
      painter.addListener(() => repaints++);
      await tester.pump(const Duration(milliseconds: 250));
      expect(repaints, greaterThan(0));
      await tester.pumpWidget(app(reduced: true));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(app(visible: false));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(app());
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'all four outdoor sprite families match the renderer frame contract',
    (tester) async {
      final manifest = jsonDecode(
        (await tester.runAsync(
          () => rootBundle.loadString(ProductionAssets.manifest),
        ))!,
      );
      for (final type in BuildingType.values) {
        final asset = (manifest['assets'] as List).cast<Map>().singleWhere(
          (a) => a['path'] == type.actor,
        );
        expect(asset['frameSize'], [256, 384]);
        expect(asset['columns'], 4);
        expect(asset['rows'], 4);
        expect(asset['animations']['walk']['frames'], [
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
        ]);
        expect(asset['animations']['walk']['fps'], 8);
        expect(asset['pivot'], [.5, 364 / 384]);
      }
    },
  );
}
