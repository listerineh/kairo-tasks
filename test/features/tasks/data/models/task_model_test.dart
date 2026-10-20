import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/tasks/data/models/task_model.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';

void main() {
  group('TaskModel', () {
    final json = <String, dynamic>{
      'id': 't1',
      'owner_id': 'u1',
      'title': 'Call the dentist',
      'description': null,
      'priority': 'urgent',
      'status': 'in_progress',
      'due_date': '2026-10-21T10:00:00.000',
      'created_at': '2026-10-20T08:00:00.000',
      'updated_at': null,
      'completed_at': null,
    };

    test('fromJson maps snake_case columns and parses enums', () {
      final entity = TaskModel.fromJson(json).toEntity();

      expect(entity.id, 't1');
      expect(entity.ownerId, 'u1');
      expect(entity.priority, TaskPriority.urgent);
      expect(entity.status, TaskStatus.inProgress);
      expect(entity.dueDate, DateTime(2026, 10, 21, 10));
    });

    test('unknown priority and status fall back to medium and pending', () {
      final entity = TaskModel.fromJson({
        ...json,
        'priority': 'whatever',
        'status': null,
      }).toEntity();

      expect(entity.priority, TaskPriority.medium);
      expect(entity.status, TaskStatus.pending);
    });

    test('fromEntity writes in_progress back as snake_case', () {
      final model = TaskModel.fromEntity(
        TaskEntity(
          id: 't1',
          ownerId: 'u1',
          title: 'x',
          createdAt: DateTime(2026),
          status: TaskStatus.inProgress,
        ),
      );

      expect(model.toUpdateJson()['status'], 'in_progress');
    });
  });
}
