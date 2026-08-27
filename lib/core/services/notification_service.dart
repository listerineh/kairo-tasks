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
    if (task.dueDate == null) return;

    final dueDate = task.dueDate!;
    if (!dueDate.isAfter(DateTime.now())) return;
    if (!await getTaskRemindersEnabled()) return;

    final scheduledDate = tz.TZDateTime.from(
      dueDate.subtract(const Duration(minutes: 15)).toUtc(),
      tz.UTC,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      task.id.hashCode.abs(),
      task.title,
      'Due soon',
      scheduledDate,
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
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _flutterLocalNotificationsPlugin.cancel(taskId.hashCode.abs());
  }

  Future<void> cancelAllTaskReminders() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> rescheduleAll(List<TaskEntity> tasks) async {
    await cancelAllTaskReminders();
    for (final task in tasks) {
      await scheduleTaskReminder(task);
    }
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
