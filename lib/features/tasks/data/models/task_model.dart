import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_entity.dart';

/// Maps `tasks` rows (with their `shared_tasks` join) to entities, and
/// drafts to insert/update payloads.
class TaskModel {
  const TaskModel._();

  /// [currentUserId] decides which side of each share is "the other
  /// person": for tasks I shared, the friend; for tasks shared with me, the
  /// sharer.
  static TaskEntity fromJson(Map<String, dynamic> json, String currentUserId) {
    return TaskEntity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: parsePriority(json['priority'] as String?),
      status: parseStatus(json['status'] as String?),
      startDate: _date(json['start_date']),
      dueDate: _date(json['due_date']),
      createdAt: _date(json['created_at'])!,
      updatedAt: _date(json['updated_at']),
      completedAt: _date(json['completed_at']),
      sharedWith: _sharedWith(json['shared_tasks'], currentUserId),
    );
  }

  static Map<String, dynamic> insertJson(TaskDraft draft, String ownerId) => {
    'owner_id': ownerId,
    'title': draft.title,
    if (draft.description != null) 'description': draft.description,
    'priority': draft.priority.name,
    'status': 'pending',
    if (draft.startDate != null) 'start_date': _iso(draft.startDate!),
    if (draft.dueDate != null) 'due_date': _iso(draft.dueDate!),
  };

  static Map<String, dynamic> updateJson(TaskDraft draft) => {
    'title': draft.title,
    'description': draft.description,
    'priority': draft.priority.name,
    'start_date': draft.startDate == null ? null : _iso(draft.startDate!),
    'due_date': draft.dueDate == null ? null : _iso(draft.dueDate!),
  };

  static String statusName(TaskStatus status) => switch (status) {
    TaskStatus.pending => 'pending',
    TaskStatus.inProgress => 'in_progress',
    TaskStatus.completed => 'completed',
  };

  static TaskPriority parsePriority(String? value) => switch (value) {
    'urgent' => TaskPriority.urgent,
    'high' => TaskPriority.high,
    'low' => TaskPriority.low,
    _ => TaskPriority.medium,
  };

  static TaskStatus parseStatus(String? value) => switch (value) {
    'in_progress' => TaskStatus.inProgress,
    'completed' => TaskStatus.completed,
    _ => TaskStatus.pending,
  };

  static String _iso(DateTime d) => d.toUtc().toIso8601String();

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();

  static List<Map<String, dynamic>> _sharedWith(Object? shares, String me) {
    if (shares is! List) return const [];
    return [
      for (final share in shares.cast<Map<String, dynamic>>())
        if (share['shared_by_id'] == me && share['shared_with'] != null)
          share['shared_with'] as Map<String, dynamic>
        else if (share['shared_with_id'] == me && share['shared_by'] != null)
          share['shared_by'] as Map<String, dynamic>,
    ];
  }
}
