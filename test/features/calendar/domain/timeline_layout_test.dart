import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/calendar/domain/timeline_layout.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';

void main() {
  final day = DateTime(2026, 10, 20);
  DateTime at(int h, [int m = 0, int d = 20]) => DateTime(2026, 10, d, h, m);

  TaskEntity task(String id, {DateTime? start, DateTime? due}) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: id,
    startDate: start,
    dueDate: due,
    createdAt: DateTime(2026),
  );

  Map<String, (int, int, int, int)> layout(List<TaskEntity> tasks) => {
    for (final b in layoutDay(tasks, day))
      b.task.id: (b.startMinute, b.endMinute, b.column, b.columns),
  };

  test('places a timed task by minutes from midnight', () {
    expect(layout([task('a', start: at(10), due: at(11, 30))]), {
      'a': (600, 690, 0, 1),
    });
  });

  test('a single time becomes a 30 minute block', () {
    expect(layout([task('due', due: at(9)), task('start', start: at(14))]), {
      'due': (510, 540, 0, 1),
      'start': (840, 870, 0, 1),
    });
  });

  test('clips multi-day tasks to the day', () {
    expect(layout([task('night', start: at(22, 0, 19), due: at(7))]), {
      'night': (0, 420, 0, 1),
    });
  });

  test('date-only tasks go to the all-day strip, not the timeline', () {
    final t = task('allday', due: day);
    expect(layoutDay([t], day), isEmpty);
    expect(allDayTasks([t], day), [t]);
    expect(allDayTasks([t], DateTime(2026, 10, 21)), isEmpty);
  });

  test('overlapping tasks split the width; separate clusters do not', () {
    expect(
      layout([
        task('a', start: at(9), due: at(11)),
        task('b', start: at(10), due: at(12)),
        task('c', start: at(11), due: at(12)),
        task('d', start: at(13), due: at(14)),
      ]),
      {
        'a': (540, 660, 0, 2),
        'b': (600, 720, 1, 2),
        'c': (660, 720, 0, 2),
        'd': (780, 840, 0, 1),
      },
    );
  });

  test('very short tasks get at least 15 minutes', () {
    expect(layout([task('q', start: at(8), due: at(8, 5))]), {
      'q': (480, 495, 0, 1),
    });
  });

  test('snaps to 15 minutes inside the day', () {
    expect(snapMinute(607), 600);
    expect(snapMinute(608), 615);
    expect(snapMinute(-20), 0);
    expect(snapMinute(1500), minutesPerDay - 15);
  });

  group('moveTask keeps the length', () {
    test('start and due move together', () {
      final moved = moveTask(task('a', start: at(10), due: at(11)), at(15));
      expect(moved.start, at(15));
      expect(moved.due, at(16));
    });

    test('a due-only task stays due-only', () {
      final moved = moveTask(task('a', due: at(10)), at(12));
      expect(moved.start, isNull);
      expect(moved.due, at(12, 30));
    });
  });
}
