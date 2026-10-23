import 'package:equatable/equatable.dart';

/// What the timer is counting.
enum FocusPhase { focus, rest }

/// A focus session as a value: rounds of focus with rests in between.
///
/// Time is stored as an end timestamp while running, so the countdown stays
/// right when the app is backgrounded or the screen is left and reopened
/// (docs/redesign-plan.md §3, Focus). Pure: every method takes `now`.
class FocusSession extends Equatable {
  const FocusSession({
    this.phase = FocusPhase.focus,
    this.round = 1,
    this.total = focusLength,
    this.endsAt,
    this.pausedLeft = focusLength,
  });

  static const rounds = 4;
  static const focusLength = Duration(minutes: 25);
  static const shortRest = Duration(minutes: 5);
  static const longRest = Duration(minutes: 15);
  static const extra = Duration(minutes: 5);

  final FocusPhase phase;

  /// 1-based focus round (1..[rounds]).
  final int round;

  /// Length of the current phase, including any minutes added.
  final Duration total;

  /// When the phase ends; null while paused.
  final DateTime? endsAt;

  /// Time left when paused.
  final Duration pausedLeft;

  bool get running => endsAt != null;

  Duration remaining(DateTime now) {
    final end = endsAt;
    if (end == null) return pausedLeft;
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool finished(DateTime now) => remaining(now) == Duration.zero;

  /// 0..1 of the phase elapsed.
  double progress(DateTime now) {
    if (total == Duration.zero) return 1;
    final left = remaining(now).inMilliseconds / total.inMilliseconds;
    return (1 - left).clamp(0.0, 1.0);
  }

  FocusSession start(DateTime now) =>
      running ? this : _copy(endsAt: now.add(pausedLeft));

  FocusSession pause(DateTime now) =>
      running ? _copy(endsAt: null, pausedLeft: remaining(now)) : this;

  /// Restarts the current phase from its full length, paused.
  FocusSession reset() {
    final length = _lengthOf(phase, round);
    return _copy(total: length, endsAt: null, pausedLeft: length);
  }

  /// Adds [extra] minutes to the current phase.
  FocusSession addExtra(DateTime now) {
    final end = endsAt;
    return _copy(
      total: total + extra,
      endsAt: end?.add(extra),
      pausedLeft: end == null ? pausedLeft + extra : pausedLeft,
    );
  }

  /// The phase after this one, paused: focus → rest (long after the last
  /// round) → the next focus round (back to round 1 after a long rest).
  FocusSession next() {
    if (phase == FocusPhase.focus) {
      final length = _lengthOf(FocusPhase.rest, round);
      return FocusSession(
        phase: FocusPhase.rest,
        round: round,
        total: length,
        pausedLeft: length,
      );
    }
    final nextRound = round >= rounds ? 1 : round + 1;
    return FocusSession(round: nextRound);
  }

  /// Whether the rest after this round is the long one.
  bool get longRestNext => round >= rounds;

  static Duration _lengthOf(FocusPhase phase, int round) => switch (phase) {
    FocusPhase.focus => focusLength,
    FocusPhase.rest => round >= rounds ? longRest : shortRest,
  };

  FocusSession _copy({
    Duration? total,
    Object? endsAt = _keep,
    Duration? pausedLeft,
  }) => FocusSession(
    phase: phase,
    round: round,
    total: total ?? this.total,
    endsAt: endsAt == _keep ? this.endsAt : endsAt as DateTime?,
    pausedLeft: pausedLeft ?? this.pausedLeft,
  );

  static const _keep = Object();

  @override
  List<Object?> get props => [phase, round, total, endsAt, pausedLeft];
}

/// Schedules the "phase over" notification; implemented over the platform
/// notifications in data.
abstract class FocusAlarm {
  Future<void> schedule({required Duration after, String? taskTitle});
  Future<void> cancel();
}
