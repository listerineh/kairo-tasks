import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/tasks/data/models/task_model.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_draft.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';

void main() {
  final ana = {'id': 'ana', 'display_name': 'Ana'};
  final me = {'id': 'me', 'display_name': 'Me'};

  Map<String, dynamic> row({List<Map<String, dynamic>>? shares}) => {
    'id': 't1',
    'owner_id': 'me',
    'title': 'Call the dentist',
    'description': null,
    'priority': 'urgent',
    'status': 'in_progress',
    'start_date': '2026-10-21T09:00:00.000Z',
    'due_date': '2026-10-21T10:00:00.000Z',
    'created_at': '2026-10-20T08:00:00.000Z',
    'updated_at': null,
    'completed_at': null,
    'shared_tasks': shares,
  };

  group('fromJson', () {
    test('maps columns, enums and UTC dates to local time', () {
      final task = TaskModel.fromJson(row(), 'me');

      expect(task.priority, TaskPriority.urgent);
      expect(task.status, TaskStatus.inProgress);
      expect(task.startDate, DateTime.utc(2026, 10, 21, 9).toLocal());
      expect(task.dueDate!.isUtc, isFalse);
      expect(task.sharedWith, isEmpty);
    });

    test('unknown or missing enums fall back to medium and pending', () {
      final task = TaskModel.fromJson({
        ...row(),
        'priority': 'whatever',
        'status': null,
      }, 'me');
      expect(task.priority, TaskPriority.medium);
      expect(task.status, TaskStatus.pending);
    });

    test('a task I shared lists the friend', () {
      final task = TaskModel.fromJson(
        row(
          shares: [
            {'shared_by_id': 'me', 'shared_with_id': 'ana', 'shared_with': ana},
          ],
        ),
        'me',
      );
      expect(task.sharedWith, [ana]);
    });

    test('a task shared with me lists the sharer', () {
      final task = TaskModel.fromJson(
        row(
          shares: [
            {'shared_by_id': 'ana', 'shared_with_id': 'me', 'shared_by': ana},
            // Shares between other people are not mine to show.
            {'shared_by_id': 'ana', 'shared_with_id': 'luis', 'shared_by': me},
          ],
        ),
        'me',
      );
      expect(task.sharedWith, [ana]);
    });
  });

  test('insertJson writes UTC and omits empty optionals', () {
    final json = TaskModel.insertJson(
      TaskDraft(title: 'x', dueDate: DateTime.utc(2026, 10, 21, 10)),
      'me',
    );
    expect(json, {
      'owner_id': 'me',
      'title': 'x',
      'priority': 'medium',
      'status': 'pending',
      'due_date': '2026-10-21T10:00:00.000Z',
    });
  });

  test('updateJson can clear dates', () {
    final json = TaskModel.updateJson(const TaskDraft(title: 'x'));
    expect(json['due_date'], isNull);
    expect(json.containsKey('due_date'), isTrue);
  });

  test('statusName writes in_progress as snake_case', () {
    expect(TaskModel.statusName(TaskStatus.inProgress), 'in_progress');
  });
}
