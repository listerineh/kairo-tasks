import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';

class MonthView extends StatelessWidget {
  const MonthView({
    required this.month,
    required this.tasks,
    required this.onDateTap,
    super.key,
  });

  final DateTime month;
  final List<TaskEntity> tasks;
  final void Function(DateTime) onDateTap;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();

    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    // Monday = 1 based offset
    final startWeekday = firstOfMonth.weekday - 1; // 0 = Monday

    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // Day name headers
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing8,
            vertical: AppSpacing.spacing8,
          ),
          child: Row(
            children: _dayNames
                .map(
                  (name) => Expanded(
                    child: Center(
                      child: Text(
                        name,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // Calendar grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing8,
            ),
            child: Column(
              children: List.generate(rows, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(7, (col) {
                      final cellIndex = row * 7 + col;
                      final dayNumber = cellIndex - startWeekday + 1;

                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const Expanded(child: SizedBox.shrink());
                      }

                      final date = DateTime(
                        month.year,
                        month.month,
                        dayNumber,
                      );
                      final isToday = date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;
                      final dayTasks = _tasksForDate(date);
                      final hasUrgent = dayTasks.any(
                        (t) => t.priority == TaskPriority.urgent,
                      );
                      final hasOverdue = dayTasks.any((t) => t.isOverdue);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onDateTap(date),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? colors.accent.withValues(alpha: 0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSmall,
                              ),
                              border: isToday
                                  ? Border.all(color: colors.accent)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                    color: isToday
                                        ? colors.accent
                                        : colors.textPrimary,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                                if (dayTasks.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      _TaskDot(
                                        color: hasOverdue || hasUrgent
                                            ? colors.urgent
                                            : colors.accent,
                                      ),
                                      if (dayTasks.length > 1)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 2),
                                          child: Text(
                                            '${dayTasks.length}',
                                            style: context
                                                .textTheme.labelSmall
                                                ?.copyWith(
                                              fontSize: 9,
                                              color: colors.textMuted,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
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
}

class _TaskDot extends StatelessWidget {
  const _TaskDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
