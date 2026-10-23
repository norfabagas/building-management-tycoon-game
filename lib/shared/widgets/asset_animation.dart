import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/production_assets.dart';

/// Uses the exported catalog's frame order and timing, including one-shot FX.
class AssetAnimation extends StatefulWidget {
  const AssetAnimation({
    super.key,
    required this.path,
    this.sequence = 'idle',
    this.width = 64,
    this.height = 96,
    this.hideWhenComplete = false,
  });
  final String path, sequence;
  final double width, height;
  final bool hideWhenComplete;
  @override
  State<AssetAnimation> createState() => _AssetAnimationState();
}

class _AssetAnimationState extends State<AssetAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  static Future<List<dynamic>>? _catalog;
  static final Map<String, Future<ui.Image>> _images = {};
  ui.Image? _image;
  List<int> _frames = [];
  int _columns = 1, _frameWidth = 1, _frameHeight = 1;
  bool _loop = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final path = widget.path, sequence = widget.sequence;
    final catalog = await (_catalog ??= rootBundle
        .loadString(ProductionAssets.manifest)
        .then((text) => jsonDecode(text)['assets'] as List));
    final asset = catalog.cast<Map<String, dynamic>>().firstWhere(
      (a) => a['path'] == path,
    );
    final animation = asset['animations'][sequence] as Map;
    final image = await (_images[path] ??= rootBundle.load(path).then((
      bytes,
    ) async {
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    }));
    if (!mounted || generation != _generation) return;
    setState(() {
      _image = image;
      _frames = List<int>.from(animation['frames'] as List);
      _columns = asset['columns'] as int;
      _frameWidth = asset['frameSize'][0] as int;
      _frameHeight = asset['frameSize'][1] as int;
      _loop = animation['loop'] as bool;
      _controller.duration = Duration(
        milliseconds: (_frames.length * 1000 / (animation['fps'] as num))
            .round(),
      );
    });
    _play();
  }

  void _play() {
    if (_frames.isEmpty || !mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (!_controller.isAnimating && _controller.value == 0) {
      if (_loop) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void didUpdateWidget(AssetAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.sequence != widget.sequence) {
      _controller.stop();
      _controller.value = 0;
      _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (widget.hideWhenComplete &&
            (MediaQuery.disableAnimationsOf(context) ||
                (!_loop && _controller.isCompleted))) {
          return const SizedBox.shrink();
        }
        final image = _image;
        if (image == null || _frames.isEmpty) {
          return SizedBox(width: widget.width, height: widget.height);
        }
        final frame =
            _frames[(_controller.value * _frames.length).floor().clamp(
              0,
              _frames.length - 1,
            )];
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _FramePainter(
              image,
              Rect.fromLTWH(
                (frame % _columns) * _frameWidth.toDouble(),
                (frame ~/ _columns) * _frameHeight.toDouble(),
                _frameWidth.toDouble(),
                _frameHeight.toDouble(),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _FramePainter extends CustomPainter {
  const _FramePainter(this.image, this.source);
  final ui.Image image;
  final Rect source;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
    image,
    source,
    Offset.zero & size,
    Paint()..filterQuality = FilterQuality.low,
  );
  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      oldDelegate.source != source || oldDelegate.image != image;
}
