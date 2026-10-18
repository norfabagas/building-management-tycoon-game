import 'dart:async';

import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/data/app_update_gateway.dart';
import 'package:building_management_tycoon/data/save_manager.dart';
import 'package:building_management_tycoon/features/profiles/app_update_bar.dart';
import 'package:building_management_tycoon/features/profiles/app_update_view_model.dart';
import 'package:building_management_tycoon/features/profiles/profile_screen.dart';
import 'package:building_management_tycoon/features/profiles/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/game_test_store.dart';
import 'helpers/memory_save_store.dart';

class FakeUpdates implements AppUpdateGateway {
  @override
  bool supported = true;
  @override
  String currentVersion = '20261018090000000';
  String remote = '20261018100000000';
  String result = 'reloading';
  bool offline = false;
  int syncs = 0;
  Completer<String>? pending;
  @override
  Future<String> check() async {
    if (offline) throw StateError('offline');
    return remote;
  }

  @override
  Future<String> sync(String version) async {
    syncs++;
    if (offline) throw StateError('offline');
    return pending?.future ?? result;
  }
}

void main() {
  test(
    'mismatch detection, matching release, invalid metadata and offline retry',
    () async {
      final gateway = FakeUpdates();
      final model = AppUpdateViewModel(gateway);
      addTearDown(model.dispose);
      await model.check();
      expect(model.needsSync, true);
      gateway.offline = true;
      await model.check();
      expect(model.needsSync, true);
      expect(model.message, contains('unavailable'));
      gateway.offline = false;
      gateway.remote = gateway.currentVersion;
      await model.check();
      expect(model.needsSync, false);
      gateway.remote = 'invalid';
      await model.check();
      expect(model.needsSync, false);
      expect(model.latestVersion, gateway.currentVersion);
    },
  );

  test(
    'offline startup and native platform do not pretend an update exists',
    () async {
      final gateway = FakeUpdates()..offline = true;
      final model = AppUpdateViewModel(gateway);
      addTearDown(model.dispose);
      await model.check();
      expect(model.needsSync, false);
      expect(model.message, startsWith('Offline'));
      gateway.supported = false;
      gateway.offline = false;
      await model.check();
      expect(model.latestVersion, isNull);
    },
  );

  test('sync guards duplicates and explains other tabs, failures and changed releases', () async {
    final gateway = FakeUpdates();
    final model = AppUpdateViewModel(gateway);
    addTearDown(model.dispose);
    await model.check();
    gateway.pending = Completer<String>();
    final sync = model.sync();
    await model.sync();
    expect(gateway.syncs, 1);
    expect(model.syncing, true);
    gateway.pending!.complete('other-tabs');
    await sync;
    expect(model.message, contains('other game tabs'));
    gateway.pending = null;
    gateway.offline = true;
    await model.sync();
    expect(model.message, contains('saves are safe'));
    gateway.offline = false;
    gateway.result = 'changed';
    gateway.remote = '20261018120000000';
    await model.sync();
    expect(model.latestVersion, gateway.remote);
    expect(model.needsSync, true);
  });

  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets('home Sync stays reachable at $size text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gateway = FakeUpdates();
        final updates = AppUpdateViewModel(gateway);
        final profiles = ProfileViewModel(SaveManager(MemorySaveStore()));
        await tester.pumpWidget(
          MaterialApp(
            theme: buildGameTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: ProfileScreen(
              viewModel: profiles,
              games: testGameRepository(),
              updates: updates,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final sync = find.widgetWithText(FilledButton, 'Sync');
        expect(sync, findsOneWidget);
        final before = tester.getRect(sync);
        expect(before.height, greaterThanOrEqualTo(48));
        expect(before.right, lessThanOrEqualTo(size.width));
        expect(before.top, lessThan(80));
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(sync), before);
        gateway.pending = Completer<String>();
        await tester.tap(sync);
        await tester.pump();
        expect(find.text('Syncing…'), findsOneWidget);
        gateway.pending!.complete('other-tabs');
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Close the other game tabs'),
          findsOneWidget,
        );
        expect(find.byType(AppUpdateBar), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        updates.dispose();
        profiles.dispose();
      });
    }
  }
}
