import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';
import '../services/haptics_service.dart';
import 'pressable.dart';

/// Selectable capsule ("Hoy", "Mañana", "Este finde"): a hairline outline
/// when off, solid `ink` when selected. Colors cross-fade with the `snappy`
/// spring and selecting ticks a haptic.
class KairoChip extends StatelessWidget {
  const KairoChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.leading,
    super.key,
  });

  final String label;
  final bool selected;

  /// Null disables the chip.
  final VoidCallback? onSelected;

  /// A small dot or avatar before the label.
  final Widget? leading;

  void _tap() {
    final haptics = registeredHaptics;
    if (haptics != null) unawaited(haptics.selection());
    onSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final foreground = selected ? colors.onInk : colors.label;

    return Semantics(
      button: true,
      selected: selected,
      enabled: onSelected != null,
      child: Pressable(
        onPressed: onSelected == null ? null : _tap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: AnimatedContainer(
            duration: motion.duration(KairoSpring.snappy),
            curve: motion.curve(KairoSpring.snappy),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing16,
              vertical: AppSpacing.spacing8,
            ),
            decoration: ShapeDecoration(
              color: selected ? colors.ink : colors.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected ? colors.ink : colors.separator,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.spacing8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: context.typography.callout.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
