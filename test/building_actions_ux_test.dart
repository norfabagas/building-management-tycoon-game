import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'four_types_ui_test.dart' as game;

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets(
        'building actions stay visible through scroll and rotation at $size / $scale',
        (tester) async {
          game.viewport(tester, size);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final database = (await tester.runAsync(openNewInMemoryDatabase))!;
          final state = DistrictGame(
            watermark: DateTime.now().millisecondsSinceEpoch,
            buildings: [
              ApartmentBuilding(
                id: 1,
                footprint: const Footprint(0, 0, 2, 2),
                stage: ConstructionStage.ready,
              ),
            ],
            nextBuildingId: 2,
          );
          await tester.runAsync(
            () =>
                GameRepository.store.record('1').put(database, state.toJson()),
          );
          await tester.pumpWidget(
            game.gameApp(GameRepository(open: () async => database)),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Rotate map'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Rotate right'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final camera = tester
              .widget<DistrictMap>(find.byType(DistrictMap))
              .camera!;
          expect(camera.bearing, 90);
          final map = tester.getRect(
            find.byKey(const ValueKey('district-map')),
          );
          final projection = MapProjection(
            map.size,
            camera.pan,
            zoom: camera.zoom,
            rotation: camera.rotation,
          );
          await tester.tapAt(map.topLeft + projection.point(1, 1));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final upgrade = find.widgetWithText(FilledButton, 'Upgrade building');
          expect(upgrade.hitTestable(), findsOneWidget);
          expect(tester.getSize(upgrade).height, greaterThanOrEqualTo(48));
          final pinned = tester.getRect(upgrade);
          await tester.ensureVisible(find.text('Building details'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getRect(upgrade), pinned);
          expect(find.byIcon(Icons.close), findsNothing);
          await tester.tap(upgrade);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final back = find.widgetWithText(FilledButton, 'Back to floors');
          expect(back.hitTestable(), findsOneWidget);
          final backRect = tester.getRect(back);
          await tester.ensureVisible(
            find.byKey(const ValueKey('upgrade-luxury')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getRect(back), backRect);
          await tester.tap(back);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(upgrade.hitTestable(), findsOneWidget);
          await tester.tap(find.text('Exit building'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(camera.bearing, 90);
          await tester.ensureVisible(find.text('Finances'));
          await tester.tap(find.text('Finances'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final close = find.widgetWithText(TextButton, 'Close');
          await tester.ensureVisible(close);
          expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Finances').hitTestable(), findsWidgets);
          expect(camera.bearing, 90);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(database.close);
        },
      );
    }
  }
}
