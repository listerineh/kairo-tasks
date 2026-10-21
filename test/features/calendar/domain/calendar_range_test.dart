import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/calendar/domain/calendar_range.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';

void main() {
  TaskEntity task(String id, {DateTime? start, DateTime? due}) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: id,
    startDate: start,
    dueDate: due,
    createdAt: DateTime(2026, 1, 1),
  );

  test('weeks start on Sunday', () {
    // 2026-10-20 is a Tuesday.
    expect(startOfWeek(DateTime(2026, 10, 20, 15)), DateTime(2026, 10, 18));
    expect(startOfWeek(DateTime(2026, 10, 18)), DateTime(2026, 10, 18));
    expect(startOfWeek(DateTime(2026, 11, 1)), DateTime(2026, 11, 1));
  });

  test('steps a day, a week or to the neighbouring month', () {
    final d = DateTime(2026, 10, 31);
    expect(
      stepDate(d, CalendarViewType.day, forward: true),
      DateTime(2026, 11),
    );
    expect(
      stepDate(d, CalendarViewType.week, forward: false),
      DateTime(2026, 10, 24),
    );
    expect(
      stepDate(d, CalendarViewType.month, forward: true),
      DateTime(2026, 11),
    );
    expect(
      stepDate(DateTime(2026, 1, 15), CalendarViewType.month, forward: false),
      DateTime(2025, 12),
    );
  });

  group('tasksOnDay', () {
    final day = DateTime(2026, 10, 20, 12);

    test('includes date-only tasks due that day', () {
      final t = task('dateOnly', due: DateTime(2026, 10, 20));
      expect(tasksOnDay([t], day), [t]);
    });

    test('includes spans crossing the day and excludes others', () {
      final span = task(
        'span',
        start: DateTime(2026, 10, 19, 22),
        due: DateTime(2026, 10, 21, 8),
      );
      final before = task('before', due: DateTime(2026, 10, 19, 23));
      final after = task('after', start: DateTime(2026, 10, 21));
      expect(tasksOnDay([span, before, after], day), [span]);
    });

    test('a task ending exactly at midnight belongs to its own day', () {
      final t = task(
        'endsMidnight',
        start: DateTime(2026, 10, 19, 23),
        due: DateTime(2026, 10, 20),
      );
      expect(tasksOnDay([t], DateTime(2026, 10, 19)), [t]);
    });
  });

  test('merging keeps my copy of a task shared with me', () {
    final mine = task('t1').copyWith(color: '#mine');
    final theirs = task('t1').copyWith(color: '#theirs');
    final other = task('t2');
    expect(mergeTasks([mine], [theirs, other]), [mine, other]);
  });
}
