import 'package:flutter/foundation.dart';

import '../../data/save_manager.dart';
import '../../domain/game_rules.dart';
import '../../domain/local_profile.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._saves);

  final SaveManager _saves;
  List<LocalProfile?> _profiles = List.filled(GameRules.profileSlots, null);
  bool _busy = false;
  bool _loaded = false;
  String? _error;

  List<LocalProfile?> get profiles => List.unmodifiable(_profiles);
  bool get busy => _busy;
  bool get loaded => _loaded;
  String? get error => _error;

  Future<void> load() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _profiles = await _saves.loadProfiles();
      _loaded = true;
    } catch (_) {
      _loaded = false;
      _error = 'Saved districts could not be read. Your saves have been kept.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<LocalProfile> create({
    required int slot,
    required String areaName,
  }) async {
    if (_busy || !_loaded) throw StateError('Profiles are not ready');
    _busy = true;
    notifyListeners();
    try {
      final profile = await _saves.createProfile(
        slot: slot,
        areaName: areaName,
      );
      _profiles = [..._profiles]..[slot - 1] = profile;
      return profile;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
