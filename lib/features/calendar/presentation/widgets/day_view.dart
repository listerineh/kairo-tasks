import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';

class DayView extends StatelessWidget {
  const DayView({
    required this.date,
    required this.tasks,
    required this.onTaskTap,
    super.key,
  });

  final DateTime date;
  final List<TaskEntity> tasks;
  final void Function(TaskEntity) onTaskTap;

  static const _hourHeight = 60.0;
  static const _startHour = 0;
  static const _endHour = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppSpacing.spacing8),
      child: SizedBox(
        height: _hourHeight * (_endHour - _startHour),
        child: Stack(
          children: [
            // Hour grid lines
            ...List.generate(_endHour - _startHour, (i) {
              final hour = _startHour + i;
              return Positioned(
                top: i * _hourHeight,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        _formatHour(hour),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        height: 1,
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Current time indicator
            if (isToday)
              Positioned(
                top: _timeToOffset(now),
                left: 44,
                right: 0,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.urgent,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: colors.urgent,
                      ),
                    ),
                  ],
                ),
              ),

            // Task blocks
            ...tasks
                .where((t) => t.dueDate != null)
                .map((task) => _buildTaskBlock(context, task, colors)),

            // All-day / no-time tasks at the top
            if (tasks.where((t) => t.dueDate == null).isNotEmpty)
              Positioned(
                top: 0,
                left: 52,
                right: AppSpacing.spacing8,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing8),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: tasks
                        .where((t) => t.dueDate == null)
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                            ),
                            child: Text(
                              t.title,
                              style:
                                  context.textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskBlock(
    BuildContext context,
    TaskEntity task,
    AppColorScheme colors,
  ) {
    final dueDate = task.dueDate!;
    final startTime = task.startDate ?? dueDate.subtract(const Duration(hours: 1));
    final top =
        (startTime.hour - _startHour) * _hourHeight + startTime.minute * _hourHeight / 60;
    // Calculate block height from duration
    final durationMinutes = dueDate.difference(startTime).inMinutes.clamp(30, 480);
    final blockHeight = durationMinutes * _hourHeight / 60;

    final taskColor = _taskColor(task, colors);
    final isCompleted = task.status == TaskStatus.completed;

    return Positioned(
      top: top.clamp(0, _hourHeight * (_endHour - _startHour) - blockHeight),
      left: 52,
      right: AppSpacing.spacing8,
      height: blockHeight,
      child: GestureDetector(
        onTap: () => onTaskTap(task),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing12,
            vertical: AppSpacing.spacing8,
          ),
          decoration: BoxDecoration(
            color: taskColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            border: Border(
              left: BorderSide(color: taskColor, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task.title,
                style: context.textTheme.labelMedium?.copyWith(
                  color: isCompleted ? colors.textMuted : colors.textPrimary,
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  task.description!,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _timeToOffset(DateTime time) {
    return (time.hour - _startHour) * _hourHeight +
        time.minute * _hourHeight / 60;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  Color _taskColor(TaskEntity task, AppColorScheme colors) {
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
