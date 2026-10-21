import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/widgets/kairo_header.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/session/current_user.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../../domain/calendar_range.dart';
import '../cubit/calendar_cubit.dart';
import '../widgets/day_view.dart';
import '../widgets/month_view.dart';
import '../widgets/week_view.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final CalendarCubit _cubit = getIt<CalendarCubit>()..start();

  CalendarViewType get _viewType => _cubit.state.viewType;
  DateTime get _selectedDate => _cubit.state.selectedDate;

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      bloc: _cubit,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: logo + view toggle + date navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacing16,
                AppSpacing.spacing8,
                AppSpacing.spacing16,
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const KairoHeader(),
                      const Spacer(),
                      _ViewChip(
                        label: context.l10n.dayInitial,
                        isSelected: _viewType == CalendarViewType.day,
                        onTap: () => _cubit.setView(CalendarViewType.day),
                      ),
                      const SizedBox(width: 6),
                      _ViewChip(
                        label: context.l10n.weekInitial,
                        isSelected: _viewType == CalendarViewType.week,
                        onTap: () => _cubit.setView(CalendarViewType.week),
                      ),
                      const SizedBox(width: 6),
                      _ViewChip(
                        label: context.l10n.monthInitial,
                        isSelected: _viewType == CalendarViewType.month,
                        onTap: () => _cubit.setView(CalendarViewType.month),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _cubit.previous,
                        child: Icon(
                          Icons.chevron_left,
                          color: colors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing4),
                      GestureDetector(
                        onTap: () => _cubit.setView(CalendarViewType.month),
                        child: Text(
                          _headerTitle(),
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _cubit.next,
                        child: Icon(
                          Icons.chevron_right,
                          color: colors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Week strip header (day/week views)
            if (_viewType != CalendarViewType.month) _buildWeekStrip(context),

            // Calendar content
            Expanded(
              child: BlocBuilder<TasksBloc, TasksState>(
                builder: (context, state) {
                  final tasks = mergeTasks(
                    _coloredTasks(state.tasks),
                    _friendTasks(context),
                  );

                  switch (_viewType) {
                    case CalendarViewType.day:
                      return DayView(
                        date: _selectedDate,
                        tasks: tasksOnDay(tasks, _selectedDate),
                        onTaskTap: _onTaskTap,
                      );
                    case CalendarViewType.week:
                      return WeekView(
                        selectedDate: _selectedDate,
                        tasks: tasks,
                        onDateTap: _cubit.showDay,
                        onTaskTap: _onTaskTap,
                      );
                    case CalendarViewType.month:
                      return MonthView(
                        month: _selectedDate,
                        tasks: tasks,
                        selectedDate: _selectedDate,
                        onDateTap: _cubit.showDay,
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
                    onTap: _cubit.today,
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
                        context.l10n.today,
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
    final weekStart = startOfWeek(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing8,
        vertical: AppSpacing.spacing4,
      ),
      child: Row(
        children: List.generate(7, (i) {
          final date = weekStart.add(Duration(days: i));
          final isToday = DateUtils.isSameDay(date, now);
          final isSelected = DateUtils.isSameDay(date, _selectedDate);

          return Expanded(
            child: GestureDetector(
              onTap: () => _cubit.selectDate(date),
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
                              ? (isToday ? colors.onTint : colors.textPrimary)
                              : (isToday ? colors.accent : colors.textPrimary),
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
    final weekStart = startOfWeek(_selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (weekStart.month != weekEnd.month) {
      return _monthNames[weekEnd.month - 1].substring(0, 3);
    }
    return '';
  }

  /// My tasks in my color.
  List<TaskEntity> _coloredTasks(List<TaskEntity> tasks) {
    final palette = _cubit.state.friendCalendar.palette;
    final me = getIt<CurrentUser>().id;
    return [
      for (final t in tasks) t.copyWith(color: palette.colorFor(t.ownerId, me)),
    ];
  }

  /// Friends' tasks in the color I chose for them; private ones only say
  /// the time is busy.
  List<TaskEntity> _friendTasks(BuildContext context) {
    final calendar = _cubit.state.friendCalendar;
    final busy = context.l10n.busy;
    return [
      for (final f in calendar.friendTasks)
        f.task.copyWith(
          title: f.isPrivate ? busy : null,
          color: calendar.palette.colorFor(f.task.ownerId, null),
        ),
    ];
  }

  void _onTaskTap(TaskEntity task) {
    if (task.ownerId != getIt<CurrentUser>().id) {
      return;
    }
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
              color: isSelected ? colors.onTint : colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
