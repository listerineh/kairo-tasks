import '../entities/task_sync_status.dart';
import '../repositories/task_repository.dart';

class WatchSyncStatus {
  const WatchSyncStatus(this._repository);

  final TaskRepository _repository;

  Stream<TaskSyncStatus> call() => _repository.watchSyncStatus();
}
