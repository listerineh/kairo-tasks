import '../../tasks/domain/entities/task_entity.dart';
import '../../tasks/domain/quick_dates.dart';
import '../../tasks/domain/streak.dart';
import '../../tasks/domain/task_sections.dart';
import 'mascot/mascot_mood.dart';
import 'mascot/mascot_mood_resolver.dart';

/// What Kairo can suggest on Hoy, in rotation order.
enum KairoTipKind {
  /// "Start with «X»": the next task to do.
  startWith,

  /// "You've done N of M".
  progress,

  /// "Stuck? Tap Focus".
  focus,

  /// Everything due today is done.
  allDone,

  /// Nothing planned and nothing done.
  rest,
}

/// The facts the Hoy screen shows, computed from the task list for [now].
/// Pure: no Flutter, no clock of its own.
class TodaySummary {
  const TodaySummary._({
    required this.now,
    required this.pending,
    required this.done,
    required this.overdue,
    required this.streak,
    required this.next,
    required this.lastCompletionDay,
  });

  factory TodaySummary.from(
    Iterable<TaskEntity> tasks, {
    required DateTime now,
    String? userId,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final sections = {for (final s in groupTasks(tasks, now)) s.kind: s.tasks};
    final overdue = sections[TaskSectionKind.overdue] ?? const <TaskEntity>[];
    final dueToday = sections[TaskSectionKind.today] ?? const <TaskEntity>[];
    final done = [
      for (final t in sections[TaskSectionKind.completed] ?? <TaskEntity>[])
        if (Streak.completedOn(t) == today) t,
    ];

    DateTime? lastCompletion;
    if (userId != null) {
      for (final day in Streak.completionDays(tasks, userId, now)) {
        if (lastCompletion == null || day.isAfter(lastCompletion)) {
          lastCompletion = day;
        }
      }
    }

    return TodaySummary._(
      now: now,
      pending: [...overdue, ...dueToday],
      done: done,
      overdue: overdue.length,
      streak: userId == null ? 0 : Streak.forTasks(tasks, userId, now),
      next: _next(dueToday, now),
      lastCompletionDay: lastCompletion,
    );
  }

  final DateTime now;

  /// Unfinished tasks: overdue first, then today's, earliest first.
  final List<TaskEntity> pending;

  /// Completed today, most recent first.
  final List<TaskEntity> done;
  final int overdue;
  final int streak;

  /// The timed task for the "Ahora" card, if any.
  final TaskEntity? next;
  final DateTime? lastCompletionDay;

  int get total => pending.length + done.length;

  /// 0..1 of today's tasks done.
  double get progress => total == 0 ? 0 : done.length / total;

  /// When [next] starts (its start time, else its due time).
  DateTime? get nextAt => next == null ? null : _timeOf(next!);

  MascotMood mood({bool focusRunning = false}) =>
      const MascotMoodResolver().resolve(
        MascotSituation(
          now: now,
          pendingToday: pending.length,
          completedToday: done.length,
          lastCompletionDay: lastCompletionDay,
          focusRunning: focusRunning,
        ),
      );

  /// Kairo's suggestions in rotation order; tapping him shows the next one.
  List<KairoTipKind> get tips {
    if (total == 0) return const [KairoTipKind.rest];
    if (pending.isEmpty) return const [KairoTipKind.allDone];
    return [
      KairoTipKind.startWith,
      if (done.isNotEmpty) KairoTipKind.progress,
      KairoTipKind.focus,
    ];
  }

  /// The task "start with" names: the next timed one, else the most
  /// pressing pending one.
  TaskEntity? get firstStep => next ?? (pending.isEmpty ? null : pending.first);

  static DateTime? _timeOf(TaskEntity t) {
    for (final d in [t.startDate, t.dueDate]) {
      if (d != null && hasTimeOfDay(d)) return d;
    }
    return null;
  }

  /// The earliest of today's timed tasks that has not ended more than 30
  /// minutes ago; else the last one that did.
  static TaskEntity? _next(List<TaskEntity> today, DateTime now) {
    final timed = [
      for (final t in today)
        if (_timeOf(t) != null) t,
    ]..sort((a, b) => _timeOf(a)!.compareTo(_timeOf(b)!));
    if (timed.isEmpty) return null;
    final cutoff = now.subtract(const Duration(minutes: 30));
    return timed.firstWhere(
      (t) => !_timeOf(t)!.isBefore(cutoff),
      orElse: () => timed.last,
    );
  }
}
