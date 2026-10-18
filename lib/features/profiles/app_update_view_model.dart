import 'package:flutter/foundation.dart';

import '../../data/app_update_gateway.dart';

class AppUpdateViewModel extends ChangeNotifier {
  AppUpdateViewModel(this._gateway);
  final AppUpdateGateway _gateway;
  String? latestVersion;
  String? message;
  bool checking = false;
  bool syncing = false;
  bool _disposed = false;
  bool get supported => _gateway.supported;
  String get currentVersion => _gateway.currentVersion;
  bool get needsSync =>
      latestVersion != null && latestVersion != currentVersion;

  void _publish() {
    if (!_disposed) notifyListeners();
  }

  Future<void> check() async {
    if (!supported || checking || syncing || _disposed) return;
    checking = true;
    _publish();
    try {
      final version = await _gateway.check().timeout(
        const Duration(seconds: 12),
      );
      if (!RegExp(r'^\d{17}$').hasMatch(version)) throw const FormatException();
      latestVersion = version;
      message = null;
    } catch (_) {
      message = needsSync
          ? 'Update check unavailable. You can retry Sync when online.'
          : 'Offline · version check unavailable';
    } finally {
      checking = false;
      _publish();
    }
  }

  Future<void> sync() async {
    if (!needsSync || checking || syncing || _disposed) return;
    syncing = true;
    message = 'Downloading update. Your saved districts stay on this device.';
    _publish();
    try {
      final result = await _gateway
          .sync(latestVersion!)
          .timeout(const Duration(minutes: 5));
      message = switch (result) {
        'reloading' => 'Update ready. Reloading…',
        'other-tabs' => 'Close the other game tabs, then tap Sync again.',
        'changed' => 'A newer release is available. Tap Sync again.',
        _ => 'Update could not finish. Check your connection and retry Sync.',
      };
      if (result == 'changed') {
        latestVersion = await _gateway.check().timeout(
          const Duration(seconds: 12),
        );
      }
    } catch (_) {
      message = 'Update could not finish. Your saves are safe. Retry Sync when online.';
    } finally {
      syncing = false;
      _publish();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
