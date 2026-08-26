import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';

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
  await NotificationService.instance.initialize();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  // Initialize dependency injection
  await configureDependencies();

  // Register Android FCM token on startup
  if (Platform.isAndroid) {
    await NotificationService.instance.registerFcmToken();
  }

  runApp(const KairoTasksApp());
}
