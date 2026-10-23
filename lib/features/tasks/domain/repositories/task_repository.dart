import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/task_draft.dart';
import '../entities/task_entity.dart';
import '../entities/task_sync_status.dart';

/// Tasks work offline: the list comes from the device first, changes apply
/// locally at once and wait in an outbox until the server confirms them
/// (last-write-wins on `updated_at`). Writes only fail for local reasons
/// (not signed in); a change the server later rejects is dropped and the
/// next refresh shows the server's version.
abstract class TaskRepository {
  /// The signed-in user's tasks plus tasks shared with them, newest first,
  /// with local changes applied. Emits the stored copy on listen (if any),
  /// then after every server refresh, remote change or local change.
  /// Errors arrive as [Failure] stream errors only when there is nothing
  /// stored to show.
  Stream<List<TaskEntity>> watchTasks();

  /// Connection and outbox state, for the "offline" hint.
  Stream<TaskSyncStatus> watchSyncStatus();

  Future<Either<Failure, TaskEntity>> createTask(TaskDraft draft);

  Future<Either<Failure, Unit>> updateTask(String id, TaskDraft draft);

  Future<Either<Failure, Unit>> setCompleted(
    String id, {
    required bool completed,
  });

  Future<Either<Failure, Unit>> deleteTask(String id);
}
