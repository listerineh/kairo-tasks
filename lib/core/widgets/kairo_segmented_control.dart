import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';
import '../services/haptics_service.dart';

/// iOS-style segmented control: the thumb slides to the selection with the
/// `snappy` spring and every change ticks a selection haptic.
class KairoSegmentedControl<T> extends StatelessWidget {
  const KairoSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Values and their labels, in display order.
  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  void _select(T value) {
    if (value == selected) return;
    final haptics = registeredHaptics;
    if (haptics != null) unawaited(haptics.selection());
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final values = segments.keys.toList();
    final index = values.indexOf(selected);
    final count = values.length;
    final x = count == 1 ? 0.0 : -1 + 2 * index / (count - 1);

    return ConstrainedBox(
      // 32 pt like iOS, inside a 44 pt tall touch area.
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.fill,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedAlign(
                    alignment: Alignment(x, 0),
                    duration: motion.duration(KairoSpring.snappy),
                    curve: motion.curve(KairoSpring.snappy),
                    child: FractionallySizedBox(
                      widthFactor: 1 / count,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceRaised,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final value in values)
                      Expanded(
                        child: _Segment(
                          label: segments[value]!,
                          selected: value == selected,
                          onTap: () => _select(value),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing8,
                vertical: AppSpacing.spacing4,
              ),
              // One line, never split mid-word: at large text sizes a label that
              // does not fit shrinks instead (like UISegmentedControl).
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: context.typography.footnote.copyWith(
                    color: colors.label,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
