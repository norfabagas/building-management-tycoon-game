import 'package:audioplayers/audioplayers.dart';
import 'package:building_management_tycoon/app/production_assets.dart';
import 'package:building_management_tycoon/shared/game_audio.dart';
import 'package:building_management_tycoon/shared/widgets/asset_animation.dart';
import 'package:building_management_tycoon/features/district/vertical_transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class LocalPlayer implements AudioPlayer {
  final sources = <Source>[];
  int stops = 0, disposals = 0;
  bool fail = false;
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    if (fail) throw StateError('Playback unavailable');
    sources.add(source);
  }

  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {}
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget motionApp(Widget child, {bool reduced = false}) => MaterialApp(
  builder: (context, content) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: content!,
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('audio stays uninitialized/muted until a gesture, uses only assets, and mute stops every player', () async {
    final players = <LocalPlayer>[];
    final audio = GameAudio(
      create: () {
        final player = LocalPlayer();
        players.add(player);
        return player;
      },
    );
    await audio.updateMusic(4);
    await audio.effect(ProductionAssets.audioUiConfirm);
    expect(players, isEmpty);
    expect(audio.enabled, isFalse);
    expect(await audio.setEnabled(true), isTrue);
    await audio.updateMusic(2);
    await audio.updateMusic(4);
    await audio.effect(ProductionAssets.audioUiConfirm);
    expect(players.length, 3);
    for (final source in players.expand((p) => p.sources)) {
      expect(source, isA<AssetSource>());
      expect((source as AssetSource).path, startsWith('game/audio/'));
    }
    final count = players.expand((p) => p.sources).length;
    await audio.setEnabled(false);
    await audio.effect(ProductionAssets.audioUiError);
    expect(audio.enabled, isFalse);
    expect(players.every((p) => p.stops > 0), isTrue);
    expect(players.expand((p) => p.sources).length, count);
    await audio.dispose();
    expect(players.every((p) => p.disposals == 1), isTrue);
  });
  test(
    'playback failure mutes/stops ambience and does not escape into gameplay',
    () async {
      final players = <LocalPlayer>[];
      final audio = GameAudio(
        create: () {
          final player = LocalPlayer()..fail = players.isEmpty;
          players.add(player);
          return player;
        },
      );
      expect(await audio.setEnabled(true), isFalse);
      expect(audio.enabled, isFalse);
      expect(players.every((p) => p.stops > 0), isTrue);
      await audio.dispose();
    },
  );
  testWidgets(
    'one-shot financial effect disappears after completion and is omitted for reduced motion',
    (tester) async {
      await tester.pumpWidget(
        motionApp(
          const AssetAnimation(
            path: ProductionAssets.effectsCoin,
            sequence: 'play',
            hideWhenComplete: true,
          ),
        ),
      );
      final paint = find.descendant(
        of: find.byType(AssetAnimation),
        matching: find.byType(CustomPaint),
      );
      for (
        var attempt = 0;
        attempt < 30 && paint.evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(
        find.descendant(
          of: find.byType(AssetAnimation),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.descendant(
          of: find.byType(AssetAnimation),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      await tester.pumpWidget(
        motionApp(
          const AssetAnimation(
            key: ValueKey('reduced'),
            path: ProductionAssets.effectsCoin,
            sequence: 'play',
            hideWhenComplete: true,
          ),
          reduced: true,
        ),
      );
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(AssetAnimation),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('lift carriage moves, arrives once and respects reduced motion', (
    tester,
  ) async {
    var arrivals = 0;
    await tester.pumpWidget(
      motionApp(
        VerticalTransport(
          executive: false,
          direction: 1,
          onArrival: () => arrivals++,
        ),
      ),
    );
    final carriage = find.byKey(const ValueKey('lift-carriage'));
    final before = tester.widget<Positioned>(carriage).top!;
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.widget<Positioned>(carriage).top, lessThan(before));
    expect(arrivals, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(arrivals, 1);
    await tester.pumpWidget(
      motionApp(
        VerticalTransport(
          key: const ValueKey('reduced'),
          executive: true,
          direction: -1,
          onArrival: () => arrivals++,
        ),
        reduced: true,
      ),
    );
    await tester.pump();
    expect(tester.widget<Positioned>(carriage).top, 24);
    expect(arrivals, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
