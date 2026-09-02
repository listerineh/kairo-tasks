import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'app/locale/locale_service.dart';
import 'core/constants/app_constants.dart';
import 'core/services/logger_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase and notifications
  // Firebase is only available if google-services.json /
  // GoogleService-Info.plist are present. Otherwise remote push is disabled.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase not configured, remote push disabled: $e');
    }
  }

  await LocaleService.instance.init();
  await NotificationService.instance.initialize();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  // Initialize logging
  await LoggerService.instance.init();
  LoggerService.instance.info('App started');

  await NotificationStore.instance.load();

  // Initialize dependency injection
  await configureDependencies();

  // Load onboarding flag and current session
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  final session = Supabase.instance.client.auth.currentSession;
  final initialLocation = session != null
      ? '/dashboard'
      : (hasSeenOnboarding ? '/login' : '/onboarding');

  // Capture Flutter and platform errors
  FlutterError.onError = (details) {
    LoggerService.instance.error(
      'Flutter error',
      data: <String, dynamic>{
        'exception': details.exception.toString(),
        'stack': details.stack.toString(),
      },
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    LoggerService.instance.error(
      'Platform error',
      data: <String, dynamic>{
        'error': error.toString(),
        'stack': stack.toString(),
      },
    );
    return true;
  };

  runZonedGuarded<void>(
    () => runApp(KairoApp(initialLocation: initialLocation)),
    (error, stackTrace) {
      LoggerService.instance.error(
        'Uncaught zone error',
        data: <String, dynamic>{
          'error': error.toString(),
          'stack': stackTrace.toString(),
        },
      );
    },
  );
}
