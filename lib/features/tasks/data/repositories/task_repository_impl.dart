import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/session/current_user.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_model.dart';

@LazySingleton(as: TaskRepository)
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(
    this._remote,
    this._user, {
    @ignoreParam DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final TaskRemoteDataSource _remote;
  final CurrentUser _user;
  final DateTime Function() _now;

  static const _signedOut = AuthFailure(message: 'Not signed in');

  @override
  Stream<List<TaskEntity>> watchTasks() {
    StreamSubscription<void>? changes;
    late final StreamController<List<TaskEntity>> out;

    void fail(Object error) {
      if (out.isClosed) return;
      out.addError(
        error is ServerException
            ? ServerFailure(message: error.message)
            : error,
      );
    }

    Future<void> refresh(String userId) async {
      try {
        final tasks = await _fetch(userId);
        if (!out.isClosed) out.add(tasks);
      } on ServerException catch (e) {
        fail(e);
      }
    }

    out = StreamController<List<TaskEntity>>(
      onListen: () {
        final userId = _user.id;
        if (userId == null) {
          out
            ..addError(_signedOut)
            ..close();
          return;
        }
        unawaited(refresh(userId));
        // Realtime rows lack the shares join, so refetch on every change.
        changes = _remote
            .changes(userId)
            .listen((_) => unawaited(refresh(userId)), onError: fail);
      },
      onCancel: () async {
        await changes?.cancel();
        // Not awaited: done is never delivered once the listener is gone.
        unawaited(out.close());
      },
    );
    return out.stream;
  }

  Future<List<TaskEntity>> _fetch(String userId) async {
    final rows = await _remote.fetchTasks();
    return [for (final row in rows) TaskModel.fromJson(row, userId)];
  }

  @override
  Future<Either<Failure, TaskEntity>> createTask(TaskDraft draft) => _run((
    userId,
  ) async {
    final id = await _remote.insertTask(TaskModel.insertJson(draft, userId));
    final friends = draft.sharedWithIds;
    if (friends != null && friends.isNotEmpty) {
      await _remote.replaceShares(id, userId, friends);
    }
    return TaskEntity(
      id: id,
      ownerId: userId,
      title: draft.title,
      description: draft.description,
      priority: draft.priority,
      startDate: draft.startDate,
      dueDate: draft.dueDate,
      createdAt: _now(),
    );
  });

  @override
  Future<Either<Failure, Unit>> updateTask(String id, TaskDraft draft) =>
      _run((userId) async {
        await _remote.updateTask(id, TaskModel.updateJson(draft));
        final friends = draft.sharedWithIds;
        if (friends != null) await _remote.replaceShares(id, userId, friends);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> setCompleted(
    String id, {
    required bool completed,
  }) => _run((_) async {
    final status = completed ? TaskStatus.completed : TaskStatus.pending;
    await _remote.updateTask(id, {'status': TaskModel.statusName(status)});
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> deleteTask(String id) => _run((_) async {
    await _remote.deleteTask(id);
    return unit;
  });

  Future<Either<Failure, T>> _run<T>(
    Future<T> Function(String userId) action,
  ) async {
    final userId = _user.id;
    if (userId == null) return const Left(_signedOut);
    try {
      return Right(await action(userId));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
