import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalSaveStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// Local metadata storage. Web storage belongs to the current browser origin.
class PreferencesSaveStore implements LocalSaveStore {
  PreferencesSaveStore(this._preferences);

  static const storageKey = 'building_management_tycoon.profiles.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(storageKey);

  @override
  Future<void> write(String value) => _preferences.setString(storageKey, value);
}
