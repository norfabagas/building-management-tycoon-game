import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' hide Finder;

import 'four_types_ui_test.dart' as game;
import 'helpers/game_test_store.dart';
import 'helpers/pump_map_controls.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Use the shipped fallback font for meaningful narrow-screen measurements.
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto.ttf'));
    await font.load();
  });
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(568, 320),
    const Size(640, 360),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets(
        'activities stays labelled and reachable at the left at $size / $scale',
        (tester) async {
          game.viewport(tester, size);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final db = (await tester.runAsync(openNewInMemoryDatabase))!;
          final now = DateTime.now().millisecondsSinceEpoch;
          final source = DistrictGame(watermark: now).toJson();
          await tester.runAsync(
            () => GameRepository.store.record('1').put(db, source),
          );
          await tester.pumpWidget(
            game.gameApp(
              FixedClockGameRepository(open: () async => db, fixedNow: now),
            ),
          );
          await pumpMapControls(tester);

          final activities = find.byKey(const ValueKey('district-activities'));
          expect(activities.hitTestable(), findsOneWidget);
          expect(
            find.text(size.width < 400 ? 'Goals' : 'Activities').hitTestable(),
            findsOneWidget,
          );
          final position = tester.getRect(activities);
          expect(position.left, lessThanOrEqualTo(20));
          expect(position.width, greaterThanOrEqualTo(48));
          expect(position.height, greaterThanOrEqualTo(48));
          expect(position.center.dx, lessThan(size.width / 2));
          expect(position.bottom, lessThanOrEqualTo(size.height));
          expect(
            position.right,
            lessThanOrEqualTo(tester.getRect(find.text('Build')).left),
          );

          await tester.tap(activities);
          await pumpMapControls(tester);
          for (final label in ['Achievements', 'Decorations']) {
            final item = find.widgetWithText(PopupMenuItem<String>, label);
            expect(item.hitTestable(), findsOneWidget);
            final rect = tester.getRect(item);
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
          }
          await tester.tap(find.text('Achievements'));
          await pumpMapControls(tester);
          expect(find.text(Achievement.firstBusiness.label), findsOneWidget);
          expect(find.text('Achievements'), findsOneWidget);
          await tester.tap(find.byTooltip('Close panel'));
          await pumpMapControls(tester);

          // Scrolling the other actions must never hide the activities entry.
          await tester.ensureVisible(find.byTooltip('Center map'));
          await pumpMapControls(tester);
          expect(tester.getRect(activities), position);
          expect(activities.hitTestable(), findsOneWidget);
          await tester.tap(activities);
          await pumpMapControls(tester);
          await tester.tap(find.text('Decorations'));
          await pumpMapControls(tester);
          expect(find.text('Decorations'), findsOneWidget);
          expect(find.text('Place tree'), findsOneWidget);
          await tester.tap(find.byTooltip('Close panel'));
          await pumpMapControls(tester);
          expect(activities.hitTestable(), findsOneWidget);
          final saved = (await tester.runAsync(
            () => GameRepository.store.record('1').get(db),
          ))!;
          expect(saved, source);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(db.close);
        },
      );
    }
  }
}
