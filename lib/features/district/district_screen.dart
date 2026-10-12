import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../domain/local_profile.dart';
import '../../shared/widgets/game_brand.dart';

/// Empty district canvas for project bootstrap. No economy simulation yet.
class DistrictScreen extends StatelessWidget {
  const DistrictScreen({super.key, required this.profile});
  final LocalProfile profile;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const GameBrand(size: 32, fontSize: 20)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.areaName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Drag to pan',
              style: TextStyle(fontSize: 18, color: GameColors.muted),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ColoredBox(
                  color: GameColors.surface,
                  child: Semantics(
                    label: 'Empty district map. Drag to pan.',
                    child: InteractiveViewer(
                      scaleEnabled: false,
                      boundaryMargin: const EdgeInsets.all(400),
                      child: const SizedBox.expand(
                        child: CustomPaint(painter: _EmptyDistrictPainter()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Visual grid only. Bounds, placement and land expansion need game rules.
class _EmptyDistrictPainter extends CustomPainter {
  const _EmptyDistrictPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cells = 8;
    final tileWidth = (size.width / (cells + 1)).clamp(28.0, 128.0);
    final tileHeight = tileWidth / 2;
    final origin = Offset(
      size.width / 2,
      (size.height - tileHeight * cells) / 2,
    );
    final fill = Paint()..color = GameColors.land;
    final outline = Paint()
      ..color = const Color(0xFF97B675)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var row = 0; row < cells; row++) {
      for (var col = 0; col < cells; col++) {
        final center =
            origin +
            Offset((col - row) * tileWidth / 2, (row + col) * tileHeight / 2);
        final tile = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + tileWidth / 2, center.dy + tileHeight / 2)
          ..lineTo(center.dx, center.dy + tileHeight)
          ..lineTo(center.dx - tileWidth / 2, center.dy + tileHeight / 2)
          ..close();
        canvas.drawPath(tile, fill);
        canvas.drawPath(tile, outline);
      }
    }
  }

  @override
  bool shouldRepaint(_EmptyDistrictPainter oldDelegate) => false;
}
