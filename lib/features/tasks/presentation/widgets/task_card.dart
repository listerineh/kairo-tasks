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
          onToggleStatus();
        } else {
          onDismissed?.call();
        }
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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: colors.border, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Priority indicator bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: _priorityColor(colors),
                        borderRadius: BorderRadius.only(
                          topLeft:
                              const Radius.circular(AppSpacing.radiusMedium),
                          bottomLeft: task.dueDate == null
                              ? const Radius.circular(AppSpacing.radiusMedium)
                              : Radius.zero,
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppSpacing.spacing16),
                        child: Row(
                          children: [
                            // Task info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: context.textTheme.titleSmall
                                        ?.copyWith(
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
                                    const SizedBox(
                                      height: AppSpacing.spacing4,
                                    ),
                                    Text(
                                      task.description!,
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(
                                        color: isCompleted
                                            ? colors.textMuted
                                            : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (task.dueDate != null &&
                                      !isCompleted) ...[
                                    const SizedBox(
                                      height: AppSpacing.spacing8,
                                    ),
                                    _DueDateChip(
                                      dueDate: task.dueDate!,
                                      isOverdue: task.isOverdue,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.spacing12),
                            // Status circle
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
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
              // Time progress bar
              if (task.dueDate != null && !isCompleted)
                _TimeProgressBar(
                  startDate: task.startDate ?? task.createdAt,
                  dueDate: task.dueDate!,
                ),
            ],
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

class _TimeProgressBar extends StatelessWidget {
  const _TimeProgressBar({
    required this.startDate,
    required this.dueDate,
  });

  final DateTime startDate;
  final DateTime dueDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();

    final totalDuration = dueDate.difference(startDate).inMinutes;
    final elapsed = now.difference(startDate).inMinutes;

    // Clamp progress between 0 and 1
    final progress = totalDuration > 0
        ? (elapsed / totalDuration).clamp(0.0, 1.0)
        : 0.0;

    // Red when less than 10% time remaining
    final isUrgent = progress >= 0.9;
    final isOverdue = now.isAfter(dueDate);

    final barColor = isOverdue || isUrgent ? colors.urgent : colors.accent;

    return Container(
      height: 3,
      width: double.infinity,
      color: colors.surfaceSubtle,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(2),
              bottomRight: Radius.circular(2),
            ),
          ),
        ),
      ),
    );
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
    final difference = dueDate.difference(now);

    String label;
    if (difference.isNegative) {
      final overdue = -difference.inHours;
      if (overdue < 1) {
        label = '${-difference.inMinutes}m overdue';
      } else if (overdue < 24) {
        label = '${overdue}h overdue';
      } else {
        label = '${-difference.inDays}d overdue';
      }
    } else if (difference.inHours < 1) {
      label = '${difference.inMinutes}m left';
    } else if (difference.inHours < 24) {
      label = '${difference.inHours}h left';
    } else if (difference.inDays == 1) {
      label = 'Tomorrow';
    } else if (difference.inDays < 7) {
      label = 'In ${difference.inDays} days';
    } else {
      label = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }

    // Show time if due within 24h
    if (!difference.isNegative && difference.inHours < 24) {
      final hour = dueDate.hour;
      final minute = dueDate.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      label += ' ($displayHour:$minute $period)';
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
