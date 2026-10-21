import 'dart:math' as math;

import '../../tasks/domain/entities/task_entity.dart';

/// Minutes in a day; positions on the timeline are minutes from midnight.
const minutesPerDay = 24 * 60;

/// Default length for a task with a single time (start or due only).
const defaultBlockMinutes = 30;

/// A task placed on one day's timeline. Overlapping tasks share the width:
/// [column] of [columns].
class TimelineBlock {
  const TimelineBlock({
    required this.task,
    required this.startMinute,
    required this.endMinute,
    this.column = 0,
    this.columns = 1,
  });

  final TaskEntity task;
  final int startMinute;
  final int endMinute;
  final int column;
  final int columns;

  TimelineBlock _place(int column, int columns) => TimelineBlock(
    task: task,
    startMinute: startMinute,
    endMinute: endMinute,
    column: column,
    columns: columns,
  );
}

bool _hasTime(DateTime d) => d.hour != 0 || d.minute != 0;

/// A date-only task (no time on its start or due date) shows in the
/// all-day strip instead of on the timeline.
bool isAllDay(TaskEntity t) {
  final start = t.startDate;
  final due = t.dueDate;
  if (start == null && due == null) return false;
  return (start == null || !_hasTime(start)) && (due == null || !_hasTime(due));
}

/// The task's span: start to due; with only one of them, a
/// [defaultBlockMinutes] block ending at due or starting at start.
(DateTime, DateTime)? taskSpan(TaskEntity t) {
  final start = t.startDate;
  final due = t.dueDate;
  if (start == null && due == null) return null;
  final from =
      start ?? due!.subtract(const Duration(minutes: defaultBlockMinutes));
  final to = due ?? start!.add(const Duration(minutes: defaultBlockMinutes));
  return to.isAfter(from)
      ? (from, to)
      : (from, from.add(const Duration(minutes: 15)));
}

/// Timed tasks touching [day], clipped to it, with overlap columns.
List<TimelineBlock> layoutDay(Iterable<TaskEntity> tasks, DateTime day) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = DateTime(day.year, day.month, day.day + 1);

  final blocks = <TimelineBlock>[];
  for (final t in tasks) {
    if (isAllDay(t)) continue;
    final span = taskSpan(t);
    if (span == null) continue;
    final (from, to) = span;
    if (!from.isBefore(dayEnd) || !to.isAfter(dayStart)) continue;
    final start = from.isBefore(dayStart)
        ? 0
        : from.difference(dayStart).inMinutes;
    final end = to.isAfter(dayEnd)
        ? minutesPerDay
        : to.difference(dayStart).inMinutes;
    blocks.add(
      TimelineBlock(
        task: t,
        startMinute: start,
        // Very short tasks still need room for a line of text.
        endMinute: math.min(minutesPerDay, math.max(end, start + 15)),
      ),
    );
  }
  blocks.sort((a, b) {
    final c = a.startMinute.compareTo(b.startMinute);
    return c != 0 ? c : b.endMinute.compareTo(a.endMinute);
  });
  return _assignColumns(blocks);
}

/// Greedy interval colouring per cluster of mutually overlapping blocks.
List<TimelineBlock> _assignColumns(List<TimelineBlock> sorted) {
  final result = <TimelineBlock>[];
  var cluster = <(TimelineBlock, int)>[];
  var clusterEnd = -1;
  final columnEnds = <int>[];

  void flush() {
    final columns = columnEnds.length;
    for (final (block, column) in cluster) {
      result.add(block._place(column, columns));
    }
    cluster = [];
    columnEnds.clear();
  }

  for (final block in sorted) {
    if (block.startMinute >= clusterEnd && cluster.isNotEmpty) flush();
    var column = columnEnds.indexWhere((end) => end <= block.startMinute);
    if (column == -1) {
      column = columnEnds.length;
      columnEnds.add(block.endMinute);
    } else {
      columnEnds[column] = block.endMinute;
    }
    cluster.add((block, column));
    clusterEnd = math.max(clusterEnd, block.endMinute);
  }
  if (cluster.isNotEmpty) flush();
  return result;
}

/// Date-only tasks for [day]'s all-day strip.
List<TaskEntity> allDayTasks(Iterable<TaskEntity> tasks, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return [
    for (final t in tasks)
      if (isAllDay(t) && _coversDay(t, d)) t,
  ];
}

bool _coversDay(TaskEntity t, DateTime day) {
  final from = t.startDate ?? t.dueDate!;
  final to = t.dueDate ?? from;
  return !day.isBefore(DateTime(from.year, from.month, from.day)) &&
      !day.isAfter(DateTime(to.year, to.month, to.day));
}

/// Rounds [minute] to the nearest [step], kept inside the day.
int snapMinute(num minute, {int step = 15}) =>
    ((minute / step).round() * step).clamp(0, minutesPerDay - step);

/// New start and due dates after dragging [task] so it starts at
/// [newStart], keeping its length. A due-only task keeps being due-only.
({DateTime? start, DateTime? due}) moveTask(
  TaskEntity task,
  DateTime newStart,
) {
  final span = taskSpan(task);
  if (span == null) return (start: task.startDate, due: task.dueDate);
  final (from, to) = span;
  final length = to.difference(from);
  return (
    start: task.startDate == null ? null : newStart,
    due: task.dueDate == null ? null : newStart.add(length),
  );
}
