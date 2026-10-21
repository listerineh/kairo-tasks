import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/task_repository.dart';

class SetTaskCompleted {
  const SetTaskCompleted(this._repository);

  final TaskRepository _repository;

  Future<Either<Failure, Unit>> call(String id, {required bool completed}) =>
      _repository.setCompleted(id, completed: completed);
}
