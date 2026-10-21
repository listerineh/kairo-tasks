import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood_resolver.dart';

void main() {
  const resolver = MascotMoodResolver();

  MascotMood mood({
    int hour = 12,
    int pending = 0,
    int completed = 0,
    DateTime? last,
    bool focus = false,
  }) {
    return resolver.resolve(
      MascotSituation(
        now: DateTime(2026, 10, 20, hour, 30),
        pendingToday: pending,
        completedToday: completed,
        lastCompletionDay: last,
        focusRunning: focus,
      ),
    );
  }

  final yesterday = DateTime(2026, 10, 19, 18);
  final lastWeek = DateTime(2026, 10, 13);

  test('a focus session wins over everything, even at night', () {
    expect(mood(focus: true, hour: 2, pending: 3), MascotMood.focused);
  });

  test('sleeps at night whatever the tasks', () {
    expect(mood(hour: 0, pending: 5), MascotMood.sleeping);
    expect(mood(hour: 5, completed: 2), MascotMood.sleeping);
  });

  test('wakes up at 06:00', () {
    expect(mood(hour: 6, pending: 1), MascotMood.idle);
  });

  test('happy once everything due today is done', () {
    expect(mood(completed: 3), MascotMood.happy);
    expect(mood(completed: 1, hour: 22), MascotMood.happy);
  });

  test('idle while work remains, even if some is done', () {
    expect(mood(pending: 2), MascotMood.idle);
    expect(mood(pending: 1, completed: 4, hour: 21), MascotMood.idle);
  });

  group('streak at risk (from 20:00, nothing done)', () {
    test('sad when tasks are waiting', () {
      expect(mood(hour: 20, pending: 1), MascotMood.sad);
    });

    test('sad when yesterday kept a streak alive, even with no tasks', () {
      expect(mood(hour: 21, last: yesterday), MascotMood.sad);
    });

    test('not sad before 20:00', () {
      expect(mood(hour: 19, pending: 1), MascotMood.idle);
      expect(mood(hour: 19, last: yesterday), MascotMood.sleeping);
    });

    test('a lapsed streak with nothing planned is a rest day', () {
      expect(mood(hour: 21, last: lastWeek), MascotMood.sleeping);
      expect(mood(hour: 21), MascotMood.sleeping);
    });
  });

  test('a rest day with nothing planned sleeps', () {
    expect(mood(), MascotMood.sleeping);
    expect(mood(last: yesterday), MascotMood.sleeping);
  });

  test('streak check handles month boundaries', () {
    final m = resolver.resolve(
      MascotSituation(
        now: DateTime(2026, 11, 1, 21),
        pendingToday: 0,
        completedToday: 0,
        lastCompletionDay: DateTime(2026, 10, 31, 9),
      ),
    );
    expect(m, MascotMood.sad);
  });

  test('situations compare by value', () {
    final a = MascotSituation(
      now: DateTime(2026),
      pendingToday: 1,
      completedToday: 0,
    );
    final b = MascotSituation(
      now: DateTime(2026),
      pendingToday: 1,
      completedToday: 0,
    );
    expect(a, b);
  });
}
