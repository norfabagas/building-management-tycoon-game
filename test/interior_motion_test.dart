import 'package:building_management_tycoon/features/district/interior_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ambient movement is continuous, bounded, varied and includes rest', () {
    final activities = <String>{};
    for (var seed = 0; seed < 12; seed++) {
      for (var tick = 0; tick < 480; tick++) {
        final pose = InteriorMotion.sample(tick / 10, seed);
        final next = InteriorMotion.sample((tick + 1) / 10, seed);
        expect(pose.x, inInclusiveRange(.22, .78));
        expect((next.x - pose.x).abs(), lessThan(.012));
        activities.add(pose.activity);
      }
      expect(InteriorMotion.sample(6, seed).walking, isFalse);
      expect(InteriorMotion.sample(2, seed).walking, isTrue);
    }
    expect(activities.length, 3);
    expect(InteriorMotion.sample(2, 1).x, isNot(InteriorMotion.sample(2, 2).x));
  });
}
