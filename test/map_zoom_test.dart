import 'dart:ui' as ui;

import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:building_management_tycoon/features/district/map_camera_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget mapApp(
  DistrictGame game, {
  bool drawing = true,
  required ValueChanged<Footprint> onFootprint,
  ValueChanged<int>? onSelect,
}) => MaterialApp(
  theme: buildGameTheme(),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 800,
        height: 500,
        child: DistrictMap(
          game: game,
          drawing: drawing,
          onFootprint: onFootprint,
          onSelect: onSelect ?? (_) {},
        ),
      ),
    ),
  ),
);

void main() {
  test(
    'zoom keeps the same world point at the viewport centre after panning',
    () {
      final camera = MapCameraViewModel()..panBy(const Offset(130, -75));
      const size = Size(800, 500);
      final centre = size.center(Offset.zero);
      final initial = MapProjection(size, camera.pan, zoom: camera.zoom);
      final cell = initial.cellAt(centre);
      final marker = initial.point(cell.x + .5, cell.y + .5);
      camera.zoomIn();
      final enlarged = MapProjection(size, camera.pan, zoom: camera.zoom);
      expect(enlarged.cellAt(centre), cell);
      expect(
        enlarged.point(cell.x + .5, cell.y + .5),
        centre + (marker - centre) * 1.25,
      );
      camera.zoomOut();
      expect(camera.pan, const Offset(130, -75));
      camera.center();
      expect(camera.pan, Offset.zero);
      camera.dispose();
    },
  );

  testWidgets(
    'mouse zoom controls change scale and stop at both limits without drawing',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var drawings = 0;
        await tester.pumpWidget(
          mapApp(DistrictGame(watermark: 0), onFootprint: (_) => drawings++),
        );
        await tester.pumpAndSettle();
        expect(find.text('100%'), findsOneWidget);
        final mapBounds = tester.getRect(
          find.byKey(const ValueKey('district-map')),
        );
        final plusBounds = tester.getRect(
          find.byKey(const ValueKey('map-zoom-in')),
        );
        expect(mapBounds.right - plusBounds.right, 12);
        expect(mapBounds.bottom - plusBounds.bottom, 12);
        for (var click = 0; click < 6; click++) {
          await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
          await tester.pumpAndSettle();
        }
        expect(find.text('200%'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(find.byKey(const ValueKey('map-zoom-in')))
              .onPressed,
          isNull,
        );
        for (var click = 0; click < 8; click++) {
          await tester.tap(find.byKey(const ValueKey('map-zoom-out')));
          await tester.pumpAndSettle();
        }
        expect(find.text('50%'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(find.byKey(const ValueKey('map-zoom-out')))
              .onPressed,
          isNull,
        );
        expect(drawings, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('mouse footprint dragging uses the zoomed geometry', (
    tester,
  ) async {
    Footprint? selected;
    final game = DistrictGame(watermark: 0);
    await tester.pumpWidget(
      mapApp(game, onFootprint: (site) => selected = site),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
    await tester.pumpAndSettle();
    expect(find.text('125%'), findsOneWidget);
    final bounds = tester.getRect(find.byKey(const ValueKey('district-map')));
    final expected = MapProjection(bounds.size, Offset.zero, zoom: 1.25);
    final mouse = await tester.startGesture(
      bounds.topLeft + expected.point(3.5, 3.5),
      kind: ui.PointerDeviceKind.mouse,
    );
    await mouse.moveTo(bounds.topLeft + expected.point(4.5, 6.5));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(selected!.toJson(), const Footprint(3, 3, 2, 4).toJson());
    expect(selected!.rooms, 6);
    expect(selected!.quote, 2000000);
    expect(game.buildings, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'building picking follows zoom; zoom button clicks never select a building',
    (tester) async {
      final selected = <int>[];
      final game = DistrictGame(
        watermark: 0,
        nextBuildingId: 2,
        buildings: [
          ApartmentBuilding(
            id: 1,
            footprint: const Footprint(3, 3, 2, 4),
            stage: ConstructionStage.ready,
          ),
        ],
      );
      await tester.pumpWidget(
        mapApp(
          game,
          drawing: false,
          onFootprint: (_) {},
          onSelect: selected.add,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('map-zoom-out')));
      await tester.pumpAndSettle();
      expect(selected, isEmpty);
      final bounds = tester.getRect(find.byKey(const ValueKey('district-map')));
      final expected = MapProjection(bounds.size, Offset.zero, zoom: .75);
      await tester.tapAt(bounds.topLeft + expected.point(4.5, 6.5));
      await tester.pumpAndSettle();
      expect(selected, [1]);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
