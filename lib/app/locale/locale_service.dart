import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    }
  }

  Future<void> setLocale(Locale value) async {
    if (locale.value == value) return;
    locale.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.languageCode);
  }
}
