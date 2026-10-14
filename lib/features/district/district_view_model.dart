import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/game_repository.dart';
import '../../domain/district_game.dart';
import '../../domain/local_profile.dart';

class DistrictViewModel extends ChangeNotifier {
  DistrictViewModel(this.profile, this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final LocalProfile profile;
  final GameRepository repository;
  final DateTime Function() _now;
  DistrictGame? game;
  bool busy = false;
  bool _disposed = false;
  String? error;
  String? returnSummary;
  Timer? _timer;
  int? selectedBuildingId;
  int currentFloor = 1;

  ApartmentBuilding? get selectedBuilding {
    for (final building in game?.buildings ?? <ApartmentBuilding>[]) {
      if (building.id == selectedBuildingId) return building;
    }
    return null;
  }

  String get floorLabel => currentFloor == 1 ? 'Floor 1' : 'B1';
  bool get canGoUp => selectedBuilding != null && currentFloor == -1;
  bool get canGoDown =>
      selectedBuilding?.parkingComplete == true && currentFloor == 1;

  void selectBuilding(int? id) {
    selectedBuildingId = id;
    currentFloor = 1;
    notifyListeners();
  }

  void goUp() {
    if (!canGoUp) return;
    currentFloor = 1;
    notifyListeners();
  }

  void goDown() {
    if (!canGoDown) return;
    currentFloor = -1;
    notifyListeners();
  }

  Future<bool> save([void Function(DistrictGame)? action]) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final next = await repository.update(
        profile,
        _now().millisecondsSinceEpoch,
        action,
      );
      if (_disposed) return true;
      game = next;
      if (next.advancedDays > 1) {
        returnSummary =
            '${next.advancedDays} game days processed. Balance change: ${formatMoney(next.balance - next.balanceBeforeAdvance)}. Rent still pending: ${formatMoney(next.pendingRent)}.';
      }
      return true;
    } on GameplayException catch (failure) {
      if (!_disposed) error = failure.message;
      return false;
    } catch (_) {
      if (!_disposed) error = 'Progress could not be saved. Your last saved game is preserved. Retry before continuing.';
      return false;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> load() async {
    await save();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || busy || error != null || game == null) return;
      final elapsed = _now().millisecondsSinceEpoch - game!.watermark;
      if (elapsed >= 10000 ||
          elapsed + game!.remainder >= StarterCatalog.phaseMilliseconds) {
        unawaited(save());
      } else {
        notifyListeners();
      }
    });
  }

  int get secondsRemaining {
    final state = game;
    if (state == null) return 60;
    final delta = (_now().millisecondsSinceEpoch - state.watermark).clamp(
      0,
      60000,
    );
    return ((StarterCatalog.phaseMilliseconds - state.remainder - delta) / 1000)
        .ceil()
        .clamp(0, 60);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

String formatMoney(int cents) {
  final digits = (cents.abs() ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${cents < 0 ? '−' : ''}\$$digits.${(cents.abs() % 100).toString().padLeft(2, '0')}';
}
