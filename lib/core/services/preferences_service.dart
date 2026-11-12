import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/di/injection.dart';
import 'haptics_service.dart';

/// In-app accessibility preferences (Yo › Accesibilidad), stored on the
/// device. They apply on top of the system settings: reduce motion can only
/// add to the OS switch, and a text size replaces the system scale.
@lazySingleton
class PreferencesService {
  PreferencesService(this._haptics);

  final HapticsService _haptics;

  /// Forces reduced motion even when the OS setting is off.
  final ValueNotifier<bool> reduceMotion = ValueNotifier<bool>(false);

  /// A fixed text scale, or null to follow the system.
  final ValueNotifier<double?> textScale = ValueNotifier<double?>(null);

  /// Haptics live in [HapticsService]; this is the same notifier.
  ValueNotifier<bool> get haptics => _haptics.enabled;

  /// The steps the text size slider offers.
  static const textScales = [0.85, 1.0, 1.15, 1.3, 1.5, 1.75, 2.0];

  static const _kReduceMotion = 'pref_reduce_motion';
  static const _kHaptics = 'pref_haptics';
  static const _kTextScale = 'pref_text_scale';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    reduceMotion.value = prefs.getBool(_kReduceMotion) ?? false;
    haptics.value = prefs.getBool(_kHaptics) ?? true;
    textScale.value = prefs.getDouble(_kTextScale);
  }

  Future<void> setReduceMotion({required bool value}) async {
    reduceMotion.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReduceMotion, value);
  }

  Future<void> setHaptics({required bool value}) async {
    haptics.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHaptics, value);
  }

  Future<void> setTextScale(double? value) async {
    textScale.value = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_kTextScale);
    } else {
      await prefs.setDouble(_kTextScale, value);
    }
  }

  /// [data] with these preferences applied.
  MediaQueryData apply(MediaQueryData data) {
    final scale = textScale.value;
    return data.copyWith(
      disableAnimations: data.disableAnimations || reduceMotion.value,
      textScaler: scale == null ? data.textScaler : TextScaler.linear(scale),
    );
  }
}

/// The app's [PreferencesService], or null where DI isn't configured.
PreferencesService? get registeredPreferences =>
    getIt.isRegistered<PreferencesService>()
    ? getIt<PreferencesService>()
    : null;
