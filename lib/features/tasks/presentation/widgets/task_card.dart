import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/task_entity.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.onToggleStatus,
    this.onDismissed,
    this.onTap,
    super.key,
  });

  final TaskEntity task;
  final VoidCallback onToggleStatus;
  final VoidCallback? onDismissed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCompleted = task.status == TaskStatus.completed;

    return Dismissible(
      key: ValueKey(task.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right → toggle complete
          onToggleStatus();
        } else {
          // Swipe left → delete
          onDismissed?.call();
        }
        // Always return false - realtime stream handles list updates
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.spacing24),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Icon(
          isCompleted ? Icons.undo : Icons.check_circle_outline,
          color: colors.accent,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.spacing24),
        decoration: BoxDecoration(
          color: colors.urgent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Icon(Icons.delete_outline, color: colors.urgent),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: colors.border, width: 0.5),
          ),
          child: IntrinsicHeight(
          child: Row(
            children: [
              // Priority indicator bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _priorityColor(colors),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusMedium),
                    bottomLeft: Radius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.spacing16),
                  child: Row(
                    children: [
                      // Task info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style:
                                  context.textTheme.titleSmall?.copyWith(
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted
                                    ? colors.textMuted
                                    : colors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (task.description != null) ...[
                              const SizedBox(height: AppSpacing.spacing4),
                              Text(
                                task.description!,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: isCompleted
                                      ? colors.textMuted
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (task.dueDate != null) ...[
                              const SizedBox(height: AppSpacing.spacing8),
                              _DueDateChip(
                                dueDate: task.dueDate!,
                                isOverdue: task.isOverdue,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      // Status circle (right side, visual only)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? colors.accent
                              : Colors.transparent,
                          border: Border.all(
                            color: isCompleted
                                ? colors.accent
                                : colors.border,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
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

  Color _priorityColor(AppColorScheme colors) {
    switch (task.priority) {
      case TaskPriority.urgent:
        return colors.urgent;
      case TaskPriority.high:
        return colors.high;
      case TaskPriority.medium:
        return colors.medium;
      case TaskPriority.low:
        return colors.low;
    }
  }
}

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({
    required this.dueDate,
    required this.isOverdue,
  });

  final DateTime dueDate;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    String label;
    if (difference == 0) {
      label = 'Today';
    } else if (difference == 1) {
      label = 'Tomorrow';
    } else if (difference < 0) {
      label = '${-difference}d overdue';
    } else if (difference < 7) {
      label = 'In $difference days';
    } else {
      label =
          '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: isOverdue ? colors.urgent : colors.textMuted,
        ),
        const SizedBox(width: AppSpacing.spacing4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: isOverdue ? colors.urgent : colors.textMuted,
          ),
        ),
      ],
    );
  }
}
