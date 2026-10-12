import 'dart:convert';

import 'package:building_management_tycoon/data/save_manager.dart';
import 'package:building_management_tycoon/domain/game_rules.dart';
import 'package:building_management_tycoon/features/profiles/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/memory_save_store.dart';

void main() {
  late MemorySaveStore store;
  late SaveManager saves;

  setUp(() {
    store = MemorySaveStore();
    saves = SaveManager(store, now: () => DateTime.utc(2026, 10, 11));
  });

  test('five local slots survive a fresh save manager', () async {
    expect(await saves.loadProfiles(), hasLength(5));
    await saves.createProfile(slot: 3, areaName: '  Riverside  ');
    final restored = await SaveManager(store).loadProfiles();
    expect(restored[2]!.areaName, 'Riverside');
    expect(restored[2]!.createdAt, DateTime.utc(2026, 10, 11));
    expect(restored.where((profile) => profile != null), hasLength(1));
  });

  test('occupied slots cannot be overwritten', () async {
    await saves.createProfile(slot: 1, areaName: 'Central District');
    final original = store.value;
    await expectLater(
      saves.createProfile(slot: 1, areaName: 'Replacement'),
      throwsStateError,
    );
    expect(store.value, original);
  });

  test('concurrent creations preserve both slots', () async {
    await Future.wait([
      saves.createProfile(slot: 1, areaName: 'Central District'),
      saves.createProfile(slot: 2, areaName: 'Riverside'),
    ]);
    final profiles = await saves.loadProfiles();
    expect(profiles[0]!.areaName, 'Central District');
    expect(profiles[1]!.areaName, 'Riverside');
  });

  test('corrupt and unsupported saves remain intact', () async {
    for (final source in [
      'invalid JSON',
      jsonEncode({'version': 2, 'slots': List.filled(5, null)}),
      jsonEncode({'version': 1, 'slots': []}),
    ]) {
      store.value = source;
      await expectLater(
        saves.loadProfiles(),
        throwsA(isA<SaveFormatException>()),
      );
      await expectLater(
        saves.createProfile(slot: 1, areaName: 'New'),
        throwsA(isA<SaveFormatException>()),
      );
      expect(store.value, source);
    }
  });

  test('a mismatched slot number fails without resetting data', () async {
    store.value = jsonEncode({
      'version': 1,
      'slots': [
        {
          'slot': 2,
          'areaName': 'Central District',
          'createdAt': '2026-10-11T00:00:00Z',
        },
        null,
        null,
        null,
        null,
      ],
    });
    await expectLater(
      saves.loadProfiles(),
      throwsA(isA<SaveFormatException>()),
    );
  });

  test('failed writes do not publish a profile and can be retried', () async {
    final model = ProfileViewModel(saves);
    addTearDown(model.dispose);
    await model.load();
    store.failWrites = true;
    await expectLater(
      model.create(slot: 1, areaName: 'Central District'),
      throwsStateError,
    );
    expect(model.profiles[0], isNull);
    expect(model.busy, isFalse);
    store.failWrites = false;
    await model.create(slot: 1, areaName: 'Central District');
    expect(model.profiles[0]!.areaName, 'Central District');
  });

  test('failed reads block creation until a successful retry', () async {
    final model = ProfileViewModel(saves);
    addTearDown(model.dispose);
    store.failReads = true;
    await model.load();
    expect(model.loaded, isFalse);
    expect(model.error, isNotNull);
    await expectLater(
      model.create(slot: 1, areaName: 'Central'),
      throwsStateError,
    );
    store.failReads = false;
    await model.load();
    expect(model.loaded, isTrue);
    expect(model.error, isNull);
  });

  test('invalid names and slots cannot enter storage', () {
    expect(
      () => saves.createProfile(slot: 6, areaName: 'Central'),
      throwsArgumentError,
    );
    expect(
      () => saves.createProfile(slot: 0, areaName: 'Central'),
      throwsArgumentError,
    );
    expect(
      () => saves.createProfile(slot: 1, areaName: '   '),
      throwsArgumentError,
    );
    expect(store.value, isNull);
  });

  test('phase order ends at Noon before the next day starts', () {
    var clock = GameClock();
    final labels = <String>[];
    for (var i = 0; i < 5; i++) {
      labels.add(clock.phase.label);
      expect(clock.day, 1);
      clock = clock.nextPhase();
    }
    expect(labels, ['Morning', 'Day', 'Afternoon', 'Night', 'Noon']);
    expect(clock.day, 2);
    expect(clock.phase, GamePhase.morning);
  });
}
