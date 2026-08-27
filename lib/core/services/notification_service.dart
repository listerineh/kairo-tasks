import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../app/router/app_router.dart';
import '../../features/tasks/domain/entities/task_entity.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// Top-level background message handler for Firebase Cloud Messaging.
/// It is executed in its own isolate and must be a top-level function.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase not configured in background handler: $e');
    }
    return;
  }
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId}');
  }
}

/// App-side notification service.
///
/// - Android: FCM remote notifications + local task reminders.
/// - iOS: local notifications only (no APNs/FCM remote without a paid
///   Apple Developer account).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String kTaskReminders = 'task_reminders_enabled';
  static const String kFriendActivity = 'friend_activity_enabled';
  static const String kSharedTaskUpdates = 'shared_task_updates_enabled';

  static const int _kStartReminderOffset = 100000000;
  static const int _kDueSoonOffset = 200000000;
  static const int _kOverdueOffset = 300000000;
  static const int _kUrgentOffset = 400000000;
  static const int _kMorningSummaryId = 999999998;
  static const int _kInactivityNudgeId = 999999999;

  int _reminderId(String taskId, int offset) =>
      taskId.hashCode.abs() + offset;

  tz.TZDateTime _next8am() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _next8pm() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  late final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  late final FirebaseMessaging? _messaging;
  late SharedPreferences? _prefs;

  bool get _fcmAvailable =>
      Platform.isAndroid &&
      Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    if (_fcmAvailable) {
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
      _messaging!.onTokenRefresh.listen(_onTokenRefresh);
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _navigateFromMessage(initial);
    }
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? true;
    }

    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }

    return false;
  }

  Future<void> registerFcmToken() async {
    if (!_fcmAvailable) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging!.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token registration failed: $e');
      }
    }
  }

  Future<bool> getTaskRemindersEnabled() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(kTaskReminders) ?? false;
  }

  Future<bool> getFriendActivityEnabled() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(kFriendActivity) ?? true;
  }

  Future<bool> getSharedTaskUpdatesEnabled() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(kSharedTaskUpdates) ?? true;
  }

  Future<void> scheduleTaskReminder(TaskEntity task) async {
    if (task.status == TaskStatus.completed) return;
    if (!await getTaskRemindersEnabled()) return;

    await cancelTaskReminder(task.id);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
            'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = DateTime.now();

    final startDate = task.startDate;
    if (startDate != null && startDate.isAfter(now)) {
      final startReminder = tz.TZDateTime.from(
        startDate.subtract(const Duration(minutes: 5)).toUtc(),
        tz.UTC,
      );
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _reminderId(task.id, _kStartReminderOffset),
        task.title,
        'Starts in 5 minutes',
        startReminder,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );
    }

    final dueDate = task.dueDate;
    if (dueDate != null && dueDate.isAfter(now)) {
      final dueSoon = tz.TZDateTime.from(
        dueDate.subtract(const Duration(minutes: 15)).toUtc(),
        tz.UTC,
      );
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _reminderId(task.id, _kDueSoonOffset),
        task.title,
        'Due soon',
        dueSoon,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );

      final overdue = tz.TZDateTime.from(dueDate.toUtc(), tz.UTC);
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _reminderId(task.id, _kOverdueOffset),
        task.title,
        'This task is overdue',
        overdue,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );

      if (task.priority == TaskPriority.urgent &&
          dueDate.isAfter(now.add(const Duration(hours: 1)))) {
        final oneHourReminder = tz.TZDateTime.from(
          dueDate.subtract(const Duration(hours: 1)).toUtc(),
          tz.UTC,
        );
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          _reminderId(task.id, _kUrgentOffset),
          task.title,
          'Urgent due in 1 hour',
          oneHourReminder,
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
      }
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _flutterLocalNotificationsPlugin
        .cancel(_reminderId(taskId, _kStartReminderOffset));
    await _flutterLocalNotificationsPlugin
        .cancel(_reminderId(taskId, _kDueSoonOffset));
    await _flutterLocalNotificationsPlugin
        .cancel(_reminderId(taskId, _kOverdueOffset));
  }

  Future<void> cancelAllTaskReminders() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> rescheduleAll(List<TaskEntity> tasks) async {
    await cancelAllTaskReminders();
    for (final task in tasks) {
      await scheduleTaskReminder(task);
    }
    await rescheduleMorningSummary(tasks);
    await rescheduleInactivityNudge();
  }

  Future<void> rescheduleMorningSummary(List<TaskEntity> tasks) async {
    await _flutterLocalNotificationsPlugin.cancel(_kMorningSummaryId);

    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day);

    var todayCount = 0;
    var overdueCount = 0;
    for (final task in tasks) {
      final dueDate = task.dueDate;
      if (dueDate == null || task.status == TaskStatus.completed) continue;

      if (dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day) {
        todayCount++;
      } else if (dueDate.isBefore(today)) {
        overdueCount++;
      }
    }

    final String body;
    if (todayCount == 0 && overdueCount == 0) {
      body = 'No tienes tareas pendientes';
    } else if (overdueCount == 0) {
      body = 'Tienes $todayCount tareas hoy';
    } else if (todayCount == 0) {
      body = 'Tienes $overdueCount tareas vencidas';
    } else {
      body = 'Tienes $todayCount tareas hoy y $overdueCount vencidas';
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
            'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _kMorningSummaryId,
      'KairoTasks',
      body,
      _next8am(),
      details,
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  Future<void> rescheduleInactivityNudge() async {
    await _flutterLocalNotificationsPlugin.cancel(_kInactivityNudgeId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
            'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _kInactivityNudgeId,
      'KairoTasks',
      'No has creado tareas en el día',
      _next8pm(),
      details,
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  Future<void> showUrgentNotification(TaskEntity task) async {
    await showLocalNotification(
      title: 'Urgent: ${task.title}',
      body: task.dueDate != null ? 'Due ${task.dueDate}' : 'High priority task',
      id: task.id.hashCode.abs() + 500000000,
    );
  }

  Future<void> setFriendActivityEnabled(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(kFriendActivity, value);
  }

  Future<void> setSharedTaskUpdatesEnabled(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(kSharedTaskUpdates, value);
  }

  Future<void> onToggleTaskReminders(
    bool value, {
    List<TaskEntity> tasks = const [],
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(kTaskReminders, value);

    if (value) {
      await rescheduleAll(tasks);
    } else {
      await cancelAllTaskReminders();
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (!Platform.isAndroid) return;

    final notification = message.notification;
    if (notification == null) return;

    await showLocalNotification(
      title: notification.title ??
          (message.data['title'] as String?) ??
          'KairoTasks',
      body: notification.body ?? (message.data['body'] as String?) ?? '',
      id: message.messageId?.hashCode ?? 0,
    );
  }

  void _onMessageOpened(RemoteMessage message) {
    _navigateFromMessage(message);
  }

  Future<void> _onTokenRefresh(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token refresh update failed: $e');
      }
    }
  }

  void _navigateFromMessage(RemoteMessage message) {
    final router = AppRouter.router;
    if (router == null) return;
    if (Supabase.instance.client.auth.currentSession == null) return;

    final type = message.data['type'] as String? ?? '';
    switch (type) {
      case 'friend_request':
      case 'friend_accepted':
        router.go('/social');
      case 'shared_task':
      case 'task_shared':
        router.go('/tasks');
      case 'task_due':
      case 'task_reminder':
        router.go('/calendar');
      default:
        router.go('/dashboard');
    }
  }
}
