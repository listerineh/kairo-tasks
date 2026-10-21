import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/domain/streak.dart';

void main() {
  final today = DateTime(2026, 10, 20, 15);
  DateTime day(int d) => DateTime(2026, 10, d, 9);

  TaskEntity done(DateTime when, {String owner = 'me'}) => TaskEntity(
    id: '$when$owner',
    ownerId: owner,
    title: 't',
    createdAt: DateTime(2026),
    status: TaskStatus.completed,
    completedAt: when,
  );

  group('fromDays', () {
    test('counts consecutive days ending today', () {
      expect(Streak.fromDays([day(20), day(19), day(18)], today), 3);
    });

    test('a streak ending yesterday is still alive', () {
      expect(Streak.fromDays([day(19), day(18)], today), 2);
    });

    test('a gap breaks it', () {
      expect(Streak.fromDays([day(20), day(18)], today), 1);
      expect(Streak.fromDays([day(17)], today), 0);
    });

    test('several completions on one day count once', () {
      expect(Streak.fromDays([day(20), DateTime(2026, 10, 20, 22)], today), 1);
    });

    test('crosses month boundaries', () {
      expect(
        Streak.fromDays([
          DateTime(2026, 11, 1),
          DateTime(2026, 10, 31),
        ], DateTime(2026, 11, 1, 12)),
        2,
      );
    });

    test('no days, no streak', () {
      expect(Streak.fromDays(const [], today), 0);
    });
  });

  test('only my own completed tasks count', () {
    final tasks = [
      done(day(20)),
      done(day(19), owner: 'ana'),
      TaskEntity(id: 'p', ownerId: 'me', title: 'p', createdAt: day(19)),
    ];
    expect(Streak.forTasks(tasks, 'me', today), 1);
    expect(Streak.completedToday(tasks, 'me', today), isTrue);
    expect(Streak.completedToday(tasks, 'ana', today), isFalse);
  });

  test('future completion dates are ignored', () {
    expect(Streak.forTasks([done(day(25))], 'me', today), 0);
  });
}
