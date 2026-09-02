import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../app/locale/locale_service.dart';
import '../../app/router/app_router.dart';
import '../../generated/app_localizations.dart';
import '../../features/tasks/domain/entities/task_entity.dart';
import 'logger_service.dart';
import 'notification_store.dart';

// ignore_for_file: avoid_positional_boolean_parameters, directives_ordering

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
  static const int _kStreakId = 9999;
  static const int _kStreakReminderId = 8888;
  static const int _kStreakLostId = 8887;
  static const int _kFocusSessionId = 7777;

  int _reminderId(String taskId, int offset) =>
      taskId.hashCode.abs() + offset;

  AppLocalizations _l10n() =>
      lookupAppLocalizations(LocaleService.instance.locale.value);

  tz.TZDateTime _next8am() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _payloadJson({
    required String type,
    required String title,
    required String body,
  }) {
    return jsonEncode({
      'type': type,
      'title': title,
      'body': body,
    });
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    required String type,
    String? taskId,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: _payloadJson(type: type, title: title, body: body),
      );
    } catch (e) {
      LoggerService.instance.error(
        'Failed to schedule notification',
        data: {
          'operation': 'notification.zonedSchedule',
          if (taskId != null) 'task_id': taskId,
          'id': id,
          'scheduled_date': scheduledDate.toIso8601String(),
          'error': e.toString(),
        },
      );
    }
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
      (Platform.isAndroid || Platform.isIOS) &&
      Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    LoggerService.instance.info(
      'Initializing notification service',
      data: {'operation': 'notification.initialize'},
    );

    try {
      _prefs = await SharedPreferences.getInstance();

      tz.initializeTimeZones();
      try {
        final localInfo = await FlutterTimezone.getLocalTimezone();
        final location = tz.getLocation(localInfo.identifier);
        tz.setLocalLocation(location);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to set local timezone, falling back to UTC: $e');
        }
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

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

      LoggerService.instance.info(
        'Local notifications initialized',
        data: {'operation': 'notification.initialize'},
      );

      if (_fcmAvailable) {
        LoggerService.instance.info(
          'FCM is available',
          data: {'operation': 'notification.initialize'},
        );
        _messaging = FirebaseMessaging.instance;
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
        _messaging!.onTokenRefresh.listen(_onTokenRefresh);
        final initial = await _messaging.getInitialMessage();
        if (initial != null) _navigateFromMessage(initial);
      } else {
        LoggerService.instance.info(
          'FCM is unavailable',
          data: {'operation': 'notification.initialize'},
        );
        _messaging = null;
      }
    } on Exception catch (e) {
      LoggerService.instance.error(
        'Notification service initialization failed',
        data: {'operation': 'notification.initialize', 'error': e.toString()},
      );
    }
  }

  Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final title = decoded['title'] as String? ?? '';
      final body = decoded['body'] as String? ?? '';
      final type = decoded['type'] as String? ?? 'local';

      if (title.isNotEmpty && body.isNotEmpty) {
        await NotificationStore.instance.add(
          title: title,
          body: body,
          type: type,
          id: response.id?.toString(),
        );
      }
    } on FormatException catch (_) {
      LoggerService.instance.warning(
        'Ignoring malformed local notification payload',
        data: {
          'operation': 'notification.onDidReceiveNotificationResponse',
          'payload': payload,
        },
      );
    }
  }

  Future<bool> requestPermission() async {
    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'unknown';
    LoggerService.instance.info(
      'Requesting notification permission',
      data: {'operation': 'notification.requestPermission', 'platform': platform},
    );

    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      final result = granted ?? true;
      LoggerService.instance.info(
        'Notification permission result',
        data: {
          'operation': 'notification.requestPermission',
          'platform': platform,
          'granted': result,
        },
      );
      return result;
    }

    if (Platform.isIOS) {
      if (_fcmAvailable) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        final granted =
            settings.authorizationStatus == AuthorizationStatus.authorized;
        LoggerService.instance.info(
          'Notification permission result',
          data: {
            'operation': 'notification.requestPermission',
            'platform': platform,
            'granted': granted,
          },
        );
        return granted;
      }

      final iOSImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iOSImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      final result = granted ?? true;
      LoggerService.instance.info(
        'Notification permission result',
        data: {
          'operation': 'notification.requestPermission',
          'platform': platform,
          'granted': result,
        },
      );
      return result;
    }

    LoggerService.instance.info(
      'Notification permission not supported on this platform',
      data: {'operation': 'notification.requestPermission', 'platform': platform},
    );
    return false;
  }

  Future<void> registerFcmToken() async {
    if (!_fcmAvailable) {
      LoggerService.instance.info(
        'FCM token registration skipped, FCM unavailable',
        data: {'operation': 'notification.registerFcmToken'},
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      LoggerService.instance.info(
        'FCM token registration skipped, no authenticated user',
        data: {'operation': 'notification.registerFcmToken'},
      );
      return;
    }

    LoggerService.instance.info(
      'Registering FCM token',
      data: {'operation': 'notification.registerFcmToken'},
    );

    try {
      final token = await _messaging!.getToken();
      LoggerService.instance.info(
        'FCM token retrieved',
        data: {
          'operation': 'notification.registerFcmToken',
          'token_length': token?.length,
        },
      );
      if (token == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      LoggerService.instance.error(
        'FCM token registration failed',
        data: {'operation': 'notification.registerFcmToken', 'error': e.toString()},
      );
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
    final nowUtc = tz.TZDateTime.now(tz.UTC);
    final l10n = _l10n();

    Future<void> scheduleIfFuture(
      tz.TZDateTime scheduledDate,
      int id,
      String title,
      String body,
      String type,
    ) async {
      if (!scheduledDate.isAfter(nowUtc)) return;
      try {
        await _zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          details: details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          type: type,
        );
      } catch (e) {
        LoggerService.instance.error(
          'Failed to schedule task reminder',
          data: {
            'operation': 'notification.scheduleTaskReminder',
            'task_id': task.id,
            'scheduled_date': scheduledDate.toIso8601String(),
            'error': e.toString(),
          },
        );
      }
    }

    final startDate = task.startDate;
    if (startDate != null && startDate.isAfter(now)) {
      final startReminder = tz.TZDateTime.from(
        startDate.subtract(const Duration(minutes: 5)).toUtc(),
        tz.UTC,
      );
      await scheduleIfFuture(
        startReminder,
        _reminderId(task.id, _kStartReminderOffset),
        task.title,
        l10n.notificationTaskStartsSoon,
        'task_reminder',
      );
    }

    final dueDate = task.dueDate;
    if (dueDate != null && dueDate.isAfter(now)) {
      final dueSoon = tz.TZDateTime.from(
        dueDate.subtract(const Duration(minutes: 15)).toUtc(),
        tz.UTC,
      );
      await scheduleIfFuture(
        dueSoon,
        _reminderId(task.id, _kDueSoonOffset),
        task.title,
        l10n.notificationTaskDueSoon,
        'task_reminder',
      );

      final overdue = tz.TZDateTime.from(dueDate.toUtc(), tz.UTC);
      await scheduleIfFuture(
        overdue,
        _reminderId(task.id, _kOverdueOffset),
        task.title,
        l10n.notificationTaskOverdue,
        'task_reminder',
      );

      if (task.priority == TaskPriority.urgent &&
          dueDate.isAfter(now.add(const Duration(hours: 1)))) {
        final oneHourReminder = tz.TZDateTime.from(
          dueDate.subtract(const Duration(hours: 1)).toUtc(),
          tz.UTC,
        );
        await scheduleIfFuture(
          oneHourReminder,
          _reminderId(task.id, _kUrgentOffset),
          l10n.notificationUrgentTitle(task.title),
          l10n.notificationTaskUrgentOneHour,
          'task_reminder',
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
    await _flutterLocalNotificationsPlugin
        .cancel(_reminderId(taskId, _kUrgentOffset));
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
    await rescheduleInactivityNudge(tasks);
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

    final l10n = _l10n();
    final title = l10n.kairoTasks;
    final String body;
    if (todayCount == 0 && overdueCount == 0) {
      body = l10n.notificationMorningNoPending;
    } else if (overdueCount == 0) {
      body = l10n.notificationMorningTodayCount(todayCount);
    } else if (todayCount == 0) {
      body = l10n.notificationMorningOverdueCount(overdueCount);
    } else {
      body = l10n.notificationMorningTodayAndOverdueCount(
        todayCount,
        overdueCount,
      );
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

    await _zonedSchedule(
      id: _kMorningSummaryId,
      title: title,
      body: body,
      scheduledDate: _next8am(),
      details: details,
      androidScheduleMode: AndroidScheduleMode.inexact,
      type: 'morning',
    );
  }

  Future<void> rescheduleInactivityNudge(List<TaskEntity> tasks) async {
    await _flutterLocalNotificationsPlugin.cancel(_kInactivityNudgeId);

    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day);

    final createdToday = tasks.any((t) {
      final created = t.createdAt.toLocal();
      return created.year == today.year &&
          created.month == today.month &&
          created.day == today.day;
    });

    if (createdToday || now.hour >= 20) {
      return;
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

    final l10n = _l10n();
    final title = l10n.kairoTasks;
    final body = l10n.notificationInactivityBody;
    await _zonedSchedule(
      id: _kInactivityNudgeId,
      title: title,
      body: body,
      scheduledDate: _next8pm(),
      details: details,
      androidScheduleMode: AndroidScheduleMode.inexact,
      type: 'inactivity',
    );
  }

  Future<void> showStreakNotification(int streak) async {
    final l10n = _l10n();
    await showLocalNotification(
      id: _kStreakId,
      title: l10n.notificationStreakEarnedTitle,
      body: l10n.notificationStreakEarnedBody(streak),
    );
  }

  Future<void> rescheduleStreakReminders({
    required int streak,
    required bool hasCompletedToday,
  }) async {
    await _flutterLocalNotificationsPlugin.cancel(_kStreakReminderId);
    await _flutterLocalNotificationsPlugin.cancel(_kStreakLostId);

    if (hasCompletedToday || streak <= 0) {
      LoggerService.instance.info(
        'Streak reminders canceled',
        data: {
          'operation': 'notification.rescheduleStreakReminders',
          'hasCompletedToday': hasCompletedToday,
          'streak': streak,
        },
      );
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var closeDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 23);
    if (!closeDate.isAfter(now)) {
      closeDate = closeDate.add(const Duration(days: 1));
    }

    final lostDate = tz.TZDateTime(
      tz.local,
      closeDate.year,
      closeDate.month,
      closeDate.day + 1,
      0,
      0,
      1,
    );

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

    final l10n = _l10n();
    await _zonedSchedule(
      id: _kStreakReminderId,
      title: l10n.notificationStreakCloseTitle,
      body: l10n.notificationStreakCloseBody(streak),
      scheduledDate: closeDate,
      details: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      type: 'streak',
    );

    await _zonedSchedule(
      id: _kStreakLostId,
      title: l10n.notificationStreakLostTitle,
      body: l10n.notificationStreakLostBody(streak),
      scheduledDate: lostDate,
      details: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      type: 'streak',
    );

    LoggerService.instance.info(
      'Streak reminders rescheduled',
      data: {
        'operation': 'notification.rescheduleStreakReminders',
        'closeDate': closeDate.toIso8601String(),
        'lostDate': lostDate.toIso8601String(),
        'streak': streak,
      },
    );
  }

  Future<void> cancelStreakReminders() async {
    await _flutterLocalNotificationsPlugin.cancel(_kStreakReminderId);
    await _flutterLocalNotificationsPlugin.cancel(_kStreakLostId);
  }

  Future<void> scheduleFocusSessionEnd({
    required Duration duration,
    String? taskTitle,
  }) async {
    await _flutterLocalNotificationsPlugin.cancel(_kFocusSessionId);

    final now = tz.TZDateTime.now(tz.local);
    final scheduleDate = now.add(duration);

    final l10n = _l10n();
    final title = taskTitle != null
        ? l10n.focusSessionCompleteTitle
        : l10n.focusBreakCompleteTitle;
    final body = taskTitle != null
        ? l10n.focusSessionCompleteBody(taskTitle)
        : l10n.focusBreakCompleteBody;

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

    await _zonedSchedule(
      id: _kFocusSessionId,
      title: title,
      body: body,
      scheduledDate: scheduleDate,
      details: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      type: 'focus',
    );

    LoggerService.instance.info(
      'Focus session end scheduled',
      data: {
        'operation': 'notification.scheduleFocusSessionEnd',
        'scheduleDate': scheduleDate.toIso8601String(),
        'taskTitle': taskTitle,
      },
    );
  }

  Future<void> cancelFocusSessionEnd() async {
    await _flutterLocalNotificationsPlugin.cancel(_kFocusSessionId);
  }

  Future<void> scheduleSoftReminder({
    required String taskId,
    required String taskTitle,
    required Duration delay,
  }) async {
    final id = _softReminderIdFor(taskId);
    await _flutterLocalNotificationsPlugin.cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    final scheduleDate = now.add(delay);

    final l10n = _l10n();
    final title = l10n.softReminderTitle;
    final body = l10n.softReminderBody(taskTitle);

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

    await _zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduleDate,
      details: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      type: 'soft_reminder',
    );

    LoggerService.instance.info(
      'Soft reminder scheduled',
      data: {
        'operation': 'notification.scheduleSoftReminder',
        'scheduleDate': scheduleDate.toIso8601String(),
        'taskTitle': taskTitle,
        'delayMinutes': delay.inMinutes,
      },
    );
  }

  int _softReminderIdFor(String taskId) {
    return taskId.hashCode.abs() + 600000000;
  }

  Future<void> showUrgentNotification(TaskEntity task) async {
    final l10n = _l10n();
    final dueText = task.dueDate != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate!)
        : '';
    await showLocalNotification(
      title: l10n.notificationUrgentTitle(task.title),
      body: dueText.isNotEmpty
          ? l10n.notificationUrgentBody(dueText)
          : 'High priority task',
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
    String type = 'local',
    String? storeId,
  }) async {
    LoggerService.instance.info(
      'Showing local notification',
      data: {
        'operation': 'notification.showLocalNotification',
        'title': title,
        'id': id,
      },
    );

    unawaited(
      NotificationStore.instance.add(
        title: title,
        body: body,
        type: type,
        id: storeId,
      ),
    );

    try {
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
    } catch (e) {
      LoggerService.instance.error(
        'Failed to show local notification',
        data: {
          'operation': 'notification.showLocalNotification',
          'title': title,
          'id': id,
          'error': e.toString(),
        },
      );
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (!Platform.isAndroid) return;

    final notification = message.notification;
    if (notification == null) return;

    LoggerService.instance.info(
      'FCM foreground message received',
      data: {
        'operation': 'notification.onForegroundMessage',
        'message_id': message.messageId,
        'title': notification.title,
      },
    );

    try {
      final l10n = _l10n();
      await showLocalNotification(
        title: notification.title ??
            (message.data['title'] as String?) ??
            l10n.kairoTasks,
        body: notification.body ?? (message.data['body'] as String?) ?? '',
        id: message.messageId?.hashCode ?? 0,
        type: 'push',
        storeId: message.messageId,
      );
    } catch (e) {
      LoggerService.instance.error(
        'Failed to show foreground notification',
        data: {
          'operation': 'notification.onForegroundMessage',
          'message_id': message.messageId,
          'error': e.toString(),
        },
      );
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final type = message.data['type'] as String? ?? '';
    LoggerService.instance.info(
      'Notification opened from background',
      data: {'operation': 'notification.onMessageOpened', 'type': type},
    );

    final title = message.notification?.title ??
        (message.data['title'] as String?) ??
        '';
    final body = message.notification?.body ??
        (message.data['body'] as String?) ??
        '';
    if (title.isNotEmpty) {
      unawaited(
        NotificationStore.instance.add(
          title: title,
          body: body,
          type: 'push',
          id: message.messageId,
        ),
      );
    }

    _navigateFromMessage(message);
  }

  Future<void> _onTokenRefresh(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    LoggerService.instance.info(
      'FCM token refreshed',
      data: {
        'operation': 'notification.onTokenRefresh',
        'token_length': token.length,
      },
    );

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      LoggerService.instance.error(
        'FCM token refresh update failed',
        data: {'operation': 'notification.onTokenRefresh', 'error': e.toString()},
      );
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
