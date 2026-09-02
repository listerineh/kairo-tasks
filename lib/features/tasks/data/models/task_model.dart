import '../../domain/entities/task_entity.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.createdAt,
    this.description,
    this.priority = 'medium',
    this.status = 'pending',
    this.dueDate,
    this.updatedAt,
    this.completedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      ownerId: entity.ownerId,
      title: entity.title,
      description: entity.description,
      priority: entity.priority.name,
      status: _statusToString(entity.status),
      dueDate: entity.dueDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      completedAt: entity.completedAt,
    );
  }

  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      ownerId: ownerId,
      title: title,
      description: description,
      priority: _parsePriority(priority),
      status: _parseStatus(status),
      dueDate: dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'owner_id': userId,
      'title': title,
      if (description != null) 'description': description,
      'priority': priority,
      'status': status,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
    };
  }

  static TaskPriority _parsePriority(String value) {
    switch (value) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  static TaskStatus _parseStatus(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }

  static String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }
}
