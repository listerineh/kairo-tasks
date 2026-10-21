import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/task_draft.dart';
import '../repositories/task_repository.dart';

class UpdateTask {
  const UpdateTask(this._repository);

  final TaskRepository _repository;

  Future<Either<Failure, Unit>> call(String id, TaskDraft draft) {
    if (draft.title.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'A task needs a title')),
      );
    }
    return _repository.updateTask(id, draft);
  }
}
