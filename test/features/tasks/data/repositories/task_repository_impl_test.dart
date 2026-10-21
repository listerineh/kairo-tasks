import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/core/errors/exceptions.dart';
import 'package:kairotasks/core/errors/failures.dart';
import 'package:kairotasks/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_draft.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockTaskRemoteDataSource remote;
  late TaskRepositoryImpl repository;
  final now = DateTime(2026, 10, 20, 9);

  Map<String, dynamic> row(String id) => {
    'id': id,
    'owner_id': 'me',
    'title': 'Task $id',
    'created_at': '2026-10-20T08:00:00.000Z',
  };

  setUp(() {
    remote = MockTaskRemoteDataSource();
    repository = TaskRepositoryImpl(
      remote,
      FakeCurrentUser(),
      clock: () => now,
    );
  });

  group('watchTasks', () {
    test('emits on listen and refetches on every remote change', () async {
      final changes = StreamController<void>();
      var fetches = 0;
      when(() => remote.fetchTasks())
          .thenAnswer((_) async => [row('t${++fetches}')]);
      when(() => remote.changes('me')).thenAnswer((_) => changes.stream);

      final emitted = <List<TaskEntity>>[];
      final sub = repository.watchTasks().listen(emitted.add);
      await pumpEventQueue();
      changes.add(null);
      await pumpEventQueue();

      expect(emitted.map((l) => l.single.id), ['t1', 't2']);
      await sub.cancel();
      unawaited(changes.close());
    });

    test('server errors surface as ServerFailure', () {
      when(() => remote.fetchTasks())
          .thenThrow(const ServerException(message: 'down'));
      // Still listens for changes, so a later change can retry.
      when(() => remote.changes('me')).thenAnswer((_) => const Stream.empty());

      expect(
        repository.watchTasks(),
        emitsError(const ServerFailure(message: 'down')),
      );
    });

    test('signed out is an AuthFailure', () {
      final signedOut = TaskRepositoryImpl(remote, FakeCurrentUser(null));
      expect(signedOut.watchTasks(), emitsError(isA<AuthFailure>()));
    });
  });

  group('createTask', () {
    test('inserts, shares with friends and returns the entity', () async {
      when(() => remote.insertTask(any())).thenAnswer((_) async => 'new');
      when(() => remote.replaceShares(any(), any(), any()))
          .thenAnswer((_) async {});

      final result = await repository.createTask(
        const TaskDraft(title: 'Plan trip', sharedWithIds: ['ana']),
      );

      final task = result.getOrElse(() => throw StateError('failed'));
      expect(task.id, 'new');
      expect(task.ownerId, 'me');
      expect(task.createdAt, now);
      verify(() => remote.replaceShares('new', 'me', ['ana'])).called(1);
    });

    test('skips shares when there are none', () async {
      when(() => remote.insertTask(any())).thenAnswer((_) async => 'new');
      await repository.createTask(const TaskDraft(title: 'Solo'));
      verifyNever(() => remote.replaceShares(any(), any(), any()));
    });
  });

  test('updateTask leaves shares alone when sharedWithIds is null', () async {
    when(() => remote.updateTask(any(), any())).thenAnswer((_) async {});

    final result = await repository.updateTask(
      't1',
      const TaskDraft(title: 'x'),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verifyNever(() => remote.replaceShares(any(), any(), any()));
  });

  test('setCompleted writes the status column', () async {
    when(() => remote.updateTask(any(), any())).thenAnswer((_) async {});

    await repository.setCompleted('t1', completed: true);
    await repository.setCompleted('t1', completed: false);

    verify(() => remote.updateTask('t1', {'status': 'completed'})).called(1);
    verify(() => remote.updateTask('t1', {'status': 'pending'})).called(1);
  });

  test('deleteTask maps ServerException to ServerFailure', () async {
    when(() => remote.deleteTask('t1'))
        .thenThrow(const ServerException(message: 'nope'));

    final result = await repository.deleteTask('t1');

    expect(result, const Left<Failure, Unit>(ServerFailure(message: 'nope')));
  });
}
