import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/session/current_user.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_sync_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_store.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_model.dart';
import '../sync/outbox.dart';
import '../sync/pending_op.dart';

/// Offline-first tasks (docs/redesign-plan.md § V10).
///
/// - Reads: the stored copy shows at once; a server fetch replaces it and
///   is stored again. Waiting changes are always laid on top ([overlay]).
/// - Writes: applied to the outbox (merged per task, [enqueue]) and shown
///   immediately; then sent in order. Network errors leave them waiting;
///   server errors drop them (the next fetch shows the server's version).
/// - Conflicts: an update older than the server row's `updated_at` loses
///   ([updateStillWins]).
/// - Sending retries when connectivity comes back and on every listen.
@LazySingleton(as: TaskRepository)
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(
    this._remote,
    this._local,
    this._network,
    this._user, {
    @ignoreParam DateTime Function()? clock,
    @ignoreParam String Function()? newId,
  }) : _now = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final TaskRemoteDataSource _remote;
  final TaskLocalStore _local;
  final NetworkInfo _network;
  final CurrentUser _user;
  final DateTime Function() _now;
  final String Function() _newId;

  static const _signedOut = AuthFailure(message: 'Not signed in');

  /// Columns only the device fills in; the server sets its own.
  static const _localOnly = {
    'created_at',
    'updated_at',
    'completed_at',
    'shared_tasks',
  };

  /// Local writes and finished syncs, so open watchers re-emit or refetch.
  final _events = StreamController<_Event>.broadcast();
  final _status = StreamController<TaskSyncStatus>.broadcast();
  TaskSyncStatus _lastStatus = const TaskSyncStatus();
  // Lives as long as the repository (a singleton), so it is never cancelled.
  // ignore: cancel_subscriptions
  StreamSubscription<bool>? _connectivity;

  /// Serializes outbox reads and writes.
  Future<void> _lock = Future.value();

  /// The sync loop; one at a time.
  Future<void> _syncing = Future.value();

  /// Task id of the change being sent right now (always the outbox's first).
  String? _inFlight;

  Future<T> _locked<T>(Future<T> Function() body) {
    final result = _lock.then((_) => body());
    _lock = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  void _watchConnectivity() {
    _connectivity ??= _network.onConnectionChanged.listen((online) {
      _publish(online: online);
      if (online) _kickSync();
    }, onError: (Object _) {});
  }

  void _publish({bool? online, int? pending}) {
    final next = TaskSyncStatus(
      online: online ?? _lastStatus.online,
      pending: pending ?? _lastStatus.pending,
    );
    if (next == _lastStatus) return;
    _lastStatus = next;
    _status.add(next);
  }

  // Reads

  @override
  Stream<List<TaskEntity>> watchTasks() {
    final subscriptions = <StreamSubscription<Object?>>[];
    late final StreamController<List<TaskEntity>> out;
    var showedSomething = false;

    out = StreamController<List<TaskEntity>>(
      onListen: () {
        final userId = _user.id;
        if (userId == null) {
          out
            ..addError(_signedOut)
            ..close();
          return;
        }
        _watchConnectivity();

        Future<void> emitStored() async {
          final rows = await _local.readRows(userId);
          final ops = await _local.readOutbox(userId);
          _publish(pending: ops.length);
          if (rows == null && ops.isEmpty) return;
          if (out.isClosed) return;
          showedSomething = true;
          out.add(_entities(overlay(rows ?? const [], ops), userId));
        }

        Future<void> refresh() async {
          try {
            final rows = await _remote.fetchTasks();
            await _local.writeRows(userId, rows);
            _publish(online: true);
            final ops = await _local.readOutbox(userId);
            if (out.isClosed) return;
            showedSomething = true;
            out.add(_entities(overlay(rows, ops), userId));
          } on NetworkException catch (e) {
            _publish(online: false);
            if (!showedSomething && !out.isClosed) {
              out.addError(NetworkFailure(message: e.message));
            }
          } on ServerException catch (e) {
            if (!showedSomething && !out.isClosed) {
              out.addError(ServerFailure(message: e.message));
            } else {
              _log('tasks.refresh', e.message);
            }
          }
        }

        unawaited(() async {
          await emitStored();
          await refresh();
          _kickSync();
        }());

        subscriptions
          // Realtime rows lack the shares join, so refetch on every change.
          // Its errors (e.g. offline) don't matter: the stored copy stays.
          ..add(
            _remote
                .changes(userId)
                .listen((_) => unawaited(refresh()), onError: (Object _) {}),
          )
          ..add(
            _events.stream.listen(
              (event) =>
                  unawaited(event == _Event.local ? emitStored() : refresh()),
            ),
          );
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
        // Not awaited: done is never delivered once the listener is gone.
        unawaited(out.close());
      },
    );
    return out.stream;
  }

  @override
  Stream<TaskSyncStatus> watchSyncStatus() async* {
    _watchConnectivity();
    final userId = _user.id;
    if (userId != null) {
      _publish(pending: (await _local.readOutbox(userId)).length);
    }
    yield _lastStatus;
    yield* _status.stream;
  }

  List<TaskEntity> _entities(List<Map<String, dynamic>> rows, String userId) =>
      [for (final row in rows) TaskModel.fromJson(row, userId)];

  // Writes

  @override
  Future<Either<Failure, TaskEntity>> createTask(TaskDraft draft) async {
    final userId = _user.id;
    if (userId == null) return const Left(_signedOut);
    final id = _newId();
    final now = _now();
    final row = {
      ...TaskModel.insertJson(draft, userId),
      'id': id,
      'created_at': _iso(now),
      'updated_at': _iso(now),
      'shared_tasks': const <Map<String, dynamic>>[],
    };
    await _queue(
      userId,
      PendingOp(
        kind: PendingKind.create,
        taskId: id,
        at: now,
        changes: row,
        shares: draft.sharedWithIds,
      ),
    );
    return Right(
      TaskEntity(
        id: id,
        ownerId: userId,
        title: draft.title,
        description: draft.description,
        priority: draft.priority,
        startDate: draft.startDate,
        dueDate: draft.dueDate,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateTask(String id, TaskDraft draft) =>
      _write(
        id,
        (now) => {...TaskModel.updateJson(draft), 'updated_at': _iso(now)},
        shares: draft.sharedWithIds,
      );

  @override
  Future<Either<Failure, Unit>> setCompleted(
    String id, {
    required bool completed,
  }) => _write(
    id,
    (now) => {
      'status': TaskModel.statusName(
        completed ? TaskStatus.completed : TaskStatus.pending,
      ),
      // Shown locally right away; the server's trigger sets its own.
      'completed_at': completed ? _iso(now) : null,
      'updated_at': _iso(now),
    },
  );

  @override
  Future<Either<Failure, Unit>> deleteTask(String id) async {
    final userId = _user.id;
    if (userId == null) return const Left(_signedOut);
    await _queue(
      userId,
      PendingOp(kind: PendingKind.delete, taskId: id, at: _now()),
    );
    return const Right(unit);
  }

  Future<Either<Failure, Unit>> _write(
    String id,
    Map<String, dynamic> Function(DateTime now) changes, {
    List<String>? shares,
  }) async {
    final userId = _user.id;
    if (userId == null) return const Left(_signedOut);
    final now = _now();
    await _queue(
      userId,
      PendingOp(
        kind: PendingKind.update,
        taskId: id,
        at: now,
        changes: changes(now),
        shares: shares,
      ),
    );
    return const Right(unit);
  }

  Future<void> _queue(String userId, PendingOp op) async {
    final pending = await _locked(() async {
      final ops = enqueue(
        await _local.readOutbox(userId),
        op,
        firstInFlight: _inFlight == op.taskId,
      );
      await _local.writeOutbox(userId, ops);
      return ops.length;
    });
    _publish(pending: pending);
    _events.add(_Event.local);
    _kickSync();
  }

  // Sending

  void _kickSync() {
    final userId = _user.id;
    if (userId == null) return;
    _syncing = _syncing.then((_) => _sync(userId)).catchError((Object e) {
      _log('tasks.sync', '$e');
    });
  }

  Future<void> _sync(String userId) async {
    var sent = 0;
    Map<String, Map<String, dynamic>>? server;
    try {
      while (true) {
        final op = await _locked(() async {
          final ops = await _local.readOutbox(userId);
          final first = ops.isEmpty ? null : ops.first;
          _inFlight = first?.taskId;
          return first;
        });
        if (op == null) break;

        // Last-write-wins needs the server's current rows; fetch once.
        if (op.kind == PendingKind.update && server == null) {
          server = {
            for (final r in await _remote.fetchTasks()) r['id'] as String: r,
          };
        }
        try {
          await _send(userId, op, server);
        } on ServerException catch (e) {
          // Rejected (e.g. permissions): drop it; the next fetch shows the
          // server's version.
          _log(
            'tasks.sync.rejected',
            '${op.kind.name} ${op.taskId}: '
                '${e.message}',
          );
        }
        final pending = await _locked(() async {
          final ops = await _local.readOutbox(userId);
          // Remove what was sent; a change merged into it meanwhile was
          // appended after it, so it is still there.
          final rest = ops.isNotEmpty && ops.first == op ? ops.sublist(1) : ops;
          await _local.writeOutbox(userId, rest);
          _inFlight = null;
          return rest.length;
        });
        sent++;
        _publish(online: true, pending: pending);
      }
    } on NetworkException {
      _inFlight = null;
      _publish(online: false);
      return;
    }
    if (sent > 0) _events.add(_Event.synced);
  }

  Future<void> _send(
    String userId,
    PendingOp op,
    Map<String, Map<String, dynamic>>? server,
  ) async {
    switch (op.kind) {
      case PendingKind.create:
        final row = _serverColumns(op.changes)..['id'] = op.taskId;
        try {
          await _remote.insertTask(row);
        } on ServerException catch (e) {
          // Already inserted by an earlier attempt: send the fields instead.
          if (e.code != '23505') rethrow;
          await _remote.updateTask(
            op.taskId,
            _serverColumns(op.changes)
              ..remove('id')
              ..remove('owner_id'),
          );
        }
        final shares = op.shares;
        if (shares != null && shares.isNotEmpty) {
          await _remote.replaceShares(op.taskId, userId, shares);
        }
      case PendingKind.update:
        if (!updateStillWins(op, server?[op.taskId])) {
          _log('tasks.sync.lostConflict', op.taskId);
          return;
        }
        final changes = _serverColumns(op.changes);
        if (changes.isNotEmpty) await _remote.updateTask(op.taskId, changes);
        final shares = op.shares;
        if (shares != null) {
          await _remote.replaceShares(op.taskId, userId, shares);
        }
      case PendingKind.delete:
        await _remote.deleteTask(op.taskId);
    }
  }

  static Map<String, dynamic> _serverColumns(Map<String, dynamic> changes) => {
    for (final e in changes.entries)
      if (!_localOnly.contains(e.key)) e.key: e.value,
  };

  static String _iso(DateTime d) => d.toUtc().toIso8601String();

  static void _log(String operation, String detail) => LoggerService.instance
      .warning('Task sync', data: {'operation': operation, 'detail': detail});
}

enum _Event { local, synced }
