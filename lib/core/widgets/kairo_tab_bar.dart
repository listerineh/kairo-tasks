import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';
import '../services/haptics_service.dart';

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

/// Translucent tab bar: blurred surface at 80%, hairline on top, labels
/// always visible. Use with `Scaffold(extendBody: true)` so content scrolls
/// underneath.
class KairoTabBar extends StatelessWidget {
  const KairoTabBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<KairoTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

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

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: colors.separator,
                width: AppSpacing.hairline,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            // Tab labels cap their growth like iOS; past this size the
            // system relies on the large content viewer instead.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 49),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _TabButton(
                          item: items[i],
                          selected: i == currentIndex,
                          index: i,
                          count: items.length,
                          onTap: () => _select(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
    final color = selected ? colors.tint : colors.labelSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      hint: '${index + 1} / $count',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: motion.duration(KairoSpring.snappy),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  key: ValueKey(selected),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.caption1.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
