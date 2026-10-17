import 'package:building_management_tycoon/app/tycoon_app.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/data/save_manager.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/profiles/profile_view_model.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' hide Finder;

import 'four_types_ui_test.dart' as game;
import 'helpers/game_test_store.dart';
import 'helpers/memory_save_store.dart';

void expectReachable(
  WidgetTester tester,
  Finder finder,
  Size size, {
  double keyboard = 0,
}) {
  expect(finder.hitTestable(), findsOneWidget);
  final rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width));
  expect(rect.bottom, lessThanOrEqualTo(size.height - keyboard));
  expect(rect.height, greaterThanOrEqualTo(48));
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(568, 320),
    const Size(640, 360),
  ]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets(
        'construction review pins actions, redraws and cancels at $size, text $scale',
        (tester) async {
          game.viewport(tester, size);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final db = (await tester.runAsync(openNewInMemoryDatabase))!;
          final repository = GameRepository(open: () async => db);
          await tester.pumpWidget(game.gameApp(repository));
          await tester.pumpAndSettle();
          await game.click(tester, 'Build');
          await game.click(tester, 'Choose apartment');
          final map = tester.getRect(
            find.byKey(const ValueKey('district-map')),
          );
          final projection = MapProjection(map.size, Offset.zero);
          final drag = await tester.startGesture(
            map.topLeft + projection.point(.5, .5),
          );
          await drag.moveTo(map.topLeft + projection.point(1.5, 1.5));
          await drag.up();
          await tester.pumpAndSettle();
          final review = find.widgetWithText(FilledButton, 'Review cost');
          expectReachable(tester, review, size);
          await tester.tap(review);
          await tester.pumpAndSettle();
          final confirm = find.widgetWithText(
            FilledButton,
            'Confirm construction',
          );
          final cancel = find.widgetWithText(TextButton, 'Cancel construction');
          final redraw = find.widgetWithText(TextButton, 'Redraw footprint');
          expectReachable(tester, confirm, size);
          expectReachable(tester, cancel, size);
          final before = tester.getRect(confirm);
          await tester.ensureVisible(find.text('Completed daily upkeep'));
          await tester.pumpAndSettle();
          expect(tester.getRect(confirm), before);
          expectReachable(tester, redraw, size);
          await tester.tap(redraw);
          await tester.pumpAndSettle();
          expectReachable(tester, review, size);
          await tester.tap(review);
          await tester.pumpAndSettle();
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          final saved = (await tester.runAsync(
            () => GameRepository.store.record('1').get(db),
          ))!;
          expect(DistrictGame.fromJson(saved).buildings, isEmpty);
          expect(DistrictGame.fromJson(saved).balance, 4000000);
          expectReachable(
            tester,
            find.widgetWithText(FilledButton, 'Build'),
            size,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(db.close);
        },
      );
    }
  }

  for (final scenario in [
    (size: const Size(320, 568), keyboard: 260.0, scale: 1.0),
    (size: const Size(360, 640), keyboard: 290.0, scale: 1.4),
    (size: const Size(568, 320), keyboard: 120.0, scale: 1.0),
  ]) {
    testWidgets('profile form keeps keyboard-safe actions at $scenario', (
      tester,
    ) async {
      game.viewport(tester, scenario.size);
      final model = ProfileViewModel(SaveManager(MemorySaveStore()));
      await tester.pumpWidget(
        TycoonApp(profiles: model, games: testGameRepository()),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('New').first);
      await tester.tap(find.text('New').first);
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(bottom: scenario.keyboard);
      tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      final create = find.widgetWithText(FilledButton, 'Create district');
      final cancel = find.widgetWithText(TextButton, 'Cancel');
      expectReachable(
        tester,
        create,
        scenario.size,
        keyboard: scenario.keyboard,
      );
      expectReachable(
        tester,
        cancel,
        scenario.size,
        keyboard: scenario.keyboard,
      );
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Enter a district name.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('district-name')));
      await tester.enterText(
        find.byKey(const ValueKey('district-name')),
        'Small phone',
      );
      expectReachable(
        tester,
        cancel,
        scenario.size,
        keyboard: scenario.keyboard,
      );
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(model.profiles.every((profile) => profile == null), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      model.dispose();
    });
  }
}
