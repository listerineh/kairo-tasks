import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../app/di/injection.dart';

/// Haptics paired with state changes (docs/redesign-plan.md §2.5).
///
/// Widgets call the intent (`selection`, `completed`, `celebrated`) rather
/// than a raw impact, so the mapping lives in one place. There is no heavy
/// impact on purpose.
@lazySingleton
class HapticsService {
  /// User preference; the toggle lands in Profile/Settings (Phase 6).
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  /// Pickers, segmented controls, chips, ticks while dragging.
  Future<void> selection() => _play(HapticFeedback.selectionClick);

  /// Completing a task.
  Future<void> completed() => _play(HapticFeedback.lightImpact);

  /// Streak celebration.
  Future<void> celebrated() => _play(HapticFeedback.mediumImpact);

  Future<void> _play(Future<void> Function() feedback) async {
    if (enabled.value) await feedback();
  }
}

/// The app's [HapticsService], or null where DI isn't configured (widget
/// and golden tests). Shared widgets use this so they render without setup.
HapticsService? get registeredHaptics =>
    getIt.isRegistered<HapticsService>() ? getIt<HapticsService>() : null;
