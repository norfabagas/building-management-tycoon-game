import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/daylight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets(
    'offline lighting catch-up does not sweep through hundreds of days',
    (tester) async {
      Widget sky(double time) =>
          MaterialApp(home: DaylightOverlay(milliseconds: time));
      await tester.pumpWidget(sky(0));
      await tester.pumpWidget(sky(100 * 24000 + 18000));
      await tester.pump(const Duration(milliseconds: 400));
      final painter =
          tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!
              as DaylightPainter;
      expect(painter.milliseconds.abs(), lessThanOrEqualTo(6000));
      await tester.pump(const Duration(seconds: 1));
      final settled =
          tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!
              as DaylightPainter;
      expect(settled.milliseconds % 24000, 18000);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'schema 5 retains fractional hour progress before the first midnight',
    () {
      final json = DistrictGame(watermark: 1000, balance: 123456).toJson()
        ..['catalog'] = 1
        ..['version'] = 5
        ..['phaseIndex'] = 3
        ..['remainder'] = 2500
        ..['phaseMilliseconds'] = 5000;
      final state = DistrictGame.fromJson(json);
      DistrictSimulation.advance(state, 1000);
      expect(state.timeOfDayMilliseconds, 21000);
      expect(state.balance, 123456);
      expect(state.lastClosing, 0);
      DistrictSimulation.advance(state, 3999);
      expect(state.lastClosing, 0);
      DistrictSimulation.advance(state, 4000);
      expect(state.lastClosing, 1);
      expect(state.day, 2);
      expect(state.balance, 123456);
    },
  );
  testWidgets(
    'lighting interpolates forward through midnight without a flash',
    (tester) async {
      Widget app(double time) => MaterialApp(
        home: SizedBox(
          width: 200,
          height: 100,
          child: DaylightOverlay(milliseconds: time),
        ),
      );
      await tester.pumpWidget(app(23900));
      await tester.pumpWidget(app(24100));
      await tester.pump(const Duration(milliseconds: 400));
      final overlay = find.descendant(
        of: find.byType(DaylightOverlay),
        matching: find.byType(CustomPaint),
      );
      final painter =
          tester.widget<CustomPaint>(overlay).painter! as DaylightPainter;
      expect(painter.milliseconds, closeTo(24000, .01));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<CustomPaint>(overlay).painter! as DaylightPainter)
            .milliseconds,
        24100,
      );
    },
  );
  test('close exactly at hour 24, then advance the calendar once', () {
    final state = DistrictGame(watermark: 0);
    DistrictSimulation.place(state, const Footprint(0, 0, 2, 2));
    DistrictSimulation.advance(state, 23999);
    expect(state.day, 1);
    expect(state.lastClosing, 0);
    expect(state.statement, isNull);
    final balance = state.balance;
    DistrictSimulation.advance(state, 24000);
    expect(state.day, 2);
    expect(state.timeOfDayMilliseconds, 0);
    expect(state.lastClosing, 1);
    expect(state.statement!.day, 1);
    expect(state.balance, balance);
    final saved = state.toJson();
    DistrictSimulation.advance(state, 24000);
    DistrictSimulation.advance(state, 23000);
    expect(state.toJson(), saved);
  });
  test('hourly offline catch-up matches fine steps across Sunday midnight', () {
    DistrictGame mature() => DistrictGame(
      watermark: 0,
      nextBuildingId: 2,
      buildings: [
        ApartmentBuilding(
          id: 1,
          footprint: const Footprint(0, 0, 2, 4),
          stage: ConstructionStage.ready,
          occupied: {0, 1, 2, 3, 4, 5},
        ),
      ],
    );
    final offline = mature(), online = mature();
    for (var time = 250; time <= 168000; time += 250) {
      DistrictSimulation.advance(online, time);
    }
    DistrictSimulation.advance(offline, 168000);
    expect(offline.toJson(), online.toJson());
    expect(offline.statement!.day, 7);
    expect(offline.statement!.rent, 504000);
    expect(offline.pendingRent, 0);
    expect(offline.day, 8);
  });
  test('schema 5 closed Noon migrates without rebilling or repurchasing', () {
    final json = DistrictGame(watermark: 1000, day: 7, lastClosing: 7).toJson()
      ..['catalog'] = 1
      ..['version'] = 5
      ..['phaseIndex'] = 4
      ..['phaseMilliseconds'] = 5000;
    final state = DistrictGame.fromJson(json);
    DistrictSimulation.advance(state, 1000);
    expect(state.day, 8);
    expect(state.lastClosing, 7);
    expect(state.balance, 4000000);
    expect(state.toJson()['version'], 7);
    final saved = state.toJson();
    DistrictSimulation.advance(state, 1000);
    expect(state.toJson(), saved);
  });
  test('daylight is continuous at phase boundaries and midnight', () {
    for (final hour in [
      0.0,
      5.0,
      6.0,
      7.0,
      12.0,
      17.0,
      18.0,
      19.0,
      22.0,
      24.0,
    ]) {
      final before = Daylight.tint((hour - .001 + 24) % 24);
      final after = Daylight.tint((hour + .001) % 24);
      expect((before.a - after.a).abs(), lessThan(.01));
      expect((before.r - after.r).abs(), lessThan(.01));
      expect((before.g - after.g).abs(), lessThan(.01));
      expect((before.b - after.b).abs(), lessThan(.01));
    }
    expect(Daylight.tint(0), Daylight.tint(24));
    expect(Daylight.tint(12).a, 0);
  });
}
