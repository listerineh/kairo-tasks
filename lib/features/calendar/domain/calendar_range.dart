import '../../tasks/domain/entities/task_entity.dart';

enum CalendarViewType { day, week, month }

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The Sunday that starts [date]'s week.
DateTime startOfWeek(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday % 7);

/// The date one page before or after [date] in [view]: a day, a week, or
/// the first of the neighbouring month.
DateTime stepDate(
  DateTime date,
  CalendarViewType view, {
  required bool forward,
}) {
  final sign = forward ? 1 : -1;
  return switch (view) {
    CalendarViewType.day => DateTime(date.year, date.month, date.day + sign),
    CalendarViewType.week => DateTime(
      date.year,
      date.month,
      date.day + 7 * sign,
    ),
    CalendarViewType.month => DateTime(date.year, date.month + sign),
  };
}

/// Tasks whose span (start, else due, else creation; until due) touches [day].
List<TaskEntity> tasksOnDay(Iterable<TaskEntity> tasks, DateTime day) {
  final start = _day(day);
  final end = DateTime(start.year, start.month, start.day + 1);
  return [
    for (final t in tasks)
      if (_overlaps(t, start, end)) t,
  ];
}

bool _overlaps(TaskEntity t, DateTime start, DateTime end) {
  final from = t.startDate ?? t.dueDate ?? t.createdAt;
  final to = t.dueDate ?? from;
  // A zero-length task still belongs to the day it sits on.
  return from.isBefore(end) && (to.isAfter(start) || to == start);
}

/// My tasks plus friends' tasks, mine winning when both have the same id
/// (a friend's task shared with me).
List<TaskEntity> mergeTasks(
  Iterable<TaskEntity> mine,
  Iterable<TaskEntity> friends,
) {
  final byId = {for (final t in mine) t.id: t};
  for (final t in friends) {
    byId.putIfAbsent(t.id, () => t);
  }
  return byId.values.toList();
}
