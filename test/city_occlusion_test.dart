import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> activityPixels(
  WidgetTester tester,
  CustomPainter painter,
) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Size(1280, 664));
  final picture = recorder.endRecording();
  return (await tester.runAsync(() async {
    final image = await picture.toImage(1280, 664);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final copy = Uint8List.fromList(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
    return copy;
  }))!;
}

int opaquePixels(
  Uint8List bytes, [
  Rect area = const Rect.fromLTWH(0, 0, 1280, 664),
]) {
  var count = 0;
  for (
    var y = area.top.floor().clamp(0, 663);
    y < area.bottom.ceil().clamp(0, 664);
    y++
  ) {
    for (
      var x = area.left.floor().clamp(0, 1279);
      x < area.right.ceil().clamp(0, 1280);
      x++
    ) {
      if (bytes[(y * 1280 + x) * 4 + 3] > 0) count++;
    }
  }
  return count;
}

Widget app(DistrictGame game) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: DistrictMap(
      game: game,
      drawing: false,
      onFootprint: (_) {},
      onSelect: (_) {},
    ),
  ),
);
void main() {
  testWidgets(
    'a completed floor invalidates cached traffic occlusion in the same scene',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 664);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = DistrictGame(
        watermark: 0,
        nextBuildingId: 5,
        buildings: [
          for (var i = 0; i < 4; i++)
            ApartmentBuilding(
              id: i + 1,
              type: BuildingType.values[i],
              footprint: const [
                Footprint(-4, -1, 2, 4),
                Footprint(0, -1, 2, 2),
                Footprint(3, -1, 2, 2),
                Footprint(-1, 4, 4, 2),
              ][i],
              stage: ConstructionStage.ready,
            ),
        ],
      );
      await tester.pumpWidget(app(game));
      await tester.pump();
      final painter = tester
          .widget<CustomPaint>(find.byKey(const ValueKey('map-activity')))
          .painter!;
      final low = opaquePixels(await activityPixels(tester, painter));
      for (final b in game.buildings) {
        b.aboveGroundFloors = 10;
      }
      final high = opaquePixels(await activityPixels(tester, painter));
      expect(high, greaterThan(0));
      expect(high, lessThan(low));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'front-side walker remains whole in front of a taller owner facade',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 664);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final building = ApartmentBuilding(
        id: 1,
        footprint: const Footprint(0, 0, 2, 4),
        stage: ConstructionStage.ready,
      );
      final game = DistrictGame(
        watermark: 0,
        nextBuildingId: 2,
        buildings: [building],
      );
      await tester.pumpWidget(app(game));
      await tester.pump();
      final painter = tester
          .widget<CustomPaint>(find.byKey(const ValueKey('map-activity')))
          .painter!;
      final route = MapActivityRoute(building.footprint, vehicle: false);
      final world = route.pose(route.length * .543).position;
      expect(world.dx, greaterThan(2));
      final foot = MapProjection(
        const Size(1280, 664),
        Offset.zero,
      ).point(world.dx, world.dy);
      final headAndBody = Rect.fromLTRB(
        foot.dx - 9,
        foot.dy - 24,
        foot.dx + 9,
        foot.dy - 5,
      );
      final before = opaquePixels(
        await activityPixels(tester, painter),
        headAndBody,
      );
      building.aboveGroundFloors = 10;
      final after = opaquePixels(
        await activityPixels(tester, painter),
        headAndBody,
      );
      expect(before, greaterThan(25));
      expect(after, before);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
