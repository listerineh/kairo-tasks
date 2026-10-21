import 'package:equatable/equatable.dart';

import 'task_entity.dart';

/// The user-editable fields of a task, used to create or update one.
class TaskDraft extends Equatable {
  const TaskDraft({
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.startDate,
    this.dueDate,
    this.sharedWithIds,
  });

  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? startDate;
  final DateTime? dueDate;

  /// Friends the task is shared with. Null leaves existing shares untouched
  /// on update; an empty list removes them all.
  final List<String>? sharedWithIds;

  @override
  List<Object?> get props => [
    title,
    description,
    priority,
    startDate,
    dueDate,
    sharedWithIds,
  ];
}
