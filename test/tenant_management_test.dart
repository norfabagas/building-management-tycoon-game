import 'dart:async';

import 'package:building_management_tycoon/app/game_theme.dart';
import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/building_presentation.dart';
import 'package:building_management_tycoon/features/district/district_view_model.dart';
import 'package:building_management_tycoon/features/district/tenant_management_screen.dart';
import 'package:building_management_tycoon/shared/widgets/asset_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

final _now = DateTime(2026, 10, 17);
final _profile = LocalProfile(
  slot: 1,
  areaName: 'Release review',
  createdAt: _now,
);
DistrictGame _game(BuildingType type) => DistrictGame(
  watermark: _now.millisecondsSinceEpoch,
  nextBuildingId: 2,
  buildings: [
    ApartmentBuilding(
      id: 1,
      type: type,
      footprint: const Footprint(0, 0, 2, 2),
      stage: ConstructionStage.ready,
      occupied: {0},
      pendingRent: type == BuildingType.apartment ? 12000 : 0,
    ),
  ],
);

Widget _app(DistrictViewModel model) => MaterialApp(
  theme: buildGameTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: Builder(
    builder: (context) => Scaffold(
      body: Column(
        children: [
          const Text('Unit interior'),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TenantManagementScreen(
                  model: model,
                  buildingId: 1,
                  unit: 0,
                ),
              ),
            ),
            child: const Text('Manage'),
          ),
        ],
      ),
    ),
  ),
);

class _FailReleaseRepository extends GameRepository {
  _FailReleaseRepository({required super.open});
  final gate = Completer<void>();
  bool fail = true;
  int requests = 0;
  @override
  Future<DistrictGame> update(
    LocalProfile profile,
    int now, [
    void Function(DistrictGame)? action,
  ]) async {
    if (action != null) {
      requests++;
      if (fail) {
        await gate.future;
        throw StateError('Write failed');
      }
    }
    return super.update(profile, now, action);
  }
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final type in [
      BuildingType.apartment,
      BuildingType.hotel,
      BuildingType.office,
    ]) {
      testWidgets('$type custom release review, cancel and commit at $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = (await tester.runAsync(openNewInMemoryDatabase))!;
        final state = _game(type);
        await tester.runAsync(
          () => GameRepository.store.record('1').put(db, state.toJson()),
        );
        final model = DistrictViewModel(
          _profile,
          GameRepository(open: () async => db),
          now: () => _now,
        )..game = state;
        await tester.pumpWidget(_app(model));
        await tester.tap(find.text('Manage'));
        await tester.pumpAndSettle();
        final page = find.byKey(const ValueKey('tenant-management-page'));
        expect(tester.getSize(page), size);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(SimpleDialog), findsNothing);
        expect(find.text('Tenant management'), findsOneWidget);
        expect(find.text('Release summary'), findsOneWidget);
        final current = tester.widget<Image>(
          find.byKey(const ValueKey('management-current-art')),
        );
        final vacant = tester.widget<Image>(
          find.byKey(const ValueKey('management-vacant-art')),
        );
        expect((current.image as AssetImage).assetName, type.roomArtwork);
        expect((vacant.image as AssetImage).assetName, type.vacantArtwork);
        final action = switch (type) {
          BuildingType.hotel => 'Check out guest',
          BuildingType.office => 'End floor lease',
          _ => 'Vacate room',
        };
        final confirmRect = tester.getRect(find.text(action));
        expect(confirmRect.top, greaterThanOrEqualTo(0));
        expect(confirmRect.bottom, lessThanOrEqualTo(size.height));
        final original = (await tester.runAsync(
          () => GameRepository.store.record('1').get(db),
        ))!;
        await tester.tap(find.text('Keep tenant'));
        await tester.pumpAndSettle();
        expect(find.text('Unit interior'), findsOneWidget);
        expect(
          await tester.runAsync(() => GameRepository.store.record('1').get(db)),
          original,
        );
        await tester.tap(find.text('Manage'));
        await tester.pumpAndSettle();
        final parking = type.baysPerUnit(4);
        await tester.ensureVisible(
          find.text(
            'Parking: $parking reserved ${type == BuildingType.office ? 'bays' : 'bay'}',
          ),
        );
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        expect(find.text('Unit interior'), findsOneWidget);
        final saved = (await tester.runAsync(
          () => GameRepository.store.record('1').get(db),
        ))!;
        final result = DistrictGame.fromJson(saved);
        expect(result.buildings.single.occupied, isEmpty);
        expect(result.buildings.single.usedBays, 0);
        expect(result.pendingRent, state.pendingRent);
        expect(result.balance, state.balance);
        expect(model.error, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        model.dispose();
        await tester.runAsync(db.close);
      });
    }
  }

  testWidgets(
    'pending release blocks duplicate/back actions; failed write can retry in the page',
    (tester) async {
      final db = (await tester.runAsync(openNewInMemoryDatabase))!;
      final state = _game(BuildingType.apartment);
      await tester.runAsync(
        () => GameRepository.store.record('1').put(db, state.toJson()),
      );
      final games = _FailReleaseRepository(open: () async => db);
      final model = DistrictViewModel(_profile, games, now: () => _now)
        ..game = state;
      await tester.pumpWidget(_app(model));
      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vacate room'));
      await tester.pump();
      expect(find.text('Releasing…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Keep tenant'),
            )
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('tenant-management-page')),
        findsOneWidget,
      );
      expect(games.requests, 1);
      games.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Retry release'), findsOneWidget);
      expect(model.game!.buildings.single.occupied, {0});
      expect(
        await tester.runAsync(() => GameRepository.store.record('1').get(db)),
        state.toJson(),
      );
      games.fail = false;
      await tester.tap(find.text('Retry release'));
      await tester.pumpAndSettle();
      expect(games.requests, 2);
      expect(model.game!.buildings.single.occupied, isEmpty);
      expect(model.game!.pendingRent, 12000);
      expect(find.text('Unit interior'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      model.dispose();
      await tester.runAsync(db.close);
    },
  );

  testWidgets(
    'a newly vacant unit refreshes the review and removes release actions',
    (tester) async {
      final db = (await tester.runAsync(openNewInMemoryDatabase))!;
      final state = _game(BuildingType.office);
      await tester.runAsync(
        () => GameRepository.store.record('1').put(db, state.toJson()),
      );
      final model = DistrictViewModel(
        _profile,
        GameRepository(open: () async => db),
        now: () => _now,
      )..game = state;
      await tester.pumpWidget(_app(model));
      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => model.save((game) => DistrictSimulation.vacate(game, 1, 0)),
      );
      await tester.pumpAndSettle();
      expect(find.text('This unit is already vacant'), findsOneWidget);
      expect(find.text('End floor lease'), findsNothing);
      expect(find.byType(AssetAnimation), findsNothing);
      final art = tester.widget<Image>(
        find.byKey(const ValueKey('management-current-art')),
      );
      expect(
        (art.image as AssetImage).assetName,
        BuildingType.office.vacantArtwork,
      );
      await tester.tap(find.text('Back to interior'));
      await tester.pumpAndSettle();
      expect(find.text('Unit interior'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      model.dispose();
      await tester.runAsync(db.close);
    },
  );
}
