import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// App-side service that buffers log entries and flushes them to a
/// Supabase Edge Function.
class LoggerService {
  LoggerService._();

  /// Singleton instance.
  static final LoggerService instance = LoggerService._();

  static const _logsApiKey = String.fromEnvironment(
    'LOGS_API_KEY',
    defaultValue: '',
  );

  final _uuid = const Uuid();
  String _traceId = const Uuid().v4();
  final List<Map<String, dynamic>> _buffer = [];
  Timer? _flushTimer;

  final Map<String, dynamic> _deviceInfo = <String, dynamic>{};

  /// Current trace id.
  String get traceId => _traceId;

  /// Sets a custom trace id.
  // ignore: use_setters_to_change_properties
  void setTraceId(String traceId) => _traceId = traceId;

  /// Generates a new trace id and returns it.
  String newTrace() => _traceId = _uuid.v4();

  /// Collects device info and starts the periodic flush timer.
  Future<void> init() async {
    await _collectDeviceInfo();
    _traceId = _uuid.v4();
    _flushTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) { flush(); },
    );
  }

  Future<void> _collectDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _deviceInfo['appVersion'] = packageInfo.version;

      if (Platform.isAndroid) {
        final android = await DeviceInfoPlugin().androidInfo;
        _deviceInfo['os'] = 'Android';
        _deviceInfo['model'] = android.model;
        _deviceInfo['version'] = android.version.release;
      } else if (Platform.isIOS) {
        final ios = await DeviceInfoPlugin().iosInfo;
        _deviceInfo['os'] = 'iOS';
        _deviceInfo['model'] = ios.utsname.machine;
        _deviceInfo['version'] = ios.systemVersion;
      } else {
        _deviceInfo['os'] = Platform.operatingSystem;
        _deviceInfo['model'] = '';
        _deviceInfo['version'] = '';
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('LoggerService device info collection failed: $e');
      }
      _deviceInfo['os'] = Platform.operatingSystem;
      _deviceInfo['model'] = '';
      _deviceInfo['version'] = '';
      _deviceInfo['appVersion'] = '';
    }
  }

  /// Logs a trace message.
  void trace(String message, {Object? data, String? traceId}) =>
      _add('trace', message, data: data, traceId: traceId);

  /// Logs a debug message.
  void debug(String message, {Object? data, String? traceId}) =>
      _add('debug', message, data: data, traceId: traceId);

  /// Logs an info message.
  void info(String message, {Object? data, String? traceId}) =>
      _add('info', message, data: data, traceId: traceId);

  /// Logs a warning message.
  void warning(String message, {Object? data, String? traceId}) =>
      _add('warning', message, data: data, traceId: traceId);

  /// Logs an error message and immediately flushes the buffer.
  void error(String message, {Object? data, String? traceId}) {
    _add('error', message, data: data, traceId: traceId);
    flush();
  }

  /// Logs a fatal message and immediately flushes the buffer.
  void fatal(String message, {Object? data, String? traceId}) {
    _add('fatal', message, data: data, traceId: traceId);
    flush();
  }

  void _add(
    String level,
    String message, {
    Object? data,
    String? traceId,
  }) {
    final entry = <String, dynamic>{
      'trace_id': traceId ?? _traceId,
      'level': level,
      'message': message,
      'data': data,
      'device_os': _deviceInfo['os'] as String?,
      'device_model': _deviceInfo['model'] as String?,
      'device_version': _deviceInfo['version'] as String?,
      'app_version': _deviceInfo['appVersion'] as String?,
      'user_id': Supabase.instance.client.auth.currentUser?.id,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _buffer.add(entry);
  }

  /// Sends buffered logs and clears the buffer.
  void flush() => unawaited(_flush());

  Future<void> _flush() async {
    if (_logsApiKey.isEmpty) {
      _buffer.clear();
      return;
    }

    if (_buffer.isEmpty) return;

    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    try {
      await Supabase.instance.client.functions.invoke(
        'logs',
        body: <String, dynamic>{'logs': batch},
        headers: <String, String>{'x-logs-key': _logsApiKey},
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('LoggerService flush failed: $e');
      }
    }
  }

  /// Stops the flush timer and flushes any remaining logs.
  Future<void> flushAndDispose() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _flush();
  }
}
