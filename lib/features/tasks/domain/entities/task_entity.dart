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
    this.sharedWith,
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
  final Map<String, dynamic>? sharedWith;

  bool get isShared => sharedWith != null;

  TaskEntity copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? sharedWith,
  }) =>
      TaskEntity(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        title: title ?? this.title,
        description: description ?? this.description,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        sharedWith: sharedWith ?? this.sharedWith,
      );

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
        sharedWith,
      ];
}
