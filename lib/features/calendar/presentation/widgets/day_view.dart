import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import 'shared_task_avatars.dart';

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
    final isToday = _isSameDay(date, now);

    // Separate all-day (no time) vs timed tasks
    final timedTasks = tasks.where((t) => t.dueDate != null).toList();
    final allDayTasks = tasks.where((t) => t.dueDate == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All-day section
        if (allDayTasks.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(52, 4, 8, 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: allDayTasks
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _taskColor(t, colors).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.title,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // Timeline
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              height: _hourHeight * (_endHour - _startHour),
              child: Stack(
                children: [
                  // Hour grid
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
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                _formatHour(hour),
                                style:
                                    context.textTheme.labelSmall?.copyWith(
                                  color: colors.textMuted,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              height: 1,
                              color: colors.border.withValues(alpha: 0.3),
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
                            width: 10,
                            height: 10,
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
                  ...timedTasks.map(
                    (task) => _buildTaskBlock(context, task, colors),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskBlock(
    BuildContext context,
    TaskEntity task,
    AppColorScheme colors,
  ) {
    final dueDate = task.dueDate!;
    final startTime =
        task.startDate ?? dueDate.subtract(const Duration(hours: 1));
    final top = _timeToOffset(startTime);
    final durationMinutes =
        dueDate.difference(startTime).inMinutes.clamp(20, 480);
    final blockHeight = (durationMinutes * _hourHeight / 60).clamp(28.0, _hourHeight * 6);
    final taskColor = _taskColor(task, colors);
    final priorityColor = _priorityColor(task, colors);
    final isCompleted = task.status == TaskStatus.completed;

    return Positioned(
      top: top.clamp(0, _hourHeight * (_endHour - _startHour) - blockHeight),
      left: 52,
      right: 8,
      height: blockHeight,
      child: GestureDetector(
        onTap: () => onTaskTap(task),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: taskColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(color: taskColor, width: 4),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: isCompleted
                            ? colors.textMuted
                            : colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (blockHeight > 40) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${_formatTime(startTime)} – ${_formatTime(dueDate)}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (blockHeight > 60 && task.description != null) ...[
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          task.description!,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textMuted,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 6,
                left: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: priorityColor,
                  ),
                ),
              ),
              if (task.sharedWith.isNotEmpty)
                Positioned(
                  bottom: 6,
                  right: 12,
                  child: SharedTaskAvatars(
                    sharedWith: task.sharedWith,
                    radius: 9,
                  ),
                ),
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

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _priorityColor(TaskEntity task, AppColorScheme colors) {
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

  Color _taskColor(TaskEntity task, AppColorScheme colors) {
    if (task.color != null && task.color!.isNotEmpty) {
      try {
        return Color(int.parse(task.color!.replaceFirst('#', '0xFF')));
      } catch (_) {
        // fall through to priority color
      }
    }
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
