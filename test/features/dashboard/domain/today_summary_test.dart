import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood.dart';
import 'package:kairotasks/features/dashboard/domain/today_summary.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';

void main() {
  final now = DateTime(2026, 10, 21, 10, 40);
  DateTime at(int h, [int m = 0, int d = 21]) => DateTime(2026, 10, d, h, m);

  TaskEntity task(
    String id, {
    DateTime? due,
    DateTime? start,
    bool done = false,
    DateTime? completedAt,
    String owner = 'me',
  }) => TaskEntity(
    id: id,
    ownerId: owner,
    title: id,
    dueDate: due,
    startDate: start,
    status: done ? TaskStatus.completed : TaskStatus.pending,
    completedAt: completedAt,
    createdAt: DateTime(2026),
  );

  TodaySummary summary(List<TaskEntity> tasks) =>
      TodaySummary.from(tasks, now: now, userId: 'me');

  test('pending is overdue first, then today; later days stay out', () {
    final s = summary([
      task('today', due: at(16)),
      task('late', due: at(9, 0, 19)),
      task('tomorrow', due: at(9, 0, 22)),
      task('someday'),
    ]);
    expect(s.pending.map((t) => t.id), ['late', 'today']);
    expect(s.overdue, 1);
  });

  test('done counts only what was completed today', () {
    final s = summary([
      task('a', due: at(8), done: true, completedAt: at(8, 30)),
      task('b', due: at(9, 0, 20), done: true, completedAt: at(18, 0, 20)),
      task('c', due: at(16)),
    ]);
    expect(s.done.map((t) => t.id), ['a']);
    expect(s.total, 2);
    expect(s.progress, 0.5);
  });

  test('next is the earliest timed task still ahead', () {
    final s = summary([
      task('dentist', due: at(10, 15)),
      task('report', start: at(11), due: at(13)),
      task('walk', due: at(8)),
      task('untimed', due: at(0)),
    ]);
    // 10:15 is within the 30 minute grace window at 10:40; 8:00 is not.
    expect(s.next?.id, 'dentist');
    expect(s.nextAt, at(10, 15));
  });

  test('with no timed tasks there is no next, but a first step', () {
    final s = summary([task('untimed', due: at(0))]);
    expect(s.next, isNull);
    expect(s.firstStep?.id, 'untimed');
  });

  test('streak counts days in a row with completions', () {
    final s = summary([
      task('a', done: true, completedAt: at(9)),
      task('b', done: true, completedAt: at(9, 0, 20)),
      task('c', done: true, completedAt: at(9, 0, 19)),
      task('theirs', done: true, completedAt: at(9, 0, 18), owner: 'ana'),
    ]);
    expect(s.streak, 3);
    expect(s.lastCompletionDay, DateTime(2026, 10, 21));
  });

  group('tips', () {
    test('a busy day rotates start, progress and focus', () {
      final s = summary([
        task('a', due: at(9), done: true, completedAt: at(9)),
        task('b', due: at(16)),
      ]);
      expect(s.tips, [
        KairoTipKind.startWith,
        KairoTipKind.progress,
        KairoTipKind.focus,
      ]);
    });

    test('progress waits for the first completion', () {
      expect(summary([task('b', due: at(16))]).tips, [
        KairoTipKind.startWith,
        KairoTipKind.focus,
      ]);
    });

    test('all done and rest days have one message', () {
      expect(
        summary([task('a', due: at(9), done: true, completedAt: at(9))]).tips,
        [KairoTipKind.allDone],
      );
      expect(summary([]).tips, [KairoTipKind.rest]);
    });
  });

  test('mood follows the resolver', () {
    final s = summary([task('a', due: at(9), done: true, completedAt: at(9))]);
    expect(s.mood(), MascotMood.happy);
    expect(s.mood(focusRunning: true), MascotMood.focused);
  });
}
