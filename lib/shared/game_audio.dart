import 'package:audioplayers/audioplayers.dart';

import '../app/production_assets.dart';

/// Local media only. Creation/playback starts after an explicit sound gesture.
class GameAudio {
  GameAudio({AudioPlayer Function()? create})
    : _create = create ?? AudioPlayer.new;
  final AudioPlayer Function() _create;
  AudioPlayer? _music, _effect, _ambience;
  bool enabled = false;
  bool _starting = false;
  int _epoch = 0;
  String? _track;
  static AssetSource _source(String path) =>
      AssetSource(path.substring('assets/'.length));
  Future<bool> setEnabled(bool value, {int businesses = 0}) async {
    final epoch = ++_epoch;
    enabled = value;
    _starting = value;
    try {
      if (!value) {
        await _stopAll();
        _track = null;
        return true;
      }
      _music ??= _create();
      _effect ??= _create();
      _ambience ??= _create();
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _ambience!.setReleaseMode(ReleaseMode.loop);
      if (epoch != _epoch || !enabled) return false;
      await _ambience!.play(
        _source(ProductionAssets.audioCityAmbience),
        volume: .12,
      );
      if (epoch != _epoch || !enabled) {
        await _stopAll();
        return false;
      }
      await _playMusic(businesses);
      return enabled && epoch == _epoch;
    } catch (_) {
      enabled = false;
      await _stopAll();
      return false;
    } finally {
      if (epoch == _epoch) _starting = false;
    }
  }

  Future<void> updateMusic(int businesses) async {
    if (!enabled || _music == null || _starting) return;
    try {
      await _playMusic(businesses);
    } catch (_) {
      enabled = false;
      await _stopAll();
    }
  }

  Future<void> _playMusic(int businesses) async {
    final epoch = _epoch;
    final track = businesses >= 4
        ? ProductionAssets.audioMusicBusyDistrict
        : businesses >= 2
        ? ProductionAssets.audioMusicGrowingDistrict
        : ProductionAssets.audioMusicSmallDistrict;
    if (_track == track) return;
    await _music!.play(_source(track), volume: .22);
    if (epoch != _epoch || !enabled) {
      await _music!.stop();
      return;
    }
    _track = track;
  }

  Future<void> _stopAll() async {
    _track = null;
    try {
      await Future.wait([
        if (_music != null) _music!.stop(),
        if (_effect != null) _effect!.stop(),
        if (_ambience != null) _ambience!.stop(),
      ]);
    } catch (_) {
      /* Sound failure does not block gameplay. */
    }
  }

  Future<void> effect(String path) async {
    if (!enabled || _effect == null) return;
    final epoch = _epoch;
    try {
      await _effect!.play(_source(path), volume: .35);
      if (epoch != _epoch || !enabled) await _effect!.stop();
    } catch (_) {
      /* Audio never blocks saving or gameplay. */
    }
  }

  Future<void> dispose() async {
    enabled = false;
    _epoch++;
    try {
      await Future.wait([
        if (_music != null) _music!.dispose(),
        if (_effect != null) _effect!.dispose(),
        if (_ambience != null) _ambience!.dispose(),
      ]);
    } catch (_) {
      /* Release all possible local player resources. */
    }
  }
}
