import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';

class WeekView extends StatelessWidget {
  const WeekView({
    required this.startOfWeek,
    required this.tasks,
    required this.onDateTap,
    required this.onTaskTap,
    super.key,
  });

  final DateTime startOfWeek;
  final List<TaskEntity> tasks;
  final void Function(DateTime) onDateTap;
  final void Function(TaskEntity) onTaskTap;

  static const _hourHeight = 50.0;
  static const _startHour = 6;
  static const _endHour = 23;
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();

    return Column(
      children: [
        // Day headers
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Row(
            children: List.generate(7, (i) {
              final date = startOfWeek.add(Duration(days: i));
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDateTap(date),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.spacing8,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _dayNames[i],
                          style: context.textTheme.labelSmall?.copyWith(
                            color: isToday
                                ? colors.accent
                                : colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday ? colors.accent : null,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style:
                                  context.textTheme.labelMedium?.copyWith(
                                color: isToday
                                    ? Colors.white
                                    : colors.textPrimary,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Divider(height: 1, color: colors.border),

        // Time grid
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: _hourHeight * (_endHour - _startHour),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hour labels
                  SizedBox(
                    width: 36,
                    child: Stack(
                      children: List.generate(
                        _endHour - _startHour,
                        (i) {
                          final hour = _startHour + i;
                          return Positioned(
                            top: i * _hourHeight - 6,
                            left: 0,
                            right: 4,
                            child: Text(
                              _formatHour(hour),
                              style:
                                  context.textTheme.labelSmall?.copyWith(
                                color: colors.textMuted,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Day columns
                  ...List.generate(7, (dayIndex) {
                    final date =
                        startOfWeek.add(Duration(days: dayIndex));
                    final dayTasks = _tasksForDate(date);
                    final isToday = date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;

                    return Expanded(
                      child: Stack(
                        children: [
                          // Grid lines
                          ...List.generate(
                            _endHour - _startHour,
                            (i) => Positioned(
                              top: i * _hourHeight,
                              left: 0,
                              right: 0,
                              child: Divider(
                                height: 1,
                                color:
                                    colors.border.withValues(alpha: 0.3),
                              ),
                            ),
                          ),

                          // Vertical separator
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            child: VerticalDivider(
                              width: 1,
                              color:
                                  colors.border.withValues(alpha: 0.3),
                            ),
                          ),

                          // Current time line
                          if (isToday)
                            Positioned(
                              top: _timeToOffset(now),
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                color: colors.urgent,
                              ),
                            ),

                          // Task blocks
                          ...dayTasks
                              .where((t) => t.dueDate != null)
                              .map(
                                (task) => _buildTaskBlock(
                                  context,
                                  task,
                                  colors,
                                ),
                              ),
                        ],
                      ),
                    );
                  }),
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
    final startHour = (dueDate.hour - 1).clamp(_startHour, _endHour - 1);
    final top = (startHour - _startHour) * _hourHeight +
        dueDate.minute * _hourHeight / 60;
    final taskColor = _taskColor(task, colors);
    final isCompleted = task.status == TaskStatus.completed;

    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: _hourHeight - 2,
      child: GestureDetector(
        onTap: () => onTaskTap(task),
        child: Container(
          margin: const EdgeInsets.all(1),
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: taskColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              left: BorderSide(color: taskColor, width: 2),
            ),
          ),
          child: Text(
            task.title,
            style: context.textTheme.labelSmall?.copyWith(
              color: isCompleted ? colors.textMuted : colors.textPrimary,
              fontSize: 10,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  List<TaskEntity> _tasksForDate(DateTime date) {
    return tasks.where((t) {
      if (t.dueDate != null) {
        return t.dueDate!.year == date.year &&
            t.dueDate!.month == date.month &&
            t.dueDate!.day == date.day;
      }
      return false;
    }).toList();
  }

  double _timeToOffset(DateTime time) {
    return (time.hour - _startHour) * _hourHeight +
        time.minute * _hourHeight / 60;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12a';
    if (hour < 12) return '${hour}a';
    if (hour == 12) return '12p';
    return '${hour - 12}p';
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
