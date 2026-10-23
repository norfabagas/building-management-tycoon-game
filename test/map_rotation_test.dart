import 'dart:math' as math;

import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:building_management_tycoon/features/district/map_camera_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_map_controls.dart';

void main() {
  testWidgets('desktop camera controls retain 48px touch targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGameTheme().copyWith(
          platform: TargetPlatform.windows,
          visualDensity: VisualDensity.compact,
        ),
        home: DistrictMap(
          game: DistrictGame(watermark: 0),
          drawing: false,
          onFootprint: (_) {},
          onSelect: (_) {},
        ),
      ),
    );
    await pumpMapControls(tester);
    for (final label in ['Rotate map', 'Main road', 'Zoom out', 'Zoom in']) {
      final rect = tester.getRect(find.byTooltip(label));
      expect(rect.width, greaterThanOrEqualTo(48), reason: label);
      expect(rect.height, greaterThanOrEqualTo(48), reason: label);
    }
    await tester.tap(find.byTooltip('Rotate map'));
    await pumpMapControls(tester);
    await tester.tap(find.text('Rotate left'));
    await pumpMapControls(tester);
    await tester.tap(find.byTooltip('Rotate map'));
    await pumpMapControls(tester);
    expect(find.text('Map bearing 270°'), findsOneWidget);
    await tester.tap(find.text('Reset rotation'));
    await pumpMapControls(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'quarter turns wrap, reset keeps zoom, and center resets orientation',
    () {
      final camera = MapCameraViewModel()..zoomIn();
      const size = Size(800, 600);
      for (var turn = 0; turn < 4; turn++) {
        final projection = MapProjection(
          size,
          camera.pan,
          zoom: camera.zoom,
          rotation: camera.rotation,
        );
        final world = projection.worldAt(size.center(Offset.zero));
        camera.rotateBy(-math.pi / 2, originOffset: projection.originOffset);
        final after = MapProjection(
          size,
          camera.pan,
          zoom: camera.zoom,
          rotation: camera.rotation,
        );
        expect(
          (after.worldAt(size.center(Offset.zero)) - world).distance,
          lessThan(1e-8),
        );
        expect(camera.bearing, [270, 180, 90, 0][turn]);
      }
      camera.panBy(const Offset(80, -20));
      camera.rotateBy(.7);
      camera.resetRotation();
      expect(camera.rotation, 0);
      expect(camera.zoom, 1.25);
      camera.rotateBy(.8);
      camera.center();
      expect(camera.pan, Offset.zero);
      expect(camera.bearing, 0);
      expect(camera.zoom, 1.25);
      camera.dispose();
    },
  );
  test(
    'rotation inverses, vertical storeys and focal zoom hold at every bearing',
    () {
      for (final size in [const Size(320, 220), const Size(800, 600)]) {
        for (final angle in [
          0.0,
          .3,
          math.pi / 2,
          math.pi,
          math.pi * 1.5,
          6.1,
        ]) {
          for (final zoom in [.5, 1.0, 2.0]) {
            final projection = MapProjection(
              size,
              const Offset(30, -50),
              zoom: zoom,
              rotation: angle,
            );
            for (final world in [
              const Offset(-3.2, 5.7),
              const Offset(.2, 1.4),
            ]) {
              final screen = projection.point(world.dx, world.dy);
              expect(
                (projection.worldAt(screen) - world).distance,
                lessThan(1e-9),
              );
              expect(
                projection.cellAt(screen),
                LandCell(world.dx.floor(), world.dy.floor()),
              );
            }
            const site = Footprint(-2, 1, 2, 5);
            final ground = projection.buildingCorners(site);
            final roof = projection.buildingCorners(
              site,
              roof: true,
              floors: 7,
            );
            for (var i = 0; i < 4; i++) {
              expect(roof[i].dx, closeTo(ground[i].dx, 1e-9));
              expect(
                ground[i].dy - roof[i].dy,
                closeTo(projection.buildingHeight(site, floors: 7), 1e-9),
              );
            }
            expect(
              projection.buildingRect(site, floors: 7).width,
              closeTo(projection.footprint(site).getBounds().width, 1e-8),
            );
          }
          final camera = MapCameraViewModel()..panBy(const Offset(45, -30));
          final before = MapProjection(size, camera.pan, zoom: camera.zoom);
          final focal = size.center(Offset.zero) + const Offset(20, -10);
          final world = before.worldAt(focal);
          const shift = Offset(15, 9);
          camera.transform(
            zoom: 1.4,
            rotation: angle,
            originOffset: before.originOffset,
            fromFocal: focal - size.center(Offset.zero),
            toFocal: focal + shift - size.center(Offset.zero),
          );
          final after = MapProjection(
            size,
            camera.pan,
            zoom: camera.zoom,
            rotation: camera.rotation,
          );
          expect(
            (after.point(world.dx, world.dy) - focal - shift).distance,
            lessThan(1e-8),
          );
          camera.dispose();
        }
      }
    },
  );

  test('occlusion follows the camera instead of the original world axes', () {
    const site = Footprint(0, 0, 2, 2);
    for (final angle in [0.0, math.pi / 2, math.pi, math.pi * 1.5]) {
      final projection = MapProjection(
        const Size(800, 600),
        Offset.zero,
        rotation: angle,
      );
      final towardCamera = Offset(
        math.cos(angle) + math.sin(angle),
        math.cos(angle) - math.sin(angle),
      );
      expect(
        projection.occludesPoint(site, const Offset(1, 1) - towardCamera * 3),
        isTrue,
      );
      expect(
        projection.occludesPoint(site, const Offset(1, 1) + towardCamera * 3),
        isFalse,
      );
    }
  });

  for (final angle in [0.0, math.pi / 4, math.pi / 2, math.pi, math.pi * 1.5]) {
    testWidgets(
      'rotated map picks a building and draws the same world plot at $angle',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final camera = MapCameraViewModel();
        final initial = MapProjection(const Size(800, 600), Offset.zero);
        camera.rotateBy(angle, originOffset: initial.originOffset);
        final projection = MapProjection(
          initial.size,
          camera.pan,
          rotation: camera.rotation,
        );
        var selected = 0;
        Footprint? preview;
        final state = DistrictGame(
          watermark: 0,
          buildings: [
            ApartmentBuilding(
              id: 1,
              footprint: const Footprint(0, 0, 2, 2),
              stage: ConstructionStage.ready,
            ),
          ],
        );
        Widget app(bool drawing) => MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: DistrictMap(
              game: state,
              camera: camera,
              drawing: drawing,
              onFootprint: (site) => preview = site,
              onSelect: (id) => selected = id,
            ),
          ),
        );
        await tester.pumpWidget(app(false));
        await pumpMapControls(tester);
        await tester.tapAt(projection.point(1, 1));
        await pumpMapControls(tester);
        expect(selected, 1);
        await tester.pumpWidget(app(true));
        await pumpMapControls(tester);
        final gesture = await tester.startGesture(projection.point(.5, .5));
        await gesture.moveTo(projection.point(1.5, 1.5));
        await gesture.up();
        await pumpMapControls(tester);
        expect(preview?.toJson(), const Footprint(0, 0, 2, 2).toJson());
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        camera.dispose();
      },
    );
  }

  for (final drawing in [false, true]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
        'two-finger twist rotates without selecting or changing the plan ($drawing, zoom $scale)',
        (tester) async {
          final camera = MapCameraViewModel();
          const original = Footprint(-3, 0, 2, 2);
          Footprint? preview = original;
          var selections = 0;
          await tester.pumpWidget(
            MaterialApp(
              home: DistrictMap(
                game: DistrictGame(watermark: 0),
                camera: camera,
                drawing: drawing,
                preview: original,
                onFootprint: (p) => preview = p,
                onCancelFootprint: () => preview = null,
                onSelect: (_) => selections++,
              ),
            ),
          );
          await pumpMapControls(tester);
          final map = tester.getRect(
            find.byKey(const ValueKey('district-map')),
          );
          final centre = map.center;
          final world = MapProjection(
            map.size,
            camera.pan,
          ).worldAt(centre - map.topLeft);
          const shift = Offset(24, 12);
          final a = await tester.startGesture(
            centre - const Offset(60, 0),
            pointer: 1,
          );
          final b = await tester.startGesture(
            centre + const Offset(60, 0),
            pointer: 2,
          );
          await tester.pump();
          for (var step = 1; step <= 8; step++) {
            final angle = step * math.pi / 16;
            final vector =
                Offset(math.cos(angle), math.sin(angle)) *
                (60 * (1 + (scale - 1) * step / 8));
            final focal = centre + shift * (step / 8);
            await a.moveTo(focal - vector);
            await b.moveTo(focal + vector);
            await tester.pump();
          }
          await b.up();
          await a.up();
          await pumpMapControls(tester);
          expect(camera.rotation, closeTo(math.pi / 2, .04));
          expect(camera.zoom, closeTo(scale, .01));
          final finalProjection = MapProjection(
            map.size,
            camera.pan,
            zoom: camera.zoom,
            rotation: camera.rotation,
          );
          expect(
            (map.topLeft +
                    finalProjection.point(world.dx, world.dy) -
                    centre -
                    shift)
                .distance,
            lessThan(.01),
          );
          expect(selections, 0);
          expect(preview, original);
          await tester.tap(find.byTooltip('Rotate map'));
          await pumpMapControls(tester);
          await tester.tap(find.text('Reset rotation'));
          await pumpMapControls(tester);
          expect(camera.rotation, 0);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          camera.dispose();
        },
      );
    }
  }
}
