import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/in_app_notification.dart';

class NotificationStore {
  NotificationStore._();

  static final NotificationStore instance = NotificationStore._();

  final ValueNotifier<List<InAppNotification>> notifications =
      ValueNotifier<List<InAppNotification>>([]);

  static const _key = 'in_app_notifications';
  final _uuid = const Uuid();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      notifications.value = [];
      return;
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => InAppNotification.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifications.value = list;
    } catch (_) {
      notifications.value = [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      notifications.value.map((n) => n.toJson()).toList(),
    );
    await prefs.setString(_key, encoded);
  }

  Future<void> add({
    required String title,
    required String body,
    required String type,
    String? id,
  }) async {
    final existing = id != null &&
        notifications.value.any((n) => n.id == id);
    if (existing) return;

    final n = InAppNotification(
      id: id ?? _uuid.v4(),
      title: title,
      body: body,
      type: type,
      read: false,
      createdAt: DateTime.now(),
    );
    notifications.value = [n, ...notifications.value];
    await _save();
  }

  Future<void> markRead(String id) async {
    notifications.value = notifications.value.map((n) {
      return n.id == id ? n.copyWith(read: true) : n;
    }).toList();
    await _save();
  }

  Future<void> markAllRead() async {
    notifications.value = notifications.value
        .map((n) => n.copyWith(read: true))
        .toList();
    await _save();
  }

  Future<void> clear() async {
    notifications.value = [];
    await _save();
  }
}
