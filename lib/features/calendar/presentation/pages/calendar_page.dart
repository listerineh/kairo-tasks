import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../widgets/day_view.dart';
import '../widgets/month_view.dart';
import '../widgets/week_view.dart';

enum CalendarViewType { day, week, month }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarViewType _viewType = CalendarViewType.week;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacing24,
                AppSpacing.spacing16,
                AppSpacing.spacing24,
                AppSpacing.spacing8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _headerTitle(),
                          style: context.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.spacing4),
                        GestureDetector(
                          onTap: _goToToday,
                          child: Text(
                            'Today',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: colors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Navigation arrows
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.chevron_left),
                    iconSize: 28,
                  ),
                  IconButton(
                    onPressed: _goForward,
                    icon: const Icon(Icons.chevron_right),
                    iconSize: 28,
                  ),
                ],
              ),
            ),

            // View type selector
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing24,
                vertical: AppSpacing.spacing8,
              ),
              child: Row(
                children: CalendarViewType.values.map((type) {
                  final isSelected = _viewType == type;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: type != CalendarViewType.month
                            ? AppSpacing.spacing8
                            : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _viewType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.spacing8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSmall,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? colors.accent
                                  : colors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              type.name[0].toUpperCase() +
                                  type.name.substring(1),
                              style:
                                  context.textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : colors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Calendar content
            Expanded(
              child: BlocBuilder<TasksBloc, TasksState>(
                builder: (context, state) {
                  final tasks = state.tasks;

                  switch (_viewType) {
                    case CalendarViewType.day:
                      return DayView(
                        date: _selectedDate,
                        tasks: _tasksForDate(tasks, _selectedDate),
                        onTaskTap: _onTaskTap,
                      );
                    case CalendarViewType.week:
                      return WeekView(
                        startOfWeek: _startOfWeek(_selectedDate),
                        tasks: tasks,
                        onDateTap: (date) => setState(() {
                          _selectedDate = date;
                          _viewType = CalendarViewType.day;
                        }),
                        onTaskTap: _onTaskTap,
                      );
                    case CalendarViewType.month:
                      return MonthView(
                        month: _selectedDate,
                        tasks: tasks,
                        onDateTap: (date) => setState(() {
                          _selectedDate = date;
                          _viewType = CalendarViewType.day;
                        }),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _headerTitle() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    switch (_viewType) {
      case CalendarViewType.day:
        final now = DateTime.now();
        if (_selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day) {
          return 'Today';
        }
        return '${months[_selectedDate.month - 1]} ${_selectedDate.day}';
      case CalendarViewType.week:
        final start = _startOfWeek(_selectedDate);
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month) {
          return '${months[start.month - 1]} ${start.day}–${end.day}';
        }
        return '${months[start.month - 1].substring(0, 3)} ${start.day} – ${months[end.month - 1].substring(0, 3)} ${end.day}';
      case CalendarViewType.month:
        return '${months[_selectedDate.month - 1]} ${_selectedDate.year}';
    }
  }

  void _goToToday() {
    setState(() => _selectedDate = DateTime.now());
  }

  void _goBack() {
    setState(() {
      switch (_viewType) {
        case CalendarViewType.day:
          _selectedDate =
              _selectedDate.subtract(const Duration(days: 1));
        case CalendarViewType.week:
          _selectedDate =
              _selectedDate.subtract(const Duration(days: 7));
        case CalendarViewType.month:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month - 1,
          );
      }
    });
  }

  void _goForward() {
    setState(() {
      switch (_viewType) {
        case CalendarViewType.day:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
        case CalendarViewType.week:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
        case CalendarViewType.month:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + 1,
          );
      }
    });
  }

  DateTime _startOfWeek(DateTime date) {
    // Monday = 1, Sunday = 7
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  List<TaskEntity> _tasksForDate(List<TaskEntity> tasks, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return tasks.where((t) {
      final start = t.startDate ?? t.dueDate ?? t.createdAt;
      final end = t.dueDate ?? start;

      // Task spans this day if its range overlaps with [dayStart, dayEnd)
      return start.isBefore(dayEnd) && end.isAfter(dayStart);
    }).toList();
  }

  void _onTaskTap(TaskEntity task) {
    context.read<TasksBloc>().add(TaskStatusToggled(task.id));
  }
}
