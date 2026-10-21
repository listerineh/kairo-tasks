import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/social/domain/shared_tasks.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';

void main() {
  const ana = {'id': 'ana', 'username': 'ana', 'display_name': 'Ana'};
  const leo = {'id': 'leo', 'username': 'leo', 'display_name': 'Leo'};

  TaskEntity task(
    String id, {
    DateTime? due,
    List<Map<String, dynamic>> sharedWith = const [ana],
    TaskStatus status = TaskStatus.pending,
  }) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: id,
    dueDate: due,
    status: status,
    sharedWith: sharedWith,
    createdAt: DateTime(2026),
  );

  test('keeps unfinished shared tasks, soonest first, undated last', () {
    final tasks = [
      task('undated'),
      task('later', due: DateTime(2026, 10, 25)),
      task('mine only', due: DateTime(2026, 10, 21), sharedWith: const []),
      task('done', due: DateTime(2026, 10, 21), status: TaskStatus.completed),
      task('soon', due: DateTime(2026, 10, 22)),
    ];
    expect(sharedTasks(tasks).map((t) => t.id), ['soon', 'later', 'undated']);
  });

  test('progress follows the status', () {
    expect(sharedProgress(task('a')), 0);
    expect(sharedProgress(task('b', status: TaskStatus.inProgress)), 0.5);
    expect(sharedProgress(task('c', status: TaskStatus.completed)), 1);
  });

  test('nudges go to everyone else on the task', () {
    expect(nudgeTargets(task('a', sharedWith: const [ana, leo])), [
      'ana',
      'leo',
    ]);
  });
}
