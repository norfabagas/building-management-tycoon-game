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
  VoidCallback? onCancelFootprint,
  Footprint? preview,
  bool decorationPreview = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
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
          onCancelFootprint: onCancelFootprint,
          preview: preview,
          decorationPreview: decorationPreview,
          previewValid: decorationPreview ? true : null,
        ),
      ),
    ),
  ),
);

void main() {
  test('compact map framing preserves world position under a moving pinch', () {
    for (final size in [
      const Size(390, 180),
      const Size(844, 150),
      const Size(800, 600),
    ]) {
      final camera = MapCameraViewModel();
      final centre = size.center(Offset.zero);
      for (final zoom in [2.0, .5, 1.25]) {
        final before = MapProjection(
          size,
          camera.pan,
          zoom: camera.zoom,
        ).point(.7, 1.4);
        final moved = before + const Offset(12, -7);
        camera.transform(
          zoom: zoom,
          fromFocal: before - centre,
          toFocal: moved - centre,
        );
        final after = MapProjection(
          size,
          camera.pan,
          zoom: camera.zoom,
        ).point(.7, 1.4);
        expect((after - moved).distance, lessThan(.000001));
      }
      camera.dispose();
    }
  });

  test(
    'rectangular exteriors follow both land axes with a stable vertical height',
    () {
      for (final zoom in [.5, 1.0, 2.0]) {
        final projection = MapProjection(
          const Size(800, 500),
          const Offset(30, -20),
          zoom: zoom,
        );
        for (final site in [
          const Footprint(0, 0, 2, 4),
          const Footprint(3, 3, 4, 2),
          const Footprint(-3, 1, 1, 8),
          const Footprint(1, -3, 8, 1),
        ]) {
          final land = projection.footprint(site).getBounds();
          final exterior = projection.buildingRect(site);
          expect(exterior.width, land.width);
          expect(
            exterior.height,
            closeTo(land.height + projection.buildingHeight(site), .0001),
          );
          expect(exterior.bottomCenter, land.bottomCenter);
          final roof = projection.buildingCorners(site, roof: true);
          expect(
            (roof[1] - roof[0]).distance / (roof[3] - roof[0]).distance,
            closeTo(site.width / site.length, .000001),
          );
        }
      }
    },
  );

  test('pinch anchors the focal world point while scaling and moving', () {
    final camera = MapCameraViewModel()..panBy(const Offset(70, -40));
    const size = Size(800, 500);
    const focal = Offset(520, 180);
    const moved = Offset(550, 200);
    final before = MapProjection(size, camera.pan, zoom: camera.zoom);
    final cell = before.cellAt(focal);
    final marker = before.point(cell.x + .5, cell.y + .5);
    camera.transform(
      zoom: 1.37,
      fromFocal: focal - size.center(Offset.zero),
      toFocal: moved - size.center(Offset.zero),
    );
    final after = MapProjection(size, camera.pan, zoom: camera.zoom);
    expect(after.cellAt(moved), cell);
    expect(
      (after.point(cell.x + .5, cell.y + .5) -
              (moved + (marker - focal) * 1.37))
          .distance,
      lessThan(.000001),
    );
    camera.zoomIn();
    expect(camera.zoom, 1.5);
    camera.zoomOut();
    expect(camera.zoom, 1.25);
    camera.dispose();
  });

  for (final drawing in [false, true]) {
    testWidgets(
      'two-finger pinch zooms both ways without selecting or drawing ($drawing)',
      (tester) async {
        Footprint? preview;
        var selections = 0;
        await tester.pumpWidget(
          mapApp(
            DistrictGame(
              watermark: 0,
              nextBuildingId: 2,
              buildings: [
                ApartmentBuilding(
                  id: 1,
                  footprint: const Footprint(3, 3, 2, 4),
                  stage: ConstructionStage.ready,
                ),
              ],
            ),
            drawing: drawing,
            onFootprint: (site) => preview = site,
            onCancelFootprint: () => preview = null,
            onSelect: (_) => selections++,
          ),
        );
        await tester.pumpAndSettle();
        final map = tester.getRect(find.byKey(const ValueKey('district-map')));
        final centre = map.center + const Offset(30, -30);
        final first = await tester.startGesture(
          centre - const Offset(40, 0),
          pointer: 1,
        );
        final second = await tester.startGesture(
          centre + const Offset(40, 0),
          pointer: 2,
        );
        await tester.pump();
        await first.moveTo(centre - const Offset(60, 0));
        await second.moveTo(centre + const Offset(60, 0));
        await tester.pump();
        await first.moveTo(centre - const Offset(180, 0));
        await second.moveTo(centre + const Offset(180, 0));
        await tester.pump();
        expect(find.text('200%'), findsOneWidget);
        await first.moveTo(centre - const Offset(10, 0));
        await second.moveTo(centre + const Offset(10, 0));
        await tester.pump();
        expect(find.text('50%'), findsOneWidget);
        await second.up();
        await first.moveBy(const Offset(20, 0));
        await first.up();
        await tester.pumpAndSettle();
        expect(preview, isNull);
        expect(selections, 0);
        if (drawing) {
          final gesture = await tester.startGesture(map.center);
          await gesture.moveBy(const Offset(30, 30));
          await gesture.up();
          await tester.pumpAndSettle();
          expect(preview, isNotNull);
        } else {
          final projection = MapProjection(
            map.size,
            const Offset(15, -15),
            zoom: .5,
          );
          await tester.tapAt(map.topLeft + projection.point(4, 4));
          await tester.pumpAndSettle();
          expect(selections, 1);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final decoration in [false, true]) {
    testWidgets(
      'pinch preserves an existing placement preview (decoration: $decoration)',
      (tester) async {
        const existing = Footprint(3, 3, 2, 4);
        Footprint? preview = existing;
        await tester.pumpWidget(
          mapApp(
            DistrictGame(watermark: 0),
            preview: existing,
            decorationPreview: decoration,
            onFootprint: (site) => preview = site,
            onCancelFootprint: () => preview = null,
          ),
        );
        await tester.pumpAndSettle();
        final centre = tester.getCenter(
          find.byKey(const ValueKey('district-map')),
        );
        final first = await tester.startGesture(
          centre - const Offset(40, 0),
          pointer: 1,
        );
        final second = await tester.startGesture(
          centre + const Offset(40, 0),
          pointer: 2,
        );
        await first.moveBy(const Offset(-30, 0));
        await second.moveBy(const Offset(30, 0));
        await second.up();
        await first.up();
        await tester.pumpAndSettle();
        expect(preview?.toJson(), existing.toJson());
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

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
