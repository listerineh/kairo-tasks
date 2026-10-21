import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/task_repository.dart';

class DeleteTask {
  const DeleteTask(this._repository);

  final TaskRepository _repository;

  Future<Either<Failure, Unit>> call(String id) => _repository.deleteTask(id);
}
