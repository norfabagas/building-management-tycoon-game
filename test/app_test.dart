import 'package:building_management_tycoon/app/tycoon_app.dart';
import 'package:building_management_tycoon/data/save_manager.dart';
import 'package:building_management_tycoon/features/district/district_screen.dart';
import 'package:building_management_tycoon/features/profiles/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/memory_save_store.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('profile screen fits ${size.width} × ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = ProfileViewModel(SaveManager(MemorySaveStore()));
      await tester.pumpWidget(TycoonApp(profiles: model));
      await tester.pumpAndSettle();
      for (var slot = 1; slot <= 5; slot++) {
        expect(find.byKey(ValueKey('profile-slot-$slot')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      model.dispose();
    });
  }

  testWidgets('creating a district persists its name and opens empty land', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemorySaveStore();
    final model = ProfileViewModel(SaveManager(store));
    await tester.pumpWidget(TycoonApp(profiles: model));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create district'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a district name.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('district-name')),
      '  Riverside  ',
    );
    await tester.tap(find.text('Create district'));
    await tester.pumpAndSettle();
    expect(find.byType(DistrictScreen), findsOneWidget);
    expect(find.text('Riverside'), findsOneWidget);
    expect((await SaveManager(store).loadProfiles())[0]!.areaName, 'Riverside');
    expect(tester.takeException(), isNull);
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.text('Riverside'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
}
