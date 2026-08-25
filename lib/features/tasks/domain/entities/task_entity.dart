import 'package:equatable/equatable.dart';

enum TaskPriority { urgent, high, medium, low }

enum TaskStatus { pending, inProgress, completed }

class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.createdAt,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.startDate,
    this.dueDate,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != TaskStatus.completed;

  bool get hasDueDate => dueDate != null;

  /// Duration of the task (startDate to dueDate).
  Duration? get duration =>
      startDate != null && dueDate != null
          ? dueDate!.difference(startDate!)
          : null;

  @override
  List<Object?> get props => [
        id,
        ownerId,
        title,
        description,
        priority,
        status,
        startDate,
        dueDate,
        createdAt,
        updatedAt,
      ];
}
