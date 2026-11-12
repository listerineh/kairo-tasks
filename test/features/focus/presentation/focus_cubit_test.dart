import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/focus/domain/focus_session.dart';
import 'package:kairotasks/features/focus/presentation/cubit/focus_cubit.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:mocktail/mocktail.dart';

class _MockAlarm extends Mock implements FocusAlarm {}

void main() {
  late _MockAlarm alarm;
  late DateTime now;
  final task = TaskEntity(
    id: 't1',
    ownerId: 'me',
    title: 'Write report',
    createdAt: DateTime(2026),
  );

  setUpAll(() => registerFallbackValue(Duration.zero));

  setUp(() {
    alarm = _MockAlarm();
    when(() => alarm.cancel()).thenAnswer((_) async {});
    when(
      () => alarm.schedule(
        after: any(named: 'after'),
        taskTitle: any(named: 'taskTitle'),
      ),
    ).thenAnswer((_) async {});
    now = DateTime(2026, 10, 21, 10);
  });

  FocusCubit build() => FocusCubit(alarm, clock: () => now);

  test('choosing a task starts the round and schedules its end', () {
    fakeAsync((async) {
      final cubit = build()..choose(task);
      expect(cubit.state.chosen, isTrue);
      expect(cubit.state.task, task);
      expect(cubit.state.running, isTrue);
      verify(
        () => alarm.schedule(
          after: FocusSession.focusLength,
          taskTitle: 'Write report',
        ),
      ).called(1);
      cubit.close();
    });
  });

  test('ticks follow the clock and finish the round', () {
    fakeAsync((async) {
      final cubit = build()..choose(null);
      now = now.add(const Duration(minutes: 10));
      async.elapse(const Duration(seconds: 1));
      expect(cubit.state.remaining, const Duration(minutes: 15));

      now = now.add(const Duration(minutes: 15));
      async.elapse(const Duration(seconds: 1));
      expect(cubit.state.finished, isTrue);
      expect(cubit.state.running, isFalse);
      cubit.close();
    });
  });

  test('pausing cancels the alarm; resuming schedules what is left', () {
    fakeAsync((async) {
      final cubit = build()..choose(task);
      now = now.add(const Duration(minutes: 5));
      cubit.toggle();
      expect(cubit.state.running, isFalse);
      verify(() => alarm.cancel()).called(greaterThan(0));

      now = now.add(const Duration(minutes: 30));
      cubit.toggle();
      verify(
        () => alarm.schedule(
          after: const Duration(minutes: 20),
          taskTitle: 'Write report',
        ),
      ).called(1);
      cubit.close();
    });
  });

  test('after a round, next starts the rest without a task title', () {
    fakeAsync((async) {
      final cubit = build()..choose(task);
      now = now.add(FocusSession.focusLength);
      async.elapse(const Duration(seconds: 1));
      cubit.next();
      expect(cubit.state.session.phase, FocusPhase.rest);
      expect(cubit.state.running, isTrue);
      verify(() => alarm.schedule(after: FocusSession.shortRest)).called(1);
      cubit.close();
    });
  });

  test('changing the task drops the session', () {
    fakeAsync((async) {
      final cubit = build()
        ..choose(task)
        ..changeTask();
      expect(cubit.state.chosen, isFalse);
      expect(cubit.state.running, isFalse);
      cubit.close();
    });
  });
}
