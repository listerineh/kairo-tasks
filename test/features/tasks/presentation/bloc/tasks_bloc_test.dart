import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/core/errors/failures.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_draft.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  final now = DateTime(2026, 10, 20, 15);
  const undoWindow = Duration(milliseconds: 30);

  late MockWatchTasks watch;
  late MockCreateTask create;
  late MockUpdateTask update;
  late MockSetTaskCompleted setCompleted;
  late MockDeleteTask delete;
  late MockTaskReminders reminders;
  late StreamController<List<TaskEntity>> remote;

  TaskEntity task(
    String id, {
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.pending,
    DateTime? dueDate,
  }) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: 'Task $id',
    priority: priority,
    status: status,
    dueDate: dueDate,
    createdAt: DateTime(2026, 10, int.parse(id.substring(1))),
  );

  final a = task('t1');
  final b = task(
    't2',
    priority: TaskPriority.high,
    dueDate: DateTime(2026, 11),
  );
  final loaded = TasksState(status: TasksStatus.loaded, tasks: [b, a]);

  TasksBloc build() => TasksBloc(
    watch,
    create,
    update,
    setCompleted,
    delete,
    reminders,
    FakeCurrentUser(),
    undoWindow: undoWindow,
    clock: () => now,
  );

  setUpAll(() {
    registerFallbackValue(const TaskDraft(title: 'x'));
    registerFallbackValue(a);
  });

  setUp(() {
    watch = MockWatchTasks();
    create = MockCreateTask();
    update = MockUpdateTask();
    setCompleted = MockSetTaskCompleted();
    delete = MockDeleteTask();
    reminders = MockTaskReminders();
    remote = StreamController<List<TaskEntity>>();

    when(() => watch()).thenAnswer((_) => remote.stream);
    when(
      () => reminders.tasksLoaded(
        any(),
        streak: any(named: 'streak'),
        completedToday: any(named: 'completedToday'),
      ),
    ).thenAnswer((_) async {});
    when(() => reminders.taskCreated(any(), any())).thenAnswer((_) async {});
    when(() => reminders.taskUpdated(any())).thenAnswer((_) async {});
    when(() => reminders.taskCompleted(any())).thenAnswer((_) async {});
    when(() => reminders.taskDeleted(any())).thenAnswer((_) async {});
    when(() => reminders.streakExtended(any())).thenAnswer((_) async {});
    // Closing the bloc commits any pending deletion.
    when(() => delete(any())).thenAnswer((_) async => const Right(unit));
  });

  // close() only completes once a listener sees "done"; most tests never
  // listen, so do not await it.
  tearDown(() => unawaited(remote.close()));

  group('load', () {
    blocTest<TasksBloc, TasksState>(
      'shows loading, then every snapshot from the stream',
      build: build,
      act: (bloc) async {
        bloc.add(const TasksLoadRequested());
        await pumpEventQueue();
        remote.add([a]);
        await pumpEventQueue();
        remote.add([b, a]);
      },
      expect: () => [
        const TasksState(status: TasksStatus.loading),
        TasksState(status: TasksStatus.loaded, tasks: [a]),
        TasksState(status: TasksStatus.loaded, tasks: [b, a]),
      ],
      verify: (_) => verify(
        () => reminders.tasksLoaded([a], streak: 0, completedToday: false),
      ).called(1),
    );

    blocTest<TasksBloc, TasksState>(
      'a failure shows its message',
      build: build,
      act: (bloc) async {
        bloc.add(const TasksLoadRequested());
        await pumpEventQueue();
        remote.addError(const ServerFailure(message: 'offline'));
      },
      expect: () => [
        const TasksState(status: TasksStatus.loading),
        const TasksState(status: TasksStatus.error, errorMessage: 'offline'),
      ],
    );
  });

  group('create', () {
    blocTest<TasksBloc, TasksState>(
      'sends a draft and schedules its reminders',
      build: build,
      setUp: () => when(() => create(any())).thenAnswer((_) async => Right(a)),
      seed: () => loaded,
      act: (bloc) => bloc.add(
        const TaskCreateRequested(
          title: 'Task t1',
          priority: TaskPriority.urgent,
          sharedWith: ['ana'],
        ),
      ),
      expect: () => <TasksState>[],
      verify: (_) {
        verify(
          () => create(
            const TaskDraft(
              title: 'Task t1',
              priority: TaskPriority.urgent,
              sharedWithIds: ['ana'],
            ),
          ),
        ).called(1);
        verify(() => reminders.taskCreated(a, [b, a, a])).called(1);
      },
    );

    blocTest<TasksBloc, TasksState>(
      'shows the failure',
      build: build,
      setUp: () => when(() => create(any())).thenAnswer(
        (_) async => const Left(ValidationFailure(message: 'needs a title')),
      ),
      seed: () => loaded,
      act: (bloc) => bloc.add(const TaskCreateRequested(title: ' ')),
      expect: () => [loaded.copyWith(errorMessage: 'needs a title')],
    );
  });

  group('edit', () {
    blocTest<TasksBloc, TasksState>(
      'saves the whole draft, so a date can be removed, and reschedules',
      build: build,
      setUp: () =>
          when(() => update(any(), any()))
              .thenAnswer((_) async => const Right(unit)),
      seed: () => loaded,
      act: (bloc) => bloc.add(
        const TaskEdited(
          't2',
          TaskDraft(title: 'Renamed', priority: TaskPriority.low),
        ),
      ),
      // Shown right away; the stream confirms it later.
      expect: () => [
        loaded.copyWith(
          tasks: [
            TaskEntity(
              id: 't2',
              ownerId: 'me',
              title: 'Renamed',
              priority: TaskPriority.low,
              createdAt: b.createdAt,
            ),
            a,
          ],
        ),
      ],
      verify: (_) {
        verify(
          () => update(
            't2',
            const TaskDraft(title: 'Renamed', priority: TaskPriority.low),
          ),
        ).called(1);
        final rescheduled =
            verify(() => reminders.taskUpdated(captureAny())).captured.single
                as TaskEntity;
        expect(rescheduled.title, 'Renamed');
        expect(rescheduled.dueDate, isNull);
      },
    );

    blocTest<TasksBloc, TasksState>(
      'shows the failure and leaves reminders alone',
      build: build,
      setUp: () => when(
        () => update(any(), any()),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'offline'))),
      seed: () => loaded,
      act: (bloc) =>
          bloc.add(const TaskEdited('t2', TaskDraft(title: 'Renamed'))),
      expect: () => [
        loaded.copyWith(
          tasks: [
            TaskEntity(
              id: 't2',
              ownerId: 'me',
              title: 'Renamed',
              createdAt: b.createdAt,
            ),
            a,
          ],
        ),
        // Rolled back, then the failure.
        loaded,
        loaded.copyWith(errorMessage: 'offline'),
      ],
      verify: (_) => verifyNever(() => reminders.taskUpdated(any())),
    );
  });

  group('toggle', () {
    blocTest<TasksBloc, TasksState>(
      'completes right away and celebrates the first completion today',
      build: build,
      setUp: () =>
          when(() => setCompleted(any(), completed: any(named: 'completed')))
              .thenAnswer((_) async => const Right(unit)),
      seed: () => loaded,
      act: (bloc) => bloc.add(const TaskStatusToggled('t1')),
      expect: () {
        final done = a.copyWith(status: TaskStatus.completed, completedAt: now);
        final completed = loaded.copyWith(tasks: [b, done]);
        return [completed, completed.copyWith(streakToCelebrate: 1)];
      },
      verify: (_) {
        verify(() => setCompleted('t1', completed: true)).called(1);
        verify(() => reminders.taskCompleted('t1')).called(1);
        verify(() => reminders.streakExtended(1)).called(1);
      },
    );

    blocTest<TasksBloc, TasksState>(
      'rolls back when the server refuses',
      build: build,
      setUp: () => when(
        () => setCompleted(any(), completed: any(named: 'completed')),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'offline'))),
      seed: () => loaded,
      act: (bloc) => bloc.add(const TaskStatusToggled('t1')),
      skip: 1,
      expect: () => [loaded, loaded.copyWith(errorMessage: 'offline')],
      verify: (_) => verifyNever(() => reminders.streakExtended(any())),
    );

    blocTest<TasksBloc, TasksState>(
      'reopening clears a pending celebration',
      build: build,
      setUp: () =>
          when(() => setCompleted(any(), completed: any(named: 'completed')))
              .thenAnswer((_) async => const Right(unit)),
      seed: () => TasksState(
        status: TasksStatus.loaded,
        tasks: [task('t3', status: TaskStatus.completed)],
        streakToCelebrate: 4,
      ),
      act: (bloc) => bloc.add(const TaskStatusToggled('t3')),
      verify: (bloc) {
        expect(bloc.state.streakToCelebrate, isNull);
        expect(bloc.state.tasks.single.status, TaskStatus.pending);
        verify(() => setCompleted('t3', completed: false)).called(1);
      },
    );
  });

  group('delete with undo', () {
    blocTest<TasksBloc, TasksState>(
      'hides the task at once and deletes it after the undo window',
      build: build,
      setUp: () =>
          when(() => delete(any())).thenAnswer((_) async => const Right(unit)),
      seed: () => loaded,
      act: (bloc) => bloc.add(const TaskDeleted('t1')),
      wait: undoWindow * 3,
      expect: () => [
        loaded.copyWith(tasks: [b], pendingDeletion: a),
        loaded.copyWith(tasks: [b], pendingDeletion: null),
      ],
      verify: (_) {
        verify(() => delete('t1')).called(1);
        verify(() => reminders.taskDeleted('t1')).called(1);
      },
    );

    blocTest<TasksBloc, TasksState>(
      'undo brings it back and nothing is deleted',
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc
        ..add(const TaskDeleted('t1'))
        ..add(const TaskDeleteUndone()),
      wait: undoWindow * 3,
      expect: () => [
        loaded.copyWith(tasks: [b], pendingDeletion: a),
        loaded,
      ],
      verify: (_) => verifyNever(() => delete(any())),
    );

    blocTest<TasksBloc, TasksState>(
      'a failed delete puts the task back with the error',
      build: build,
      setUp: () => when(
        () => delete(any()),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'offline'))),
      seed: () => loaded,
      act: (bloc) => bloc.add(const TaskDeleted('t1')),
      wait: undoWindow * 3,
      verify: (bloc) {
        expect(bloc.state.tasks, [b, a]);
        expect(bloc.state.errorMessage, 'offline');
      },
    );

    blocTest<TasksBloc, TasksState>(
      'snapshots arriving during the undo window keep it hidden',
      build: build,
      seed: () => loaded,
      act: (bloc) async {
        bloc
          ..add(const TaskDeleted('t1'))
          ..add(const TasksLoadRequested());
        await pumpEventQueue();
        remote.add([b, a]);
        await pumpEventQueue();
      },
      verify: (bloc) => expect(bloc.state.tasks, [b]),
    );
  });

  test('activeTasks filters by priority and sorts urgent first', () {
    final state = TasksState(
      tasks: [
        task('t1', priority: TaskPriority.low),
        task('t2', priority: TaskPriority.urgent),
        task('t3', priority: TaskPriority.urgent, status: TaskStatus.completed),
      ],
    );
    expect(state.activeTasks.map((t) => t.id), ['t2', 't1']);
    expect(
      state.copyWith(filter: TasksFilter.urgent).activeTasks.map((t) => t.id),
      ['t2'],
    );
  });
}
