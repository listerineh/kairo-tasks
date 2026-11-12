import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sync/pending_op.dart';

/// The device copy of a user's tasks (the last server rows, as fetched) and
/// the outbox of changes not confirmed yet. Keys are per user, so another
/// account on the same device never sees them.
abstract class TaskLocalStore {
  /// The last rows fetched for [userId], or null if there are none yet.
  Future<List<Map<String, dynamic>>?> readRows(String userId);

  Future<void> writeRows(String userId, List<Map<String, dynamic>> rows);

  Future<List<PendingOp>> readOutbox(String userId);

  Future<void> writeOutbox(String userId, List<PendingOp> ops);

  /// Forgets everything stored for [userId] (sign out).
  Future<void> clear(String userId);
}

@LazySingleton(as: TaskLocalStore)
class PrefsTaskLocalStore implements TaskLocalStore {
  static String _rowsKey(String userId) => 'tasks_cache_v1_$userId';
  static String _outboxKey(String userId) => 'tasks_outbox_v1_$userId';

  @override
  Future<List<Map<String, dynamic>>?> readRows(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rowsKey(userId));
    if (raw == null) return null;
    try {
      return [
        for (final r in jsonDecode(raw) as List)
          Map<String, dynamic>.from(r as Map),
      ];
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeRows(String userId, List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rowsKey(userId), jsonEncode(rows));
  }

  @override
  Future<List<PendingOp>> readOutbox(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_outboxKey(userId));
    if (raw == null) return const [];
    try {
      return [
        for (final o in jsonDecode(raw) as List)
          PendingOp.fromJson(Map<String, dynamic>.from(o as Map)),
      ];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> writeOutbox(String userId, List<PendingOp> ops) async {
    final prefs = await SharedPreferences.getInstance();
    if (ops.isEmpty) {
      await prefs.remove(_outboxKey(userId));
    } else {
      await prefs.setString(
        _outboxKey(userId),
        jsonEncode([for (final o in ops) o.toJson()]),
      );
    }
  }

  @override
  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rowsKey(userId));
    await prefs.remove(_outboxKey(userId));
  }
}
