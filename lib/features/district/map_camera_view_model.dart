import 'package:flutter/widgets.dart';

/// Session camera settings. Zoom never changes saved land/building geometry.
class MapCameraViewModel extends ChangeNotifier {
  static const zoomLevels = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  double _zoom = 1;
  Offset _pan = Offset.zero;

  double get zoom => _zoom;
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
  }) {
    final next = zoom.clamp(zoomLevels.first, zoomLevels.last);
    _pan = toFocal - (fromFocal - _pan) * (next / _zoom);
    _zoom = next;
    notifyListeners();
  }

  void center() {
    _pan = Offset.zero;
    notifyListeners();
  }
}
