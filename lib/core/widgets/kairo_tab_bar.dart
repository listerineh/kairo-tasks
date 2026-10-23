import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';
import '../services/haptics_service.dart';
import 'pressable.dart';

class KairoTabItem {
  const KairoTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  /// Outline symbol for the unselected tab.
  final IconData icon;

  /// Filled symbol for the selected tab.
  final IconData activeIcon;
  final String label;
}

/// Floating tab bar (docs/design.md § Navigation): an `ink` capsule above
/// the content. The selected tab grows into a pill with its label in lime;
/// the others show their icon only. With [onCreate], a lime ＋ sits in the
/// middle.
///
/// Use with `Scaffold(extendBody: true)` so content scrolls underneath, and
/// leave [contentPadding] of bottom space in scroll views.
class KairoTabBar extends StatelessWidget {
  const KairoTabBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.onCreate,
    this.createLabel,
    super.key,
  });

  final List<KairoTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Shows the center ＋ button.
  final VoidCallback? onCreate;

  /// Accessibility label for the ＋ button.
  final String? createLabel;

  static const double height = 64;
  static const double sideMargin = 18;

  /// Bottom space scroll views leave so the last item clears the bar.
  static double contentPadding(BuildContext context) =>
      height + _bottomMargin(context) + AppSpacing.spacing24;

  static double _bottomMargin(BuildContext context) =>
      math.max(MediaQuery.viewPaddingOf(context).bottom - 8, 16);

  void _select(int index) {
    if (index != currentIndex) {
      final haptics = registeredHaptics;
      if (haptics != null) unawaited(haptics.selection());
    }
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final middle = (items.length / 2).ceil();

    Widget tab(int i) => _TabButton(
      item: items[i],
      selected: i == currentIndex,
      index: i,
      count: items.length,
      onTap: () => _select(i),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sideMargin,
        0,
        sideMargin,
        _bottomMargin(context),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing8),
          decoration: ShapeDecoration(
            color: colors.ink,
            shape: const StadiumBorder(),
            shadows: const [
              BoxShadow(
                color: Color(0x3D121417),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < middle; i++) tab(i),
              if (onCreate != null)
                _CreateButton(onPressed: onCreate!, label: createLabel),
              for (var i = middle; i < items.length; i++) tab(i),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.index,
    required this.count,
    required this.onTap,
  });

  final KairoTabItem item;
  final bool selected;
  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final color = selected ? colors.lime : colors.onInkSecondary;
    final duration = motion.duration(KairoSpring.smooth);
    final curve = motion.curve(KairoSpring.smooth);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      hint: '${index + 1} / $count',
      excludeSemantics: true,
      child: Pressable(
        onPressed: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          height: 48,
          constraints: const BoxConstraints(minWidth: 48),
          padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 0),
          decoration: ShapeDecoration(
            color: selected
                ? Color.alphaBlend(
                    colors.onInk.withValues(alpha: 0.1),
                    colors.ink,
                  )
                : colors.ink.withValues(alpha: 0),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                color: color,
                size: 22,
              ),
              AnimatedSize(
                duration: duration,
                curve: curve,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: context.typography.footnote.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final button = Pressable(
      onPressed: onPressed,
      pressedScale: 0.9,
      child: Container(
        width: 48,
        height: 48,
        decoration: ShapeDecoration(
          color: colors.lime,
          shape: const CircleBorder(),
        ),
        child: Icon(CupertinoIcons.add, color: colors.onLime, size: 24),
      ),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: label == null
          ? button
          : Tooltip(message: label, excludeFromSemantics: true, child: button),
    );
  }
}
