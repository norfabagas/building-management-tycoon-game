import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Continuous, cyclic lighting; midnight has the same color on both sides.
abstract final class Daylight {
  static const hours = [0.0, 5.0, 7.0, 12.0, 17.0, 19.0, 22.0, 24.0];
  static const colors = [
    Color(0x59202B59),
    Color(0x59202B59),
    Color(0x22F4B66F),
    Color(0x00FFF5D5),
    Color(0x18F3BA74),
    Color(0x405C4C83),
    Color(0x59202B59),
    Color(0x59202B59),
  ];
  static Color tint(double hour) {
    hour %= 24;
    for (var i = 1; i < hours.length; i++) {
      if (hour <= hours[i]) {
        return Color.lerp(
          colors[i - 1],
          colors[i],
          (hour - hours[i - 1]) / (hours[i] - hours[i - 1]),
        )!;
      }
    }
    return colors.first;
  }
}

class DaylightOverlay extends StatefulWidget {
  const DaylightOverlay({super.key, required this.milliseconds});
  final double milliseconds;
  @override
  State<DaylightOverlay> createState() => _DaylightOverlayState();
}

class _DaylightOverlayState extends State<DaylightOverlay> {
  late double _target = widget.milliseconds;
  @override
  void didUpdateWidget(DaylightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final delta = widget.milliseconds - oldWidget.milliseconds;
    // Offline catch-up must crossfade to the new sky, not wind through weeks.
    _target += delta.abs() <= 6000 ? delta : (delta + 12000) % 24000 - 12000;
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: _target, end: _target),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 800),
      builder: (context, time, _) =>
          CustomPaint(painter: DaylightPainter(time)),
    ),
  );
}

class DaylightPainter extends CustomPainter {
  DaylightPainter(this.milliseconds);
  final double milliseconds;
  @override
  void paint(Canvas canvas, Size size) {
    final hour = milliseconds / 1000 % 24;
    final tint = Daylight.tint(hour);
    final angle = (hour - 6) / 24 * 2 * math.pi;
    final direction = Alignment(math.cos(angle), math.sin(angle));
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: direction,
          end: Alignment(-direction.x, -direction.y),
          colors: [
            tint.withValues(alpha: tint.a * .6),
            tint,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(DaylightPainter oldDelegate) =>
      oldDelegate.milliseconds != milliseconds;
}
