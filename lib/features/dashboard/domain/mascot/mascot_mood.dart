import 'package:equatable/equatable.dart';

/// How Kairo the cat feels; each mood maps to a target pose.
enum MascotMood {
  /// Default: tasks to do, nothing special going on.
  idle,

  /// A focus session is running.
  focused,

  /// Everything due today is done.
  happy,

  /// Late in the day with nothing done while a streak or tasks are waiting.
  sad,

  /// Night (00:00-06:00) or a rest day with nothing planned.
  sleeping,
}

/// The facts the mood is derived from. All dates are local.
class MascotSituation extends Equatable {
  const MascotSituation({
    required this.now,
    required this.pendingToday,
    required this.completedToday,
    this.lastCompletionDay,
    this.focusRunning = false,
  });

  final DateTime now;

  /// Unfinished tasks due today or overdue.
  final int pendingToday;

  /// Tasks the user completed today.
  final int completedToday;

  /// Most recent day the user completed a task (time ignored).
  final DateTime? lastCompletionDay;

  final bool focusRunning;

  @override
  List<Object?> get props => [
    now,
    pendingToday,
    completedToday,
    lastCompletionDay,
    focusRunning,
  ];
}
