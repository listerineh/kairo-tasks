import 'entities/task_entity.dart';

/// Completion streaks, computed from the user's own completed tasks.
class Streak {
  const Streak._();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// When a task counts as completed: the completion time if known.
  static DateTime completedOn(TaskEntity t) =>
      _day(t.completedAt ?? t.updatedAt ?? t.createdAt);

  /// Days in a row with at least one completion, ending today or yesterday
  /// (a streak survives until the end of the day after its last completion).
  static int fromDays(Iterable<DateTime> days, DateTime today) {
    final unique = days.map(_day).toSet();
    if (unique.isEmpty) return 0;
    final day = _day(today);
    final yesterday = DateTime(day.year, day.month, day.day - 1);
    var cursor = unique.contains(day) ? day : yesterday;
    var count = 0;
    while (unique.contains(cursor)) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  /// Completion days of [userId]'s own tasks, ignoring future dates.
  static Set<DateTime> completionDays(
    Iterable<TaskEntity> tasks,
    String userId,
    DateTime today,
  ) {
    final day = _day(today);
    return {
      for (final t in tasks)
        if (t.ownerId == userId && t.status == TaskStatus.completed)
          completedOn(t),
    }..removeWhere((d) => d.isAfter(day));
  }

  static int forTasks(
    Iterable<TaskEntity> tasks,
    String userId,
    DateTime now,
  ) => fromDays(completionDays(tasks, userId, now), now);

  static bool completedToday(
    Iterable<TaskEntity> tasks,
    String userId,
    DateTime now,
  ) => completionDays(tasks, userId, now).contains(_day(now));
}
