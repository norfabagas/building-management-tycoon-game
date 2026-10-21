import 'dart:async';

import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/building_rename_dialog.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'four_types_ui_test.dart' as game;

class RenameTestRepository extends GameRepository {
  RenameTestRepository(Future<Database> Function() open) : super(open: open);
  bool reject = false;
  Completer<void>? gate;
  int actions = 0;
  @override
  Future<DistrictGame> update(
    LocalProfile profile,
    int now, [
    void Function(DistrictGame)? action,
  ]) async {
    if (action != null) {
      actions++;
      if (reject) {
        reject = false;
        throw StateError('Save unavailable');
      }
      await gate?.future;
    }
    return super.update(profile, now, action);
  }
}

void main() {
  for (final pending in [false, true]) {
    testWidgets(
      'rename keeps data safe with keyboard and ${pending ? 'pending guard' : 'failed-save retry'}',
      (tester) async {
        game.viewport(tester, const Size(320, 568));
        final db = (await tester.runAsync(openNewInMemoryDatabase))!;
        final state = DistrictGame(
          watermark: DateTime.now().millisecondsSinceEpoch,
          buildings: [
            ApartmentBuilding(
              id: 1,
              footprint: const Footprint(0, 0, 2, 2),
              stage: ConstructionStage.parkingDone,
            ),
          ],
          nextBuildingId: 2,
        );
        await tester.runAsync(
          () => GameRepository.store.record('1').put(db, state.toJson()),
        );
        final repo = RenameTestRepository(() async => db);
        await tester.pumpWidget(game.gameApp(repo));
        await tester.pumpAndSettle();
        final map = tester.getRect(find.byKey(const ValueKey('district-map')));
        await tester.tapAt(
          map.topLeft + MapProjection(map.size, Offset.zero).point(1, 1),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Rename building'));
        await tester.pumpAndSettle();
        final model = tester
            .widget<BuildingRenameDialog>(find.byType(BuildingRenameDialog))
            .model;
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('building-name')),
          'Harbour Tower',
        );
        final save = find.widgetWithText(FilledButton, 'Save name');
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.getRect(save).bottom, lessThanOrEqualTo(308));
        if (pending) {
          repo.gate = Completer<void>();
        } else {
          repo.reject = true;
        }
        await tester.tap(save);
        await tester.pump();
        if (pending) {
          expect(
            tester
                .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
                .onPressed,
            isNull,
          );
          expect(
            tester
                .widget<TextField>(
                  find.descendant(
                    of: find.byKey(const ValueKey('building-name')),
                    matching: find.byType(TextField),
                  ),
                )
                .readOnly,
            true,
          );
          expect(repo.actions, 1);
          repo.gate!.complete();
        } else {
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: find.byType(BuildingRenameDialog),
              matching: find.textContaining('Progress could not be saved'),
            ),
            findsOneWidget,
          );
          expect(model.game!.buildings.single.name, 'Apartment 1');
          await tester.tap(save);
        }
        await tester.pumpAndSettle();
        final stored = await tester.runAsync(
          () => GameRepository.store.record('1').get(db),
        );
        await tester.pumpAndSettle();
        expect(find.text('Rename building'), findsNothing);
        expect(
          DistrictGame.fromJson(stored!).buildings.single.name,
          'Harbour Tower',
        );
        expect(model.game!.buildings.single.name, 'Harbour Tower');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(db.close);
      },
    );
  }
  for (final type in BuildingType.values) {
    test(
      'rename ${type.name} preserves identity, economy and active work through serialization',
      () {
        final building = ApartmentBuilding(
          id: 1,
          type: type,
          footprint: const Footprint(0, 0, 2, 3),
          stage: ConstructionStage.ready,
          upgrade: UpgradeOrder(
            kind: BuildingUpgrade.floor,
            stage: UpgradeStage.building,
            startedDay: 1,
          ),
        );
        final state = DistrictGame(
          watermark: 0,
          buildings: [building],
          nextBuildingId: 2,
        );
        final before = state.toJson();
        DistrictSimulation.renameBuilding(state, 1, '  Menara Jakarta 🏙  ');
        expect(building.name, 'Menara Jakarta 🏙');
        final restored = DistrictGame.fromJson(state.toJson());
        expect(restored.buildings.single.name, building.name);
        expect(restored.toJson()['version'], 9);
        final after = restored.toJson();
        final first = (before['buildings'] as List).single as Map;
        final second = (after['buildings'] as List).single as Map;
        second.remove('customName');
        expect(second, first);
        expect(after, before);
      },
    );
  }

  test('schema 8 loads default labels and upgrades to 9 with roads/progress intact', () {
    final state = DistrictGame(
      watermark: 0,
      buildings: [
        ApartmentBuilding(id: 1, footprint: const Footprint(0, 0, 2, 3)),
      ],
      nextBuildingId: 2,
    );
    final legacy = state.toJson()..['version'] = 8;
    final loaded = DistrictGame.fromJson(legacy);
    expect(loaded.buildings.single.name, 'Apartment 1');
    final migrated = loaded.toJson();
    expect(migrated['version'], 9);
    migrated['version'] = 8;
    expect(migrated, legacy);
  });

  test('invalid names and stale IDs cannot mutate an existing building', () {
    final state = DistrictGame(
      watermark: 0,
      buildings: [
        ApartmentBuilding(id: 1, footprint: const Footprint(0, 0, 2, 2)),
      ],
      nextBuildingId: 2,
    );
    final before = state.toJson();
    for (final name in ['', '  ', 'x' * 41, 'Tower\nNorth']) {
      expect(
        () => DistrictSimulation.renameBuilding(state, 1, name),
        throwsA(isA<GameplayException>()),
      );
      expect(state.toJson(), before);
    }
    expect(
      () => DistrictSimulation.renameBuilding(state, 2, 'Missing'),
      throwsA(isA<GameplayException>()),
    );
    for (final value in [42, '', 'x' * 41]) {
      final json = state.buildings.single.toJson()..['customName'] = value;
      expect(() => ApartmentBuilding.fromJson(json), throwsFormatException);
    }
  });

  test(
    'rename persists locally and an aborted transaction preserves the old name',
    () async {
      final database = await openNewInMemoryDatabase();
      addTearDown(database.close);
      final repo = GameRepository(open: () async => database);
      final state = DistrictGame(
        watermark: 0,
        buildings: [
          ApartmentBuilding(id: 1, footprint: const Footprint(0, 0, 2, 2)),
        ],
        nextBuildingId: 2,
      );
      await GameRepository.store.record('1').put(database, state.toJson());
      await repo.update(
        game.profile,
        0,
        (state) => DistrictSimulation.renameBuilding(state, 1, 'North Tower'),
      );
      expect(
        (await GameRepository(
          open: () async => database,
        ).update(game.profile, 0)).buildings.single.name,
        'North Tower',
      );
      await expectLater(
        repo.update(game.profile, 10000, (state) {
          DistrictSimulation.renameBuilding(state, 1, 'Lost name');
          throw StateError('Abort transaction');
        }),
        throwsStateError,
      );
      final saved = DistrictGame.fromJson(
        (await GameRepository.store.record('1').get(database))!,
      );
      expect(saved.buildings.single.name, 'North Tower');
      expect(saved.watermark, 0);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets('rename/cancel/save remains reachable $size text $scale', (
        tester,
      ) async {
        game.viewport(tester, size);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = (await tester.runAsync(openNewInMemoryDatabase))!;
        final seed = DistrictGame(
          watermark: DateTime.now().millisecondsSinceEpoch,
          buildings: [
            ApartmentBuilding(
              id: 1,
              footprint: const Footprint(0, 0, 2, 2),
              stage: ConstructionStage.shell,
              startedDay: 1,
            ),
          ],
          nextBuildingId: 2,
        );
        await tester.runAsync(
          () => GameRepository.store.record('1').put(db, seed.toJson()),
        );
        await tester.pumpWidget(
          game.gameApp(GameRepository(open: () async => db)),
        );
        await tester.pumpAndSettle();
        final map = tester.getRect(find.byKey(const ValueKey('district-map')));
        await tester.tapAt(
          map.topLeft + MapProjection(map.size, Offset.zero).point(1, 1),
        );
        await tester.pumpAndSettle();
        final rename = find.byTooltip('Rename building');
        expect(rename.hitTestable(), findsOneWidget);
        expect(tester.getSize(rename).height, greaterThanOrEqualTo(48));
        await tester.tap(rename);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('building-name')),
          'Discarded',
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Apartment 1'), findsOneWidget);
        await tester.tap(rename);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('building-name')),
          '  ',
        );
        await tester.tap(find.text('Save name'));
        await tester.pumpAndSettle();
        expect(find.text('Enter a building name.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('building-name')),
          'Menara Nusantara',
        );
        final save = find.widgetWithText(FilledButton, 'Save name');
        expect(save.hitTestable(), findsOneWidget);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.text('Menara Nusantara'), findsOneWidget);
        expect(find.text('Upgrade building').hitTestable(), findsOneWidget);
        final persisted = (await tester.runAsync(
          () => GameRepository.store.record('1').get(db),
        ))!;
        expect(
          DistrictGame.fromJson(persisted).buildings.single.name,
          'Menara Nusantara',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(db.close);
      });
    }
  }
}
