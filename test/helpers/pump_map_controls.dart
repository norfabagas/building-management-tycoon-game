import 'package:flutter_test/flutter_test.dart';

/// Map traffic never settles. Advance finite menu/camera animations while
/// keeping ambient motion enabled for the rotation and gesture assertions.
Future<void> pumpMapControls(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
