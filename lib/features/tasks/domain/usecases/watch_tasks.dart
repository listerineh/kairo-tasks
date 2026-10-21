import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class WatchTasks {
  const WatchTasks(this._repository);

  final TaskRepository _repository;

  Stream<List<TaskEntity>> call() => _repository.watchTasks();
}
