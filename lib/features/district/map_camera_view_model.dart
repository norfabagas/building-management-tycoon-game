import 'package:flutter/widgets.dart';

/// Session camera settings. Zoom never changes saved land/building geometry.
class MapCameraViewModel extends ChangeNotifier {
  static const zoomLevels = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  int _level = 2;
  Offset _pan = Offset.zero;

  double get zoom => zoomLevels[_level];
  int get percent => (zoom * 100).round();
  Offset get pan => _pan;
  bool get canZoomOut => _level > 0;
  bool get canZoomIn => _level < zoomLevels.length - 1;

  void panBy(Offset delta) {
    _pan += delta;
    notifyListeners();
  }

  void zoomOut() {
    if (canZoomOut) _setLevel(_level - 1);
  }

  void zoomIn() {
    if (canZoomIn) _setLevel(_level + 1);
  }

  void _setLevel(int level) {
    final oldZoom = zoom;
    _level = level;
    _pan *= zoom / oldZoom;
    notifyListeners();
  }

  void center() {
    _pan = Offset.zero;
    notifyListeners();
  }
}
