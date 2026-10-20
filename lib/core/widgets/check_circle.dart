import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';
import '../services/haptics_service.dart';

/// Round completion toggle (Reminders style) with a 44 pt touch target.
///
/// Checking springs the mark in (`snappy`) and plays the "completed" haptic;
/// unchecking plays a selection tick.
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.color,
    super.key,
  });

  final bool value;

  /// Null shows the circle read-only.
  final ValueChanged<bool>? onChanged;

  /// What is being completed, e.g. the task title.
  final String semanticLabel;

  /// Fill when checked; defaults to the tint.
  final Color? color;

  static const double _diameter = 24;

  void _toggle() {
    final next = !value;
    final haptics = registeredHaptics;
    if (haptics != null) {
      unawaited(next ? haptics.completed() : haptics.selection());
    }
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final fill = color ?? colors.tint;

    return Semantics(
      checked: value,
      label: semanticLabel,
      onTap: onChanged == null ? null : _toggle,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : _toggle,
        child: SizedBox.square(
          dimension: AppSpacing.minTouchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: motion.duration(KairoSpring.snappy),
              curve: Curves.easeOut,
              width: _diameter,
              height: _diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? fill : Colors.transparent,
                border: Border.all(
                  color: value ? fill : colors.labelSecondary,
                  width: 1.5,
                ),
              ),
              child: AnimatedScale(
                scale: value ? 1 : 0,
                duration: motion.duration(KairoSpring.snappy),
                curve: motion.curve(KairoSpring.snappy),
                child: Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 16,
                  color: colors.onTint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
