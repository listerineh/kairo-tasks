import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/core/errors/exceptions.dart';
import 'package:kairotasks/core/errors/failures.dart';
import 'package:kairotasks/core/network/network_info.dart';
import 'package:kairotasks/features/tasks/data/datasources/task_local_store.dart';
import 'package:kairotasks/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:kairotasks/features/tasks/data/sync/pending_op.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_draft.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_sync_status.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

class MemoryStore implements TaskLocalStore {
  final rows = <String, List<Map<String, dynamic>>>{};
  final outbox = <String, List<PendingOp>>{};

  @override
  Future<List<Map<String, dynamic>>?> readRows(String userId) async =>
      rows[userId];

  @override
  Future<void> writeRows(String userId, List<Map<String, dynamic>> r) async =>
      rows[userId] = r;

  @override
  Future<List<PendingOp>> readOutbox(String userId) async =>
      outbox[userId] ?? const [];

  @override
  Future<void> writeOutbox(String userId, List<PendingOp> ops) async =>
      outbox[userId] = ops;

  @override
  Future<void> clear(String userId) async {
    rows.remove(userId);
    outbox.remove(userId);
  }
}

class FakeNetwork implements NetworkInfo {
  final changes = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectionChanged => changes.stream;
}

void main() {
  late MockTaskRemoteDataSource remote;
  late MemoryStore store;
  late FakeNetwork network;
  late TaskRepositoryImpl repository;
  final now = DateTime.utc(2026, 10, 22, 9);

  Map<String, dynamic> row(String id, {String? updatedAt}) => {
    'id': id,
    'owner_id': 'me',
    'title': 'Task $id',
    'created_at': '2026-10-20T08:00:00.000Z',
    'updated_at': ?updatedAt,
  };

  const offline = NetworkException(message: 'offline');

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    remote = MockTaskRemoteDataSource();
    store = MemoryStore();
    network = FakeNetwork();
    var ids = 0;
    repository = TaskRepositoryImpl(
      remote,
      store,
      network,
      FakeCurrentUser(),
      clock: () => now,
      newId: () => 'local-${++ids}',
    );
    when(() => remote.changes('me')).thenAnswer((_) => const Stream.empty());
    when(() => remote.fetchTasks()).thenAnswer((_) async => [row('s1')]);
    when(() => remote.insertTask(any())).thenAnswer((_) async => 'ok');
    when(() => remote.updateTask(any(), any())).thenAnswer((_) async {});
    when(() => remote.deleteTask(any())).thenAnswer((_) async {});
    when(() => remote.replaceShares(any(), any(), any()))
        .thenAnswer((_) async {});
  });

  tearDown(() => unawaited(network.changes.close()));

  Future<List<List<String>>> watchIds() async {
    final emitted = <List<String>>[];
    final sub = repository.watchTasks().listen(
      (tasks) => emitted.add([for (final t in tasks) t.id]),
    );
    await pumpEventQueue();
    await sub.cancel();
    return emitted;
  }

  group('watchTasks', () {
    test(
      'shows the stored copy first, then the server (and stores it)',
      () async {
        store.rows['me'] = [row('cached')];
        expect(await watchIds(), [
          ['cached'],
          ['s1'],
        ]);
        expect(store.rows['me']!.single['id'], 's1');
      },
    );

    test('refetches on every remote change', () async {
      final changes = StreamController<void>();
      var fetches = 0;
      when(() => remote.fetchTasks())
          .thenAnswer((_) async => [row('t${++fetches}')]);
      when(() => remote.changes('me')).thenAnswer((_) => changes.stream);

      final emitted = <String>[];
      final sub = repository.watchTasks().listen(
        (l) => emitted.add(l.single.id),
      );
      await pumpEventQueue();
      changes.add(null);
      await pumpEventQueue();

      expect(emitted, ['t1', 't2']);
      await sub.cancel();
      unawaited(changes.close());
    });

    test('with nothing stored, server errors surface as ServerFailure', () {
      when(() => remote.fetchTasks())
          .thenThrow(const ServerException(message: 'down'));
      expect(
        repository.watchTasks(),
        emitsError(const ServerFailure(message: 'down')),
      );
    });

    test('offline with a stored copy keeps showing it, no error', () async {
      store.rows['me'] = [row('cached')];
      when(() => remote.fetchTasks()).thenThrow(offline);
      final errors = <Object>[];
      final emitted = <List<TaskEntity>>[];
      final sub = repository.watchTasks().listen(
        emitted.add,
        onError: errors.add,
      );
      await pumpEventQueue();
      expect(emitted.single.single.id, 'cached');
      expect(errors, isEmpty);
      await sub.cancel();
    });

    test('offline with nothing stored is a NetworkFailure', () {
      when(() => remote.fetchTasks()).thenThrow(offline);
      expect(repository.watchTasks(), emitsError(isA<NetworkFailure>()));
    });

    test('signed out is an AuthFailure', () {
      final signedOut = TaskRepositoryImpl(
        remote,
        store,
        network,
        FakeCurrentUser(null),
      );
      expect(signedOut.watchTasks(), emitsError(isA<AuthFailure>()));
    });
  });

  group('offline writes', () {
    test(
      'a task created offline shows at once and syncs when back online',
      () async {
        when(() => remote.fetchTasks()).thenThrow(offline);
        when(() => remote.insertTask(any())).thenThrow(offline);

        final result = await repository.createTask(
          const TaskDraft(title: 'Plan trip', sharedWithIds: ['ana']),
        );
        await pumpEventQueue();
        final task = result.getOrElse(() => throw StateError('failed'));
        expect(task.id, 'local-1');
        expect(task.createdAt, now);
        expect(store.outbox['me']!.single.kind, PendingKind.create);
        expect((await watchIds()).last, ['local-1']);

        // Back online.
        when(() => remote.insertTask(any())).thenAnswer((_) async => 'local-1');
        when(() => remote.fetchTasks()).thenAnswer((_) async => [row('s1')]);
        network.changes.add(true);
        await pumpEventQueue();

        final inserted =
            verify(() => remote.insertTask(captureAny())).captured.last
                as Map<String, dynamic>;
        expect(inserted['id'], 'local-1');
        expect(inserted['title'], 'Plan trip');
        expect(inserted.containsKey('shared_tasks'), isFalse);
        verify(() => remote.replaceShares('local-1', 'me', ['ana'])).called(1);
        expect(store.outbox['me'], isEmpty);
      },
    );

    test('create then delete offline sends nothing', () async {
      when(() => remote.insertTask(any())).thenThrow(offline);
      when(() => remote.fetchTasks()).thenThrow(offline);
      await repository.createTask(const TaskDraft(title: 'Oops'));
      await pumpEventQueue();
      await repository.deleteTask('local-1');
      await pumpEventQueue();
      expect(store.outbox['me'], isEmpty);
      verifyNever(() => remote.deleteTask(any()));
    });

    test('sync status counts waiting changes and goes offline', () async {
      when(() => remote.deleteTask(any())).thenThrow(offline);
      final statuses = <TaskSyncStatus>[];
      final sub = repository.watchSyncStatus().listen(statuses.add);
      await repository.deleteTask('s1');
      await pumpEventQueue();
      expect(statuses.last, const TaskSyncStatus(online: false, pending: 1));
      await sub.cancel();
    });
  });

  group('sending', () {
    test('completing sends only the status column', () async {
      when(() => remote.fetchTasks()).thenAnswer((_) async => [row('t1')]);
      await repository.setCompleted('t1', completed: true);
      await pumpEventQueue();
      verify(() => remote.updateTask('t1', {'status': 'completed'})).called(1);
    });

    test('an edit older than the server row loses (last-write-wins)', () async {
      when(() => remote.fetchTasks()).thenAnswer(
        (_) async => [row('t1', updatedAt: '2026-10-22T10:00:00.000Z')],
      );
      await repository.updateTask('t1', const TaskDraft(title: 'Mine'));
      await pumpEventQueue();
      verifyNever(() => remote.updateTask(any(), any()));
      expect(store.outbox['me'], isEmpty);
    });

    test('a newer edit wins and leaves shares alone when null', () async {
      when(() => remote.fetchTasks()).thenAnswer(
        (_) async => [row('t1', updatedAt: '2026-10-22T08:00:00.000Z')],
      );
      final result = await repository.updateTask(
        't1',
        const TaskDraft(title: 'Mine'),
      );
      await pumpEventQueue();
      expect(result, const Right<Failure, Unit>(unit));
      verify(() => remote.updateTask('t1', any())).called(1);
      verifyNever(() => remote.replaceShares(any(), any(), any()));
    });

    test('a change the server rejects is dropped', () async {
      when(() => remote.deleteTask('t1'))
          .thenThrow(const ServerException(message: 'nope'));
      final result = await repository.deleteTask('t1');
      await pumpEventQueue();
      expect(result, const Right<Failure, Unit>(unit));
      expect(store.outbox['me'], isEmpty);
    });

    test('a create the server already has is sent as an update', () async {
      when(() => remote.insertTask(any()))
          .thenThrow(const ServerException(message: 'dup', code: '23505'));
      await repository.createTask(const TaskDraft(title: 'Again'));
      await pumpEventQueue();
      final changes =
          verify(() => remote.updateTask('local-1', captureAny()))
                  .captured
                  .single
              as Map<String, dynamic>;
      expect(changes['title'], 'Again');
      expect(changes.containsKey('id'), isFalse);
      expect(store.outbox['me'], isEmpty);
    });

    test('writes need a signed-in user', () async {
      final signedOut = TaskRepositoryImpl(
        remote,
        store,
        network,
        FakeCurrentUser(null),
      );
      expect(
        await signedOut.deleteTask('t1'),
        const Left<Failure, Unit>(AuthFailure(message: 'Not signed in')),
      );
    });
  });
}
