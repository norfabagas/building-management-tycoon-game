import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Session camera settings. Zoom never changes saved land/building geometry.
class MapCameraViewModel extends ChangeNotifier {
  static const zoomLevels = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  double _zoom = 1;
  double _rotation = 0;
  Offset _pan = Offset.zero;

  double get zoom => _zoom;
  double get rotation => _rotation;
  int get bearing => (_rotation * 180 / math.pi).round() % 360;
  int get percent => (zoom * 100).round();
  Offset get pan => _pan;
  bool get canZoomOut => _zoom > zoomLevels.first;
  bool get canZoomIn => _zoom < zoomLevels.last;

  void panBy(Offset delta) {
    _pan += delta;
    notifyListeners();
  }

  void zoomOut() {
    if (canZoomOut) _setZoom(((_zoom * 4).ceil() - 1) / 4);
  }

  void zoomIn() {
    if (canZoomIn) _setZoom(((_zoom * 4).floor() + 1) / 4);
  }

  void _setZoom(double value) =>
      transform(zoom: value, fromFocal: Offset.zero, toFocal: Offset.zero);

  /// Focal points are relative to the viewport centre. Also supports pinch panning.
  void transform({
    required double zoom,
    required Offset fromFocal,
    required Offset toFocal,
    double? rotation,
    Offset originOffset = Offset.zero,
  }) {
    final next = zoom.clamp(zoomLevels.first, zoomLevels.last);
    final angle = rotation ?? _rotation;
    final delta = angle - _rotation;
    final ratio = next / _zoom;
    final vector = fromFocal - _pan - originOffset;
    final rotated = Offset(
      math.cos(delta) * vector.dx - 2 * math.sin(delta) * vector.dy,
      .5 * math.sin(delta) * vector.dx + math.cos(delta) * vector.dy,
    );
    _pan = toFocal - originOffset * ratio - rotated * ratio;
    _rotation = angle % (2 * math.pi);
    _zoom = next;
    notifyListeners();
  }

  void rotateBy(double radians, {Offset originOffset = Offset.zero}) =>
      transform(
        zoom: _zoom,
        rotation: _rotation + radians,
        fromFocal: Offset.zero,
        toFocal: Offset.zero,
        originOffset: originOffset,
      );

  void resetRotation({Offset originOffset = Offset.zero}) => transform(
    zoom: _zoom,
    rotation: 0,
    fromFocal: Offset.zero,
    toFocal: Offset.zero,
    originOffset: originOffset,
  );

  void center() {
    _rotation = 0;
    _pan = Offset.zero;
    notifyListeners();
  }
}
