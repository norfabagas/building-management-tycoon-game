import 'package:flutter/material.dart';

import '../../app/production_assets.dart';
import '../../shared/widgets/asset_animation.dart';

/// Short visual travel cue only; capacity comes from saved lift counts.
class VerticalTransport extends StatefulWidget {
  const VerticalTransport({
    super.key,
    required this.executive,
    required this.direction,
    required this.onArrival,
  });
  final bool executive;
  final int direction;
  final VoidCallback onArrival;
  @override
  State<VerticalTransport> createState() => _VerticalTransportState();
}

class _VerticalTransportState extends State<VerticalTransport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _travel =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            widget.direction != 0 &&
            !MediaQuery.disableAnimationsOf(context)) {
          widget.onArrival();
        }
      });
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || widget.direction == 0) {
      _travel.stop();
      _travel.value = 1;
    } else if (!_started) {
      _started = true;
      _travel.forward();
    }
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 90,
    height: 150,
    child: AnimatedBuilder(
      animation: _travel,
      builder: (context, _) {
        final offset = (1 - Curves.easeInOut.transform(_travel.value)) * 60;
        return Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              ProductionAssets.transportLiftShaft,
              width: 82,
              height: 145,
              fit: BoxFit.fill,
            ),
            Positioned(
              key: const ValueKey('lift-carriage'),
              top: 24 + (widget.direction < 0 ? -offset : offset),
              child: SizedBox(
                width: 54,
                height: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.executive
                          ? ProductionAssets.transportExecutiveCarriage
                          : ProductionAssets.transportStandardCarriage,
                    ),
                    if (_travel.isCompleted)
                      AssetAnimation(
                        path: widget.executive
                            ? ProductionAssets.transportExecutiveDoors
                            : ProductionAssets.transportStandardDoors,
                        sequence: 'open',
                        width: 54,
                        height: 90,
                      ),
                  ],
                ),
              ),
            ),
            if (_travel.isCompleted && !MediaQuery.disableAnimationsOf(context))
              const Positioned(
                top: 0,
                child: AssetAnimation(
                  path: ProductionAssets.effectsLiftArrival,
                  sequence: 'play',
                  width: 36,
                  height: 36,
                  hideWhenComplete: true,
                ),
              ),
          ],
        );
      },
    ),
  );
}
