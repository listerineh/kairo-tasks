import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/domain/task_sections.dart';

void main() {
  final now = DateTime(2026, 10, 20, 15);

  TaskEntity task(
    String id, {
    DateTime? due,
    DateTime? start,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.pending,
    DateTime? completedAt,
    DateTime? createdAt,
  }) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: id,
    dueDate: due,
    startDate: start,
    priority: priority,
    status: status,
    completedAt: completedAt,
    createdAt: createdAt ?? DateTime(2026),
  );

  Map<TaskSectionKind, List<String>> ids(List<TaskSection> sections) => {
    for (final s in sections) s.kind: [for (final t in s.tasks) t.id],
  };

  test('puts each task in its section, in display order', () {
    final sections = groupTasks([
      task('upcoming', due: DateTime(2026, 10, 22)),
      task('done', status: TaskStatus.completed),
      task('overdue', due: DateTime(2026, 10, 18)),
      task('nodate'),
      task('today', due: DateTime(2026, 10, 20, 18)),
    ], now);

    expect(sections.map((s) => s.kind), TaskSectionKind.values);
    expect(ids(sections)[TaskSectionKind.today], ['today']);
  });

  test('a task due earlier today stays in Today', () {
    final sections = groupTasks([
      task('t', due: DateTime(2026, 10, 20, 9)),
    ], now);
    expect(sections.single.kind, TaskSectionKind.today);
  });

  test(
    'midnight tomorrow is upcoming, the last second of yesterday overdue',
    () {
      final sections = groupTasks([
        task('tomorrow', due: DateTime(2026, 10, 21)),
        task('yesterday', due: DateTime(2026, 10, 19, 23, 59, 59)),
      ], now);
      expect(ids(sections), {
        TaskSectionKind.overdue: ['yesterday'],
        TaskSectionKind.upcoming: ['tomorrow'],
      });
    },
  );

  test('falls back to the start date when there is no due date', () {
    final sections = groupTasks([
      task('s', start: DateTime(2026, 10, 25)),
    ], now);
    expect(sections.single.kind, TaskSectionKind.upcoming);
  });

  test('omits empty sections', () {
    expect(groupTasks(const [], now), isEmpty);
    expect(groupTasks([task('n')], now).single.kind, TaskSectionKind.noDate);
  });

  test('dated sections sort by date, then priority', () {
    final sections = groupTasks([
      task(
        'late-low',
        due: DateTime(2026, 10, 20, 17),
        priority: TaskPriority.low,
      ),
      task(
        'late-urgent',
        due: DateTime(2026, 10, 20, 17),
        priority: TaskPriority.urgent,
      ),
      task('early', due: DateTime(2026, 10, 20, 8)),
    ], now);
    expect(ids(sections)[TaskSectionKind.today], [
      'early',
      'late-urgent',
      'late-low',
    ]);
  });

  test('no-date sorts by priority, then newest first', () {
    final sections = groupTasks([
      task(
        'old-high',
        priority: TaskPriority.high,
        createdAt: DateTime(2026, 1),
      ),
      task('low', priority: TaskPriority.low),
      task(
        'new-high',
        priority: TaskPriority.high,
        createdAt: DateTime(2026, 9),
      ),
    ], now);
    expect(ids(sections)[TaskSectionKind.noDate], [
      'new-high',
      'old-high',
      'low',
    ]);
  });

  test('completed runs most recent first, whatever their due date', () {
    final sections = groupTasks([
      task(
        'a',
        status: TaskStatus.completed,
        completedAt: DateTime(2026, 10, 1),
        due: DateTime(2020),
      ),
      task(
        'b',
        status: TaskStatus.completed,
        completedAt: DateTime(2026, 10, 19),
      ),
    ], now);
    expect(ids(sections), {
      TaskSectionKind.completed: ['b', 'a'],
    });
  });
}
