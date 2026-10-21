import 'package:injectable/injectable.dart';

import '../domain/repositories/task_repository.dart';
import '../domain/usecases/create_task.dart';
import '../domain/usecases/delete_task.dart';
import '../domain/usecases/set_task_completed.dart';
import '../domain/usecases/update_task.dart';
import '../domain/usecases/watch_tasks.dart';

/// Registers the task use cases; the domain layer itself stays free of DI
/// annotations.
@module
abstract class TasksModule {
  WatchTasks watchTasks(TaskRepository r) => WatchTasks(r);
  CreateTask createTask(TaskRepository r) => CreateTask(r);
  UpdateTask updateTask(TaskRepository r) => UpdateTask(r);
  SetTaskCompleted setTaskCompleted(TaskRepository r) => SetTaskCompleted(r);
  DeleteTask deleteTask(TaskRepository r) => DeleteTask(r);
}
