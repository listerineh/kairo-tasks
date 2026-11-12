import '../../tasks/domain/entities/task_entity.dart';
import '../../tasks/domain/task_sections.dart';

/// "Haciendo juntos": unfinished tasks shared with at least one person.
/// Dated tasks come first, soonest first; undated ones keep their order.
List<TaskEntity> sharedTasks(Iterable<TaskEntity> tasks) {
  final shared = [
    for (final t in tasks)
      if (t.sharedWith.isNotEmpty && t.status != TaskStatus.completed) t,
  ];
  final dated = [
    for (final t in shared)
      if (taskDate(t) != null) t,
  ]..sort((a, b) => taskDate(a)!.compareTo(taskDate(b)!));
  return [
    ...dated,
    for (final t in shared)
      if (taskDate(t) == null) t,
  ];
}

/// How far along a shared task is, 0 to 1. Tasks have no steps yet, so
/// this follows the status: not started, in progress, done.
double sharedProgress(TaskEntity task) => switch (task.status) {
  TaskStatus.pending => 0,
  TaskStatus.inProgress => 0.5,
  TaskStatus.completed => 1,
};

/// The other people on a task: who it is shared with, or who shared it with
/// me. Each has `id`, `username`, `display_name` and `avatar_url`.
List<String> nudgeTargets(TaskEntity task) => [
  for (final p in task.sharedWith)
    if (p['id'] is String) p['id'] as String,
];
