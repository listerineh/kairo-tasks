import 'package:injectable/injectable.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/services/task_reminders.dart';

/// [TaskReminders] backed by the app's local notification service.
@LazySingleton(as: TaskReminders)
class NotificationTaskReminders implements TaskReminders {
  NotificationService get _notifications => NotificationService.instance;

  @override
  Future<void> tasksLoaded(
    List<TaskEntity> tasks, {
    required int streak,
    required bool completedToday,
  }) async {
    await _notifications.rescheduleMorningSummary(tasks);
    await _notifications.rescheduleStreakReminders(
      streak: streak,
      hasCompletedToday: completedToday,
    );
  }

  @override
  Future<void> taskCreated(TaskEntity task, List<TaskEntity> allTasks) async {
    await _notifications.scheduleTaskReminder(task);
    await _notifications.rescheduleInactivityNudge(allTasks);
    if (task.priority == TaskPriority.urgent) {
      await _notifications.showUrgentNotification(task);
    }
  }

  @override
  Future<void> taskUpdated(TaskEntity task) async {
    await _notifications.cancelTaskReminder(task.id);
    if (task.dueDate != null && task.status != TaskStatus.completed) {
      await _notifications.scheduleTaskReminder(task);
    }
  }

  @override
  Future<void> taskCompleted(String taskId) =>
      _notifications.cancelTaskReminder(taskId);

  @override
  Future<void> taskDeleted(String taskId) =>
      _notifications.cancelTaskReminder(taskId);

  @override
  Future<void> streakExtended(int streak) =>
      _notifications.showStreakNotification(streak);
}
