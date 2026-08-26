import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';

/// 2-day view (like Google Calendar's "week" on mobile).
/// Shows the selected date and the next day side by side.
class WeekView extends StatelessWidget {
  const WeekView({
    required this.selectedDate,
    required this.tasks,
    required this.onDateTap,
    required this.onTaskTap,
    super.key,
  });

  final DateTime selectedDate;
  final List<TaskEntity> tasks;
  final void Function(DateTime) onDateTap;
  final void Function(TaskEntity) onTaskTap;

  static const _hourHeight = 60.0;
  static const _startHour = 0;
  static const _endHour = 24;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final day1 = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final day2 = day1.add(const Duration(days: 1));

    return Column(
      children: [
        // Day column headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 44),
              _DayColumnHeader(
                date: day1,
                isToday: _isSameDay(day1, now),
                onTap: () => onDateTap(day1),
              ),
              Container(width: 1, height: 36, color: colors.border.withValues(alpha: 0.3)),
              _DayColumnHeader(
                date: day2,
                isToday: _isSameDay(day2, now),
                onTap: () => onDateTap(day2),
              ),
            ],
          ),
        ),

        // Timeline
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: _hourHeight * (_endHour - _startHour),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hour labels
                  SizedBox(
                    width: 44,
                    child: Stack(
                      children: List.generate(
                        _endHour - _startHour,
                        (i) {
                          final hour = _startHour + i;
                          return Positioned(
                            top: i * _hourHeight - 7,
                            left: 0,
                            right: 4,
                            child: Text(
                              _formatHour(hour),
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textMuted,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Day 1 column
                  Expanded(
                    child: _DayColumn(
                      date: day1,
                      tasks: _tasksForDate(day1),
                      isToday: _isSameDay(day1, now),
                      now: now,
                      onTaskTap: onTaskTap,
                    ),
                  ),

                  // Separator
                  Container(
                    width: 1,
                    height: _hourHeight * (_endHour - _startHour),
                    color: colors.border.withValues(alpha: 0.3),
                  ),

                  // Day 2 column
                  Expanded(
                    child: _DayColumn(
                      date: day2,
                      tasks: _tasksForDate(day2),
                      isToday: _isSameDay(day2, now),
                      now: now,
                      onTaskTap: onTaskTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<TaskEntity> _tasksForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return tasks.where((t) {
      final start = t.startDate ?? t.dueDate;
      if (start == null) return false;
      final end = t.dueDate ?? start;
      return start.isBefore(dayEnd) && end.isAfter(dayStart);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class _DayColumnHeader extends StatelessWidget {
  const _DayColumnHeader({
    required this.date,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onTap;

  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Text(
            '${_dayNames[date.weekday % 7]} – ${_monthNames[date.month - 1]} ${date.day}',
            style: context.textTheme.labelMedium?.copyWith(
              color: isToday ? colors.accent : colors.textSecondary,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.tasks,
    required this.isToday,
    required this.now,
    required this.onTaskTap,
  });

  final DateTime date;
  final List<TaskEntity> tasks;
  final bool isToday;
  final DateTime now;
  final void Function(TaskEntity) onTaskTap;

  static const _hourHeight = WeekView._hourHeight;
  static const _startHour = WeekView._startHour;
  static const _endHour = WeekView._endHour;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Stack(
      children: [
        // Hour grid lines
        ...List.generate(
          _endHour - _startHour,
          (i) => Positioned(
            top: i * _hourHeight,
            left: 0,
            right: 0,
            child: Divider(
              height: 1,
              color: colors.border.withValues(alpha: 0.2),
            ),
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
        ..._positionedTasks(context, colors),
      ],
    );
  }

  List<Widget> _positionedTasks(BuildContext context, AppColorScheme colors) {
    return tasks.where((t) => t.dueDate != null).map((task) {
      final startTime = task.startDate ??
          task.dueDate!.subtract(const Duration(hours: 1));
      final top = _timeToOffset(startTime);
      final durationMinutes =
          task.dueDate!.difference(startTime).inMinutes.clamp(20, 480);
      final height = (durationMinutes * _hourHeight / 60).clamp(24.0, _hourHeight * 6);
      final taskColor = _taskColor(task, colors);
      final priorityColor = _priorityColor(task, colors);
      final isCompleted = task.status == TaskStatus.completed;

      return Positioned(
        top: top.clamp(0, _hourHeight * (_endHour - _startHour) - height),
        left: 2,
        right: 2,
        height: height,
        child: GestureDetector(
          onTap: () => onTaskTap(task),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: taskColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border(
                left: BorderSide(color: taskColor, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 3, right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: priorityColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        task.title,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: isCompleted
                              ? colors.textMuted
                              : colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (height > 36 && task.startDate != null)
                  Text(
                    '${_formatTime(startTime)} – ${_formatTime(task.dueDate!)}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  double _timeToOffset(DateTime time) {
    return (time.hour - _startHour) * _hourHeight +
        time.minute * _hourHeight / 60;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

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
