import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/haptics_service.dart';
import 'calendar_colors.dart';

/// The five calendar tones as round swatches; the selected one has a ring
/// and a check. Used for my color (Yo) and a friend's color (Juntos).
class TonePicker extends StatelessWidget {
  const TonePicker({required this.selected, required this.onPick, super.key});

  final CalendarTone? selected;
  final ValueChanged<CalendarTone> onPick;

  /// The hex a tone is stored as (`profiles.color`, `friendships.*_color`).
  static String hexOf(CalendarTone tone) {
    final rgb = tone.dot.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final tone in CalendarTone.all)
          _Swatch(
            tone: tone,
            selected: tone == selected,
            onTap: () {
              unawaited(registeredHaptics?.selection());
              onPick(tone);
            },
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final CalendarTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = context.appColors.label;
    return Semantics(
      button: true,
      selected: selected,
      label: tone.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 52,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone.dot,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? label : Colors.transparent,
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: selected
                  ? const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 20,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
