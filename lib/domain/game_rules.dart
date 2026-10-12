/// Constants and phase order specified in docs/Rules.md and docs/Logic.md.
abstract final class GameRules {
  static const profileSlots = 5;
  static const maximumUndergroundFloors = 3;
  static const maximumStandardLifts = 3;
  static const maximumExecutiveLifts = 1;
}

enum GamePhase {
  morning('Morning'),
  day('Day'),
  afternoon('Afternoon'),
  night('Night'),
  noon('Noon');

  const GamePhase(this.label);
  final String label;
}

/// A clock value only. Simulation timing and balancing are not defined yet.
class GameClock {
  GameClock({this.day = 1, this.phase = GamePhase.morning}) {
    if (day < 1) throw ArgumentError.value(day, 'day');
  }

  final int day;
  final GamePhase phase;

  GameClock nextPhase() => phase == GamePhase.noon
      ? GameClock(day: day + 1)
      : GameClock(day: day, phase: GamePhase.values[phase.index + 1]);
}

enum BuildingType { apartment, hotel, office, foodCourt }
