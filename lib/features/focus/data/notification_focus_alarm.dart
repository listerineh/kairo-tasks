import 'package:injectable/injectable.dart';

import '../../../core/services/notification_service.dart';
import '../domain/focus_session.dart';

/// [FocusAlarm] over the app's local notifications.
@LazySingleton(as: FocusAlarm)
class NotificationFocusAlarm implements FocusAlarm {
  @override
  Future<void> schedule({required Duration after, String? taskTitle}) =>
      NotificationService.instance.scheduleFocusSessionEnd(
        duration: after,
        taskTitle: taskTitle,
      );

  @override
  Future<void> cancel() => NotificationService.instance.cancelFocusSessionEnd();
}
