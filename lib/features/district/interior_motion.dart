import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Seeded ambient movement independent of saved phase transitions.
class InteriorMotion {
  const InteriorMotion(
    this.x,
    this.walking,
    this.facingLeft,
    this.activity,
    this.icon,
  );
  final double x;
  final bool walking, facingLeft;
  final String activity;
  final IconData icon;
  static InteriorMotion sample(double seconds, int seed) {
    final random = math.Random(seed);
    final stops = [for (var i = 0; i < 4; i++) .22 + random.nextDouble() * .56];
    final segment = (seconds / 12).floor() % 4;
    final local = seconds % 12;
    final from = stops[segment], to = stops[(segment + 1) % 4];
    final activity = (seed + segment) % 3;
    return InteriorMotion(
      from + (to - from) * (local / 5).clamp(0.0, 1.0),
      local < 5,
      to < from,
      ['Taking a break', 'Checking messages', 'Looking around'][activity],
      [
        Icons.coffee_outlined,
        Icons.phone_android_outlined,
        Icons.visibility_outlined,
      ][activity],
    );
  }
}
