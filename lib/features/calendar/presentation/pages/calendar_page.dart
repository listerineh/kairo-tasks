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

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: month name + view toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacing16,
                AppSpacing.spacing8,
                AppSpacing.spacing16,
                0,
              ),
              child: Row(
                children: [
                  // Back arrow + month/year
                  GestureDetector(
                    onTap: _goBack,
                    child: Icon(
                      Icons.chevron_left,
                      color: colors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing4),
                  GestureDetector(
                    onTap: () => setState(
                      () => _viewType = CalendarViewType.month,
                    ),
                    child: Text(
                      _headerTitle(),
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _goForward,
                    child: Icon(
                      Icons.chevron_right,
                      color: colors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  // View type chips
                  _ViewChip(
                    label: 'D',
                    isSelected: _viewType == CalendarViewType.day,
                    onTap: () =>
                        setState(() => _viewType = CalendarViewType.day),
                  ),
                  const SizedBox(width: 6),
                  _ViewChip(
                    label: 'W',
                    isSelected: _viewType == CalendarViewType.week,
                    onTap: () =>
                        setState(() => _viewType = CalendarViewType.week),
                  ),
                  const SizedBox(width: 6),
                  _ViewChip(
                    label: 'M',
                    isSelected: _viewType == CalendarViewType.month,
                    onTap: () =>
                        setState(() => _viewType = CalendarViewType.month),
                  ),
                ],
              ),
            ),

            // Week strip header (day/week views)
            if (_viewType != CalendarViewType.month)
              _buildWeekStrip(context),

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
                        selectedDate: _selectedDate,
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
                        selectedDate: _selectedDate,
                        onDateTap: (date) => setState(() {
                          _selectedDate = date;
                          _viewType = CalendarViewType.day;
                        }),
                      );
                  }
                },
              ),
            ),

            // Bottom bar: Today button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing16,
                vertical: AppSpacing.spacing8,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goToToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing16,
                        vertical: AppSpacing.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Today',
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_viewType != CalendarViewType.month)
                    Text(
                      _nextMonthLabel(),
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStrip(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final weekStart = _startOfWeek(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing8,
        vertical: AppSpacing.spacing4,
      ),
      child: Row(
        children: List.generate(7, (i) {
          final date = weekStart.add(Duration(days: i));
          final isToday = _isSameDay(date, now);
          final isSelected = _isSameDay(date, _selectedDate);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dayLabels[date.weekday % 7],
                    style: context.textTheme.labelSmall?.copyWith(
                      color: isToday ? colors.accent : colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? (isToday ? colors.accent : colors.surfaceSubtle)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? (isToday
                                  ? Colors.white
                                  : colors.textPrimary)
                              : (isToday
                                  ? colors.accent
                                  : colors.textPrimary),
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _headerTitle() {
    switch (_viewType) {
      case CalendarViewType.month:
        return '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
      case CalendarViewType.day:
      case CalendarViewType.week:
        final now = DateTime.now();
        if (_selectedDate.year == now.year) {
          return _monthNames[_selectedDate.month - 1];
        }
        return '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
    }
  }

  String _nextMonthLabel() {
    final weekStart = _startOfWeek(_selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (weekStart.month != weekEnd.month) {
      return _monthNames[weekEnd.month - 1].substring(0, 3);
    }
    return '';
  }

  void _goToToday() => setState(() => _selectedDate = DateTime.now());

  void _goBack() {
    setState(() {
      switch (_viewType) {
        case CalendarViewType.day:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        case CalendarViewType.week:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        case CalendarViewType.month:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month - 1,
            1,
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
            1,
          );
      }
    });
  }

  DateTime _startOfWeek(DateTime date) {
    // Sunday = 0 based
    final offset = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - offset);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<TaskEntity> _tasksForDate(List<TaskEntity> tasks, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return tasks.where((t) {
      final start = t.startDate ?? t.dueDate ?? t.createdAt;
      final end = t.dueDate ?? start;
      return start.isBefore(dayEnd) && end.isAfter(dayStart);
    }).toList();
  }

  void _onTaskTap(TaskEntity task) {
    context.read<TasksBloc>().add(TaskStatusToggled(task.id));
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? colors.accent : colors.surfaceSubtle,
        ),
        child: Center(
          child: Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: isSelected ? Colors.white : colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
