import 'dart:math' as math;

import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:building_management_tycoon/features/district/map_camera_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'four_types_ui_test.dart' as game;
import 'helpers/game_test_store.dart';

void main() {
  testWidgets(
    'shallow Web drawing insets keep zoom clear of compass controls',
    (tester) async {
      game.viewport(tester, const Size(568, 320));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildGameTheme(),
          home: DistrictMap(
            game: DistrictGame(watermark: 0),
            drawing: true,
            immersive: true,
            controlInsets: const EdgeInsets.only(top: 86, bottom: 182),
            onFootprint: (_) {},
            onSelect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final zoom in ['Zoom in', 'Zoom out']) {
        final rect = tester.getRect(find.byTooltip(zoom));
        expect(find.byTooltip(zoom).hitTestable(), findsOneWidget);
        for (final control in ['Rotate map', 'Main road']) {
          expect(rect.overlaps(tester.getRect(find.byTooltip(control))), false);
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(568, 320),
    const Size(640, 360),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets(
        'mobile map fills viewport and controls remain reachable $size / $scale',
        (tester) async {
          game.viewport(tester, size);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(game.gameApp(testGameRepository()));
          await tester.pumpAndSettle();
          final mapFinder = find.byKey(const ValueKey('district-map'));
          expect(tester.getRect(mapFinder), Offset.zero & size);
          for (final tooltip in [
            'Back',
            'Rotate map',
            'Main road',
            'Zoom in',
            'Zoom out',
            'District activities',
          ]) {
            final finder = find.byTooltip(tooltip);
            expect(finder.hitTestable(), findsOneWidget, reason: tooltip);
            final rect = tester.getRect(finder);
            expect(rect.height, greaterThanOrEqualTo(48), reason: tooltip);
            expect(
              rect.bottom,
              lessThanOrEqualTo(size.height),
              reason: tooltip,
            );
          }
          await game.click(tester, 'Build');
          await game.click(tester, 'Choose apartment');
          expect(tester.getRect(mapFinder), Offset.zero & size);
          final projection = MapProjection(size, Offset.zero);
          final draw = await tester.startGesture(projection.point(.5, .5));
          await draw.moveTo(projection.point(1.5, 1.5));
          await draw.up();
          await tester.pumpAndSettle();
          expect(find.text('2 × 2 tiles'), findsOneWidget);
          expect(find.text('Review cost').hitTestable(), findsOneWidget);
          expect(find.byTooltip('Plan details').hitTestable(), findsOneWidget);
          await tester.tap(find.byTooltip('Plan details'));
          await tester.pumpAndSettle();
          expect(find.text('Draw your footprint'), findsOneWidget);
          await tester.tap(find.byTooltip('Back to map'));
          await tester.pumpAndSettle();
          expect(tester.getRect(mapFinder), Offset.zero & size);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  for (final reduced in [false, true]) {
    testWidgets(
      'button rotation respects reduced motion ($reduced) and preserves centre',
      (tester) async {
        final camera = MapCameraViewModel();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildGameTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            ),
            home: DistrictMap(
              game: DistrictGame(watermark: 0),
              drawing: false,
              camera: camera,
              onFootprint: (_) {},
              onSelect: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final map = tester.getRect(find.byKey(const ValueKey('district-map')));
        final world = MapProjection(
          map.size,
          camera.pan,
        ).worldAt(map.size.center(Offset.zero));
        await tester.tap(find.byTooltip('Rotate map'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rotate right'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        if (!reduced) {
          expect(camera.rotation, greaterThan(0));
          expect(camera.rotation, lessThan(math.pi / 2));
        } else {
          expect(camera.rotation, closeTo(math.pi / 2, 1e-8));
        }
        final during = MapProjection(
          map.size,
          camera.pan,
          rotation: camera.rotation,
        );
        expect(
          (during.worldAt(map.size.center(Offset.zero)) - world).distance,
          lessThan(1e-8),
        );
        await tester.pumpAndSettle();
        expect(camera.rotation, closeTo(math.pi / 2, 1e-8));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        camera.dispose();
      },
    );
  }

  testWidgets(
    'touch interrupts an animated turn without a delayed camera jump',
    (tester) async {
      final camera = MapCameraViewModel();
      await tester.pumpWidget(
        MaterialApp(
          home: DistrictMap(
            game: DistrictGame(watermark: 0),
            drawing: false,
            camera: camera,
            onFootprint: (_) {},
            onSelect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Rotate map'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rotate right'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('district-map'))),
      );
      final bearing = camera.rotation;
      await tester.pump(const Duration(milliseconds: 500));
      expect(camera.rotation, bearing);
      await finger.up();
      await tester.pumpAndSettle();
      expect(camera.rotation, bearing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      camera.dispose();
    },
  );
}
