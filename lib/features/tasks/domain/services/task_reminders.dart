import '../entities/task_entity.dart';

/// Local notifications that follow task changes (reminders, morning
/// summary, streak nudges). A port so the tasks logic stays testable; the
/// data layer implements it with the notification service.
abstract class TaskReminders {
  Future<void> tasksLoaded(
    List<TaskEntity> tasks, {
    required int streak,
    required bool completedToday,
  });

  Future<void> taskCreated(TaskEntity task, List<TaskEntity> allTasks);

  Future<void> taskCompleted(String taskId);

  Future<void> taskDeleted(String taskId);

  /// The first completion of the day extended the streak to [streak] days.
  Future<void> streakExtended(int streak);
}
