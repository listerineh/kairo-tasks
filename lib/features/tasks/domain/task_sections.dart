import 'entities/task_entity.dart';

/// List sections, in display order (docs/redesign-plan.md §3, Tasks).
enum TaskSectionKind { overdue, today, upcoming, noDate, completed }

class TaskSection {
  const TaskSection(this.kind, this.tasks);

  final TaskSectionKind kind;
  final List<TaskEntity> tasks;
}

/// Groups tasks into non-empty sections for [now]:
///
/// - **Overdue**: unfinished, dated before today.
/// - **Today**: unfinished, dated today (even if the time has passed).
/// - **Upcoming**: unfinished, dated after today.
/// - **No date**: unfinished, no due or start date.
/// - **Completed**: most recently completed first.
///
/// A task's date is its due date, or its start date when it has no due date.
/// Dated sections run earliest first, ties by priority; "No date" runs by
/// priority, then newest first.
List<TaskSection> groupTasks(Iterable<TaskEntity> tasks, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final buckets = {for (final k in TaskSectionKind.values) k: <TaskEntity>[]};

  for (final task in tasks) {
    final date = taskDate(task);
    final kind = switch (task) {
      _ when task.status == TaskStatus.completed => TaskSectionKind.completed,
      _ when date == null => TaskSectionKind.noDate,
      _ when date.isBefore(today) => TaskSectionKind.overdue,
      _ when date.isBefore(tomorrow) => TaskSectionKind.today,
      _ => TaskSectionKind.upcoming,
    };
    buckets[kind]!.add(task);
  }

  int byDate(TaskEntity a, TaskEntity b) {
    final c = taskDate(a)!.compareTo(taskDate(b)!);
    return c != 0 ? c : _rank(a).compareTo(_rank(b));
  }

  buckets[TaskSectionKind.overdue]!.sort(byDate);
  buckets[TaskSectionKind.today]!.sort(byDate);
  buckets[TaskSectionKind.upcoming]!.sort(byDate);
  buckets[TaskSectionKind.noDate]!.sort((a, b) {
    final c = _rank(a).compareTo(_rank(b));
    return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
  });
  buckets[TaskSectionKind.completed]!.sort(
    (a, b) => _completedAt(b).compareTo(_completedAt(a)),
  );

  return [
    for (final kind in TaskSectionKind.values)
      if (buckets[kind]!.isNotEmpty) TaskSection(kind, buckets[kind]!),
  ];
}

/// The date a task is scheduled for: due date, else start date.
DateTime? taskDate(TaskEntity t) => t.dueDate ?? t.startDate;

int _rank(TaskEntity t) => switch (t.priority) {
  TaskPriority.urgent => 0,
  TaskPriority.high => 1,
  TaskPriority.medium => 2,
  TaskPriority.low => 3,
};

DateTime _completedAt(TaskEntity t) =>
    t.completedAt ?? t.updatedAt ?? t.createdAt;
