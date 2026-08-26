import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';

/// Month view showing task title previews inside each day cell,
/// similar to Google Calendar's month view.
class MonthView extends StatelessWidget {
  const MonthView({
    required this.month,
    required this.tasks,
    required this.selectedDate,
    required this.onDateTap,
    super.key,
  });

  final DateTime month;
  final List<TaskEntity> tasks;
  final DateTime selectedDate;
  final void Function(DateTime) onDateTap;

  static const _dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();

    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Sunday = 0 based offset
    final startWeekday = firstOfMonth.weekday % 7;
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // Day name headers
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
          ),
          child: Row(
            children: _dayNames
                .map(
                  (name) => Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          name,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // Weeks (fills remaining height)
        Expanded(
          child: Column(
            children: List.generate(rows, (row) {
              return Expanded(
                child: _WeekRow(
                  row: row,
                  startWeekday: startWeekday,
                  daysInMonth: daysInMonth,
                  month: month,
                  now: now,
                  selectedDate: selectedDate,
                  tasks: tasks,
                  onDateTap: onDateTap,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.row,
    required this.startWeekday,
    required this.daysInMonth,
    required this.month,
    required this.now,
    required this.selectedDate,
    required this.tasks,
    required this.onDateTap,
  });

  final int row;
  final int startWeekday;
  final int daysInMonth;
  final DateTime month;
  final DateTime now;
  final DateTime selectedDate;
  final List<TaskEntity> tasks;
  final void Function(DateTime) onDateTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(7, (col) {
          final cellIndex = row * 7 + col;
          final dayNumber = cellIndex - startWeekday + 1;

          if (dayNumber < 1 || dayNumber > daysInMonth) {
            return const Expanded(child: SizedBox(height: 80));
          }

          final date = DateTime(month.year, month.month, dayNumber);
          final isToday = _isSameDay(date, now);
          final dayTasks = _tasksForDate(date);
          // Show max 4 tasks, rest as "+N"
          const maxVisible = 3;
          final visibleTasks = dayTasks.take(maxVisible).toList();
          final remaining = dayTasks.length - maxVisible;

          return Expanded(
            child: GestureDetector(
              onTap: () => onDateTap(date),
              child: Container(
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.border.withValues(alpha: 0.2),
                    ),
                    right: col < 6
                        ? BorderSide(
                            color: colors.border.withValues(alpha: 0.15),
                          )
                        : BorderSide.none,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day number
                    Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday ? colors.urgent : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style:
                                context.textTheme.labelSmall?.copyWith(
                              color: isToday
                                  ? Colors.white
                                  : colors.textPrimary,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Task previews
                    ...visibleTasks.map(
                      (task) => _TaskPreview(task: task),
                    ),
                    if (remaining > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          '+$remaining',
                          style:
                              context.textTheme.labelSmall?.copyWith(
                            color: colors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
  }

  List<TaskEntity> _tasksForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return tasks.where((t) {
      final start = t.startDate ?? t.dueDate ?? t.createdAt;
      final end = t.dueDate ?? start;
      return start.isBefore(dayEnd) && end.isAfter(dayStart);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TaskPreview extends StatelessWidget {
  const _TaskPreview({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final taskColor = _color(colors);
    final isCompleted = task.status == TaskStatus.completed;

    final priorityColor = _priorityColor(colors);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: taskColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: priorityColor,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              _label(),
              style: context.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: isCompleted ? colors.textMuted : null,
                decoration:
                    isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _label() {
    if (task.dueDate != null) {
      final h = task.dueDate!.hour;
      final period = h >= 12 ? 'PM' : 'AM';
      final display = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$display $period ${task.title}';
    }
    return task.title;
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

  Color _color(AppColorScheme colors) {
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
