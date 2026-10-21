import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/widgets/kairo_header.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/session/current_user.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_segmented_control.dart';
import '../../../tasks/domain/entities/task_draft.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../../../tasks/presentation/widgets/task_detail_sheet.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../../domain/calendar_range.dart';
import '../../domain/timeline_layout.dart';
import '../cubit/calendar_cubit.dart';
import '../widgets/month_view.dart';
import '../widgets/time_grid.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final CalendarCubit _cubit = getIt<CalendarCubit>()..start();

  String? get _me => getIt<CurrentUser>().id;

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      bloc: _cubit,
      builder: (context, calendar) => Scaffold(
        backgroundColor: context.appColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                state: calendar,
                onView: _cubit.setView,
                onPrevious: _cubit.previous,
                onNext: _cubit.next,
                onToday: _cubit.today,
              ),
              if (calendar.viewType != CalendarViewType.month)
                _WeekStrip(
                  selectedDate: calendar.selectedDate,
                  onSelect: _cubit.selectDate,
                ),
              Expanded(
                child: BlocBuilder<TasksBloc, TasksState>(
                  builder: (context, tasks) =>
                      _body(calendar, _visibleTasks(context, tasks.tasks)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(CalendarState calendar, List<TaskEntity> tasks) {
    final selected = calendar.selectedDate;
    switch (calendar.viewType) {
      case CalendarViewType.month:
        return MonthView(
          selectedDate: selected,
          tasks: tasks,
          onDateTap: _cubit.selectDate,
          onTaskTap: _openTask,
        );
      case CalendarViewType.day:
      case CalendarViewType.week:
        final day = DateTime(selected.year, selected.month, selected.day);
        return TimeGrid(
          days: [
            day,
            if (calendar.viewType == CalendarViewType.week)
              DateTime(day.year, day.month, day.day + 1),
          ],
          tasks: tasks,
          onTaskTap: _openTask,
          onCreateAt: (start) =>
              unawaited(showTaskForm(context, initialStart: start)),
          canMove: _isMine,
          onMove: _move,
        );
    }
  }

  /// My tasks in my color, plus friends' tasks in the color I chose for
  /// them; private ones only say the time is busy.
  List<TaskEntity> _visibleTasks(BuildContext context, List<TaskEntity> mine) {
    final calendar = _cubit.state.friendCalendar;
    final palette = calendar.palette;
    final busy = context.l10n.busy;
    return mergeTasks(
      [
        for (final t in mine)
          t.copyWith(color: palette.colorFor(t.ownerId, _me)),
      ],
      [
        for (final f in calendar.friendTasks)
          f.task.copyWith(
            title: f.isPrivate ? busy : null,
            color: palette.colorFor(f.task.ownerId, null),
          ),
      ],
    );
  }

  bool _isMine(TaskEntity task) => task.ownerId == _me;

  void _openTask(TaskEntity task) {
    if (!_isMine(task)) return;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => TaskDetailSheet(
          task: task,
          onEdit: () {
            Navigator.pop(sheetContext);
            unawaited(showTaskForm(context, task: task));
          },
        ),
      ),
    );
  }

  /// Drag to reschedule: same length, new start; sharing is left as is.
  void _move(TaskEntity task, DateTime newStart) {
    final moved = moveTask(task, newStart);
    context.read<TasksBloc>().add(
      TaskEdited(
        task.id,
        TaskDraft(
          title: task.title,
          description: task.description,
          priority: task.priority,
          startDate: moved.start,
          dueDate: moved.due,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.onView,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final CalendarState state;
  final ValueChanged<CalendarViewType> onView;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final title = MaterialLocalizations.of(context)
        .formatMonthYear(state.selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacing16,
        AppSpacing.spacing8,
        AppSpacing.spacing16,
        AppSpacing.spacing8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const KairoHeader(),
              const Spacer(),
              KairoButton(
                label: l10n.today,
                variant: KairoButtonVariant.tinted,
                onPressed: onToday,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: context.typography.title2.copyWith(
                      color: colors.label,
                    ),
                  ),
                ),
              ),
              _NavButton(
                icon: CupertinoIcons.chevron_left,
                label: l10n.calendarPrevious,
                onTap: onPrevious,
              ),
              _NavButton(
                icon: CupertinoIcons.chevron_right,
                label: l10n.calendarNext,
                onTap: onNext,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          KairoSegmentedControl<CalendarViewType>(
            segments: {
              CalendarViewType.day: l10n.calendarDay,
              CalendarViewType.week: l10n.calendarWeek,
              CalendarViewType.month: l10n.calendarMonth,
            },
            selected: state.viewType,
            onChanged: onView,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    tooltip: label,
    icon: Icon(icon, size: 20, color: context.appColors.tint),
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
  );
}

/// Sunday-first strip of the selected week; tap a day to jump to it.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selectedDate, required this.onSelect});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final type = context.typography;
    final localizations = MaterialLocalizations.of(context);
    final names = localizations.narrowWeekdays;
    final now = DateTime.now();
    final weekStart = startOfWeek(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TimeGrid.gutterWidth - AppSpacing.spacing8,
        0,
        AppSpacing.spacing8,
        AppSpacing.spacing4,
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final date = DateTime(
                    weekStart.year,
                    weekStart.month,
                    weekStart.day + i,
                  );
                  final isToday = DateUtils.isSameDay(date, now);
                  final isSelected = DateUtils.isSameDay(date, selectedDate);
                  final circle = isSelected
                      ? (isToday ? colors.tint : colors.label)
                      : null;
                  final number = isSelected
                      ? (isToday ? colors.onTint : colors.background)
                      : (isToday ? colors.tint : colors.label);
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: localizations.formatFullDate(date),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(date),
                      child: Column(
                        children: [
                          Text(
                            names[i],
                            style: type.caption1.copyWith(
                              color: colors.labelSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: circle,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${date.day}',
                              textScaler: MediaQuery.textScalerOf(context)
                                  .clamp(maxScaleFactor: 1.2),
                              style: type.callout.copyWith(
                                color: number,
                                fontWeight: isToday || isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
