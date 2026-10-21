import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/task_draft.dart';
import '../entities/task_entity.dart';

abstract class TaskRepository {
  /// The signed-in user's tasks plus tasks shared with them, newest first.
  /// Emits the full list on listen and again after every remote change
  /// (own tasks or shares). Errors arrive as [Failure] stream errors.
  Stream<List<TaskEntity>> watchTasks();

  Future<Either<Failure, TaskEntity>> createTask(TaskDraft draft);

  Future<Either<Failure, Unit>> updateTask(String id, TaskDraft draft);

  Future<Either<Failure, Unit>> setCompleted(
    String id, {
    required bool completed,
  });

  Future<Either<Failure, Unit>> deleteTask(String id);
}
