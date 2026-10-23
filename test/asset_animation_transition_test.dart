import 'package:building_management_tycoon/app/production_assets.dart';
import 'package:building_management_tycoon/shared/widgets/asset_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'sprite keeps its box and painted frame during sequence changes',
    (tester) async {
      Widget app(String sequence) => MaterialApp(
        home: Center(
          child: AssetAnimation(
            path: ProductionAssets.charactersResidentAnimation,
            sequence: sequence,
            width: 102,
            height: 153,
          ),
        ),
      );
      final paint = find.descendant(
        of: find.byType(AssetAnimation),
        matching: find.byType(CustomPaint),
      );
      await tester.pumpWidget(app('walk'));
      expect(tester.getSize(find.byType(AssetAnimation)), const Size(102, 153));
      for (var i = 0; i < 40 && paint.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      expect(paint, findsOneWidget);
      for (final sequence in ['idle', 'walk', 'idle']) {
        await tester.pumpWidget(app(sequence));
        expect(
          tester.getSize(find.byType(AssetAnimation)),
          const Size(102, 153),
        );
        expect(paint, findsOneWidget);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 250));
        expect(paint, findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
