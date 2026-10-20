import 'package:flutter/cupertino.dart';

import '../../app/theme/kairo_colors.dart';
import '../../features/tasks/domain/entities/task_entity.dart';
import '../extensions/context_extensions.dart';

/// Priority as symbol + label, never color alone (docs/redesign-plan.md §2.1).
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    required this.priority,
    this.showLabel = true,
    super.key,
  });

  final TaskPriority priority;

  /// Symbol only (rows with little room); the label stays in semantics.
  final bool showLabel;

  static Color colorFor(TaskPriority priority, KairoColors colors) =>
      switch (priority) {
        TaskPriority.urgent => colors.priorityUrgent,
        TaskPriority.high => colors.priorityHigh,
        TaskPriority.medium => colors.priorityMedium,
        TaskPriority.low => colors.priorityLow,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = colorFor(priority, context.appColors);
    final style = context.typography.footnote.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );
    final label = switch (priority) {
      TaskPriority.urgent => l10n.urgent,
      TaskPriority.high => l10n.high,
      TaskPriority.medium => l10n.medium,
      TaskPriority.low => l10n.low,
    };
    final iconSize = MediaQuery.textScalerOf(context).scale(14);

    return Semantics(
      label: '${l10n.priority}: $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrioritySymbol(priority: priority, color: color, size: iconSize),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(label, style: style),
          ],
        ],
      ),
    );
  }
}

class _PrioritySymbol extends StatelessWidget {
  const _PrioritySymbol({
    required this.priority,
    required this.color,
    required this.size,
  });

  final TaskPriority priority;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    Icon icon(IconData data) => Icon(data, size: size, color: color);

    return switch (priority) {
      // CupertinoIcons has no exclamationmark.2; two marks drawn tight.
      TaskPriority.urgent => SizedBox(
        width: size * 1.1,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -size * 0.2,
              child: icon(CupertinoIcons.exclamationmark),
            ),
            Positioned(
              left: size * 0.25,
              child: icon(CupertinoIcons.exclamationmark),
            ),
          ],
        ),
      ),
      TaskPriority.high => icon(CupertinoIcons.exclamationmark),
      TaskPriority.medium => icon(CupertinoIcons.minus),
      TaskPriority.low => icon(CupertinoIcons.arrow_down),
    };
  }
}
