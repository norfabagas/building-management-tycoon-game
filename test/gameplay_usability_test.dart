import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'four_types_ui_test.dart' show click, gameApp, viewport;

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'completed building has a map action and floor content precedes details at $size',
      (tester) async {
        viewport(tester, size);
        final db = (await tester.runAsync(openNewInMemoryDatabase))!;
        final state = DistrictGame(
          watermark: DateTime.now().millisecondsSinceEpoch,
          nextBuildingId: 2,
          buildings: [
            ApartmentBuilding(
              id: 1,
              footprint: const Footprint(0, 0, 2, 2),
              stage: ConstructionStage.parkingDone,
            ),
          ],
        );
        await tester.runAsync(
          () => GameRepository.store.record('1').put(db, state.toJson()),
        );
        await tester.pumpWidget(gameApp(GameRepository(open: () async => db)));
        await tester.pumpAndSettle();
        await click(tester, 'Open Apartment 1');
        // A map shortcut reviews the building; only the explicit opening admits business.
        expect(find.text('Open to Business'), findsOneWidget);
        await click(tester, 'Open to Business');
        expect(find.text('Room 1'), findsOneWidget);
        expect(find.text('Permanent footprint'), findsNothing);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('building-floor-view')))
              .height,
          greaterThan(135),
        );
        if (size == const Size(844, 390)) {
          expect(
            tester
                .getTopLeft(find.byKey(const ValueKey('room-artwork-1-0')))
                .dy,
            greaterThanOrEqualTo(
              tester
                  .getTopLeft(find.byKey(const ValueKey('building-floor-view')))
                  .dy,
            ),
          );
          expect(
            tester
                .getBottomRight(find.byKey(const ValueKey('room-artwork-1-0')))
                .dy,
            lessThanOrEqualTo(
              tester
                  .getBottomRight(
                    find.byKey(const ValueKey('building-floor-view')),
                  )
                  .dy,
            ),
          );
        }
        await click(tester, 'Building details');
        expect(find.text('Permanent footprint'), findsOneWidget);
        expect(find.text('Happiness'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(db.close);
      },
    );
  }
  testWidgets(
    'office review exposes cash reserve and B1 constraint before purchase',
    (tester) async {
      viewport(tester, const Size(1440, 900));
      final db = (await tester.runAsync(openNewInMemoryDatabase))!;
      await tester.pumpWidget(gameApp(GameRepository(open: () async => db)));
      await tester.pumpAndSettle();
      await click(tester, 'Build');
      expect(find.text('\$840 / room / week · Paid Sunday'), findsOneWidget);
      expect(
        find.text('\$25 / visiting party · Four windows a day'),
        findsOneWidget,
      );
      await click(tester, 'Choose office tower');
      await tester.tap(find.byKey(const ValueKey('initial-floor-plus')));
      await tester.pumpAndSettle();
      final map = tester.getRect(find.byKey(const ValueKey('district-map')));
      final projection = MapProjection(map.size, Offset.zero);
      final drag = await tester.startGesture(
        map.topLeft + projection.point(2.5, 2.5),
      );
      await drag.moveTo(map.topLeft + projection.point(3.5, 3.5));
      await drag.up();
      await tester.pumpAndSettle();
      await click(tester, 'Review cost');
      expect(find.text('Balance after purchase'), findsOneWidget);
      expect(find.text('\$12,400.00'), findsOneWidget);
      expect(find.text('Capacity with B1'), findsOneWidget);
      expect(find.text('1 / 2 floor leases'), findsOneWidget);
      final saved = (await tester.runAsync(
        () => GameRepository.store.record('1').get(db),
      ))!;
      expect(DistrictGame.fromJson(saved).balance, 4000000);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(db.close);
    },
  );
}
