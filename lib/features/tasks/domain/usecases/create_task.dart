import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/task_draft.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CreateTask {
  const CreateTask(this._repository);

  final TaskRepository _repository;

  Future<Either<Failure, TaskEntity>> call(TaskDraft draft) {
    final title = draft.title.trim();
    if (title.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'A task needs a title')),
      );
    }
    return _repository.createTask(
      TaskDraft(
        title: title,
        description: draft.description,
        priority: draft.priority,
        startDate: draft.startDate,
        dueDate: draft.dueDate,
        sharedWithIds: draft.sharedWithIds,
      ),
    );
  }
}
