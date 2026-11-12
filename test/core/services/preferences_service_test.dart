import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/core/services/haptics_service.dart';
import 'package:kairotasks/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults follow the system', () async {
    final prefs = PreferencesService(HapticsService());
    await prefs.load();
    const system = MediaQueryData(textScaler: TextScaler.linear(1.3));
    final applied = prefs.apply(system);
    expect(applied.disableAnimations, isFalse);
    expect(applied.textScaler, const TextScaler.linear(1.3));
    expect(prefs.haptics.value, isTrue);
  });

  test('settings apply on top of the system and persist', () async {
    final prefs = PreferencesService(HapticsService());
    await prefs.setReduceMotion(value: true);
    await prefs.setHaptics(value: false);
    await prefs.setTextScale(1.5);

    final reloaded = PreferencesService(HapticsService());
    await reloaded.load();
    final applied = reloaded.apply(const MediaQueryData());
    expect(applied.disableAnimations, isTrue);
    expect(applied.textScaler, const TextScaler.linear(1.5));
    expect(reloaded.haptics.value, isFalse);

    await reloaded.setTextScale(null);
    expect(
      reloaded.apply(const MediaQueryData()).textScaler,
      TextScaler.noScaling,
    );
  });

  test('the OS reduce-motion switch always wins', () async {
    final prefs = PreferencesService(HapticsService());
    await prefs.load();
    final applied = prefs.apply(const MediaQueryData(disableAnimations: true));
    expect(applied.disableAnimations, isTrue);
  });
}
