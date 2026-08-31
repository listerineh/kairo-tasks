import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocaleService {
  LocaleService._();
  static final LocaleService _instance = LocaleService._();
  static LocaleService get instance => _instance;

  final ValueNotifier<Locale> locale =
      ValueNotifier<Locale>(const Locale('es'));

  static const _key = 'app_locale';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      locale.value = Locale(saved);
      return;
    }

    // Fallback to the language saved in the user's profile when available.
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final row = await client
            .from('profiles')
            .select('language')
            .eq('id', user.id)
            .maybeSingle();
        final raw = (row?['language'] as String?)?.toLowerCase();
        if (raw != null && (raw == 'en' || raw == 'es')) {
          locale.value = Locale(raw);
          await prefs.setString(_key, raw);
          return;
        }
      }
    } catch (_) {
      // Supabase may not be initialized yet; keep default.
    }
  }

  Future<void> setLocale(Locale value) async {
    if (locale.value == value) return;
    locale.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.languageCode);

    // Persist to the profile so the server can localize push notifications.
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client
            .from('profiles')
          .update({'language': value.languageCode})
          .eq('id', user.id);
      }
    } catch (_) {
      // Ignore DB errors for language update.
    }
  }
}
