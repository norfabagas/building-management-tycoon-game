import 'dart:convert';
import 'dart:async';

import 'package:building_management_tycoon/app/tycoon_app.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/data/save_manager.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/profiles/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'helpers/memory_save_store.dart';

final created = DateTime.utc(2026, 10, 17);

class _FailingDeleteRepository extends GameRepository {
  _FailingDeleteRepository({required super.open});
  final gate = Completer<void>();
  bool fail = true;
  int attempts = 0;
  @override
  Future<void> deleteProfile(
    LocalProfile profile,
    Future<List<LocalProfile?>> Function() importLegacy,
  ) async {
    attempts++;
    if (fail) {
      await gate.future;
      throw StateError('Storage unavailable');
    }
    return super.deleteProfile(profile, importLegacy);
  }
}

void main() {
  testWidgets(
    'deletion disables duplicate/back actions and supports retry after failure',
    (tester) async {
      final db = (await tester.runAsync(openNewInMemoryDatabase))!;
      final legacy = MemorySaveStore();
      final old = await SaveManager(
        legacy,
        now: () => created,
      ).createProfile(slot: 1, areaName: 'Keep until confirmed');
      final snapshot = DistrictGame(watermark: 0).toJson();
      await tester.runAsync(
        () => GameRepository.store.record('1').put(db, snapshot),
      );
      final games = _FailingDeleteRepository(open: () async => db);
      final model = ProfileViewModel(SaveManager(legacy, games: games));
      await tester.pumpWidget(TycoonApp(profiles: model, games: games));
      await tester.pumpAndSettle();
      final remove = find.byKey(const ValueKey('delete-profile-1'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pump();
      expect(find.text('Deleting…'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Delete saved district?'), findsOneWidget);
      expect(games.attempts, 1);
      games.gate.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not delete this district.'),
        findsOneWidget,
      );
      expect(model.profiles.first!.areaName, old.areaName);
      expect(
        await tester.runAsync(() => GameRepository.store.record('1').get(db)),
        snapshot,
      );
      games.fail = false;
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      expect(games.attempts, 2);
      expect(model.profiles.first, isNull);
      expect(find.text('Delete saved district?'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      model.dispose();
      await tester.runAsync(db.close);
    },
  );

  test(
    'delete removes the selected full save and retains the other four slots',
    () async {
      final db = await openNewInMemoryDatabase();
      addTearDown(db.close);
      final legacy = MemorySaveStore();
      final games = GameRepository(open: () async => db);
      final saves = SaveManager(legacy, games: games, now: () => created);
      final originals = <LocalProfile>[];
      for (var slot = 1; slot <= 5; slot++) {
        final profile = await saves.createProfile(
          slot: slot,
          areaName: 'District $slot',
        );
        originals.add(profile);
        await games.update(profile, 0, (state) {
          state.balance = slot * 100000;
        });
      }
      final before = [
        for (var i = 1; i <= 5; i++)
          await GameRepository.store.record('$i').get(db),
      ];
      await saves.deleteProfile(originals[2]);
      final reopened = SaveManager(
        legacy,
        games: GameRepository(open: () async => db),
      );
      final slots = await reopened.loadProfiles();
      expect(slots, hasLength(5));
      expect(slots[2], isNull);
      expect(await GameRepository.store.record('3').get(db), isNull);
      for (final slot in [1, 2, 4, 5]) {
        expect(slots[slot - 1]!.areaName, 'District $slot');
        expect(
          await GameRepository.store.record('$slot').get(db),
          before[slot - 1],
        );
      }
      final marker = (await GameRepository.lifecycle.record('3').get(db))!;
      expect(marker.keys, ['deletedThrough']);
      expect((jsonDecode(legacy.value!)['slots'] as List)[2], isNull);
    },
  );

  test('reusing a deleted slot starts clean and stale sessions/reviews cannot affect it', () async {
    final db = await openNewInMemoryDatabase();
    addTearDown(db.close);
    final games = GameRepository(open: () async => db);
    final saves = SaveManager(
      MemorySaveStore(),
      games: games,
      now: () => created,
    );
    final old = await saves.createProfile(slot: 1, areaName: 'Same name');
    await games.update(old, 0, (state) {
      state.balance = 123;
    });
    await saves.deleteProfile(old);
    var actionRan = false;
    await expectLater(
      games.update(old, 0, (_) {
        actionRan = true;
      }),
      throwsA(isA<GameplayException>()),
    );
    expect(actionRan, isFalse);
    // A backwards clock/same name still receives a distinct saved generation.
    final replacement = await SaveManager(
      MemorySaveStore(),
      games: games,
      now: () => DateTime(2020),
    ).createProfile(slot: 1, areaName: 'Same name');
    expect(replacement.createdAt.isAfter(old.createdAt), isTrue);
    final fresh = await games.update(replacement, 0);
    expect(fresh.balance, 4000000);
    expect(fresh.buildings, isEmpty);
    expect(fresh.pendingRent, 0);
    final snapshot = await GameRepository.store.record('1').get(db);
    await expectLater(saves.deleteProfile(old), throwsStateError);
    await expectLater(games.update(old, 0), throwsA(isA<GameplayException>()));
    expect(await GameRepository.store.record('1').get(db), snapshot);
    expect(
      (await saves.loadProfiles()).first!.createdAt,
      replacement.createdAt,
    );
  });

  test('database deletion stays authoritative if the preference mirror cannot be written or read', () async {
    final db = await openNewInMemoryDatabase();
    addTearDown(db.close);
    final legacy = MemorySaveStore();
    final games = GameRepository(open: () async => db);
    final saves = SaveManager(legacy, games: games, now: () => created);
    final profile = await saves.createProfile(slot: 1, areaName: 'Deleted');
    await games.update(profile, 0);
    legacy.failWrites = true;
    await saves.deleteProfile(profile);
    legacy.failReads = true;
    expect(
      (await SaveManager(legacy, games: games).loadProfiles()).first,
      isNull,
    );
    expect(await GameRepository.store.record('1').get(db), isNull);
    legacy.failReads = false;
    legacy.failWrites = false;
    await saves.loadProfiles();
    expect((jsonDecode(legacy.value!)['slots'] as List).first, isNull);
  });

  test('separate managers serialize deletion and creation without losing other profiles', () async {
    final db = await openNewInMemoryDatabase();
    addTearDown(db.close);
    final legacy = MemorySaveStore();
    final games = GameRepository(open: () async => db);
    final first = SaveManager(legacy, games: games, now: () => created);
    final old = await first.createProfile(slot: 1, areaName: 'Old');
    await first.createProfile(slot: 2, areaName: 'Keep');
    final second = SaveManager(
      legacy,
      games: GameRepository(open: () async => db),
    );
    await Future.wait([
      first.deleteProfile(old),
      second.createProfile(slot: 3, areaName: 'New'),
    ]);
    final slots = await first.loadProfiles();
    expect(slots[0], isNull);
    expect(slots[1]!.areaName, 'Keep');
    expect(slots[2]!.areaName, 'New');
    await Future.wait([
      first.createProfile(slot: 4, areaName: 'Four'),
      second.createProfile(slot: 5, areaName: 'Five'),
    ]);
    expect(
      (await first.loadProfiles()).whereType<LocalProfile>(),
      hasLength(4),
    );
  });

  test('legacy metadata imports once; an explicitly selected unsupported game can be deleted', () async {
    final db = await openNewInMemoryDatabase();
    addTearDown(db.close);
    final legacy = MemorySaveStore();
    final old = await SaveManager(
      legacy,
      now: () => created,
    ).createProfile(slot: 2, areaName: 'Legacy');
    await GameRepository.store.record('2').put(db, {
      'version': 999,
      'private': 'old progress',
    });
    final games = GameRepository(open: () async => db);
    final saves = SaveManager(legacy, games: games);
    expect((await saves.loadProfiles())[1]!.areaName, 'Legacy');
    await saves.deleteProfile(old);
    expect(await GameRepository.store.record('2').get(db), isNull);
    expect((await saves.loadProfiles())[1], isNull);
  });

  test(
    'failed database open and corrupt metadata preserve existing data',
    () async {
      final db = await openNewInMemoryDatabase();
      addTearDown(db.close);
      final legacy = MemorySaveStore();
      final old = await SaveManager(
        legacy,
        now: () => created,
      ).createProfile(slot: 1, areaName: 'Keep');
      final snapshot = DistrictGame(watermark: 0).toJson();
      await GameRepository.store.record('1').put(db, snapshot);
      final before = legacy.value;
      final failing = SaveManager(
        legacy,
        games: GameRepository(
          open: () async => throw StateError('Disk unavailable'),
        ),
      );
      await expectLater(failing.deleteProfile(old), throwsStateError);
      expect(legacy.value, before);
      expect(await GameRepository.store.record('1').get(db), snapshot);
      legacy.value = 'invalid JSON';
      final saves = SaveManager(
        legacy,
        games: GameRepository(open: () async => db),
      );
      await expectLater(
        saves.loadProfiles(),
        throwsA(isA<SaveFormatException>()),
      );
      expect(await GameRepository.profiles.record('catalog').get(db), isNull);
      expect(await GameRepository.store.record('1').get(db), snapshot);
      expect(legacy.value, 'invalid JSON');
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('delete confirmation, cancel, removal and reuse at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = (await tester.runAsync(openNewInMemoryDatabase))!;
      final legacy = MemorySaveStore();
      final games = GameRepository(open: () async => db);
      final saves = SaveManager(legacy, games: games, now: () => created);
      final old = (await tester.runAsync(
        () => saves.createProfile(
          slot: 1,
          areaName: 'Riverside and its very long district name',
        ),
      ))!;
      await tester.runAsync(
        () => saves.createProfile(slot: 2, areaName: 'Keep me'),
      );
      await tester.runAsync(
        () => games.update(old, 0, (state) {
          state.balance = 123;
        }),
      );
      final uiGames = GameRepository(open: () async => db);
      final model = ProfileViewModel(
        SaveManager(legacy, games: uiGames, now: () => created),
      );
      await tester.pumpWidget(TycoonApp(profiles: model, games: uiGames));
      await tester.pumpAndSettle();
      final remove = find.byKey(const ValueKey('delete-profile-1'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('Delete saved district?'), findsOneWidget);
      expect(find.text('Slot 01 · Saved on this device'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(model.profiles.first, isNotNull);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Delete permanently'));
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      expect(model.profiles.first, isNull);
      expect(model.profiles[1]!.areaName, 'Keep me');
      expect(find.byKey(const ValueKey('delete-profile-1')), findsNothing);
      expect(
        (await tester.runAsync(() => GameRepository.store.record('1').get(db))),
        isNull,
      );
      final newButton = find.descendant(
        of: find.byKey(const ValueKey('profile-slot-1')),
        matching: find.text('New'),
      );
      await tester.ensureVisible(newButton);
      await tester.tap(newButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('district-name')),
        'Fresh start',
      );
      await tester.tap(find.text('Create district'));
      await tester.pumpAndSettle();
      final fresh = (await tester.runAsync(
        () => GameRepository.store.record('1').get(db),
      ))!;
      expect(DistrictGame.fromJson(fresh).balance, 4000000);
      expect(DistrictGame.fromJson(fresh).buildings, isEmpty);
      expect(find.text('Fresh start'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      model.dispose();
      await tester.runAsync(db.close);
    });
  }
}
