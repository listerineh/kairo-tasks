import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/session/current_user.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../../core/widgets/kairo_segmented_control.dart';
import '../../../../core/widgets/kairo_sheet.dart';
import '../../../../core/widgets/kairo_tab_bar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../tasks/domain/entities/task_draft.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/domain/task_sections.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../../../tasks/presentation/widgets/task_feedback.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../../../tasks/presentation/widgets/task_list_item.dart';
import '../../domain/calendar_range.dart';
import '../../domain/timeline_layout.dart';
import '../cubit/calendar_cubit.dart';
import '../widgets/calendar_colors.dart';
import '../widgets/month_view.dart';
import '../widgets/time_grid.dart';

/// Planear (docs/redesign-plan.md §2.3): the calendar in Day, Week and Month,
/// plus "Algún día" for tasks without a date.
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
    final colors = context.appColors;
    return TaskFeedbackListener(
      child: BlocBuilder<CalendarCubit, CalendarState>(
        bloc: _cubit,
        builder: (context, calendar) => Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            bottom: false,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: colors.label),
              child: BlocBuilder<TasksBloc, TasksState>(
                builder: (context, tasks) {
                  final visible = _visibleTasks(context, tasks.tasks);
                  final someday = _someday(tasks.tasks);
                  return Column(
                    children: [
                      _Header(
                        state: calendar,
                        somedayCount: someday.length,
                        onView: _cubit.setView,
                        onPrevious: _cubit.previous,
                        onNext: _cubit.next,
                        onToday: _cubit.today,
                        onSomeday: () => _showSomeday(context),
                      ),
                      if (calendar.viewType != CalendarViewType.month)
                        _WeekStrip(
                          selectedDate: calendar.selectedDate,
                          tasks: visible,
                          onSelect: _cubit.selectDate,
                        ),
                      Expanded(child: _body(calendar, visible)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(CalendarState calendar, List<TaskEntity> tasks) {
    final selected = calendar.selectedDate;
    final inset = KairoTabBar.contentPadding(context);
    switch (calendar.viewType) {
      case CalendarViewType.month:
        return MonthView(
          selectedDate: selected,
          tasks: tasks,
          onDateTap: _cubit.selectDate,
          onTaskTap: _openTask,
          bottomInset: inset,
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
          bottomInset: inset,
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

  /// My unfinished tasks without a date.
  List<TaskEntity> _someday(List<TaskEntity> tasks) {
    final sections = groupTasks(tasks, DateTime.now());
    final noDate = [
      for (final s in sections)
        if (s.kind == TaskSectionKind.noDate) ...s.tasks,
    ];
    return [
      for (final t in noDate)
        if (_isMine(t)) t,
    ];
  }

  bool _isMine(TaskEntity task) => task.ownerId == _me;

  void _openTask(TaskEntity task) {
    if (_isMine(task)) showTaskDetail(context, task);
  }

  void _showSomeday(BuildContext context) {
    // The sheet lives on the root navigator, above the shell's providers.
    final bloc = context.read<TasksBloc>();
    unawaited(
      showKairoSheet<void>(
        context: context,
        builder: (context, controller) => BlocProvider.value(
          value: bloc,
          child: BlocBuilder<TasksBloc, TasksState>(
            builder: (context, state) => _SomedaySheet(
              tasks: _someday(state.tasks),
              controller: controller,
            ),
          ),
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
    required this.somedayCount,
    required this.onView,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onSomeday,
  });

  final CalendarState state;
  final int somedayCount;
  final ValueChanged<CalendarViewType> onView;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onSomeday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final month = MaterialLocalizations.of(context)
        .formatMonthYear(state.selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.spacing12,
        AppSpacing.screenMargin,
        AppSpacing.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _capitalized(month),
                            style: context.typography.subheadline.copyWith(
                              color: colors.labelSecondary,
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
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.navPlan,
                        style: context.typography.largeTitle,
                      ),
                    ),
                  ],
                ),
              ),
              _Pill(
                icon: CupertinoIcons.tray,
                label: somedayCount > 0 ? '$somedayCount' : null,
                semanticsLabel: '${l10n.someday}, $somedayCount',
                onTap: onSomeday,
              ),
              const SizedBox(width: AppSpacing.spacing8),
              _Pill(label: l10n.today, onTap: onToday),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
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

  static String _capitalized(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Compact outline capsule for header actions.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.onTap,
    this.label,
    this.icon,
    this.semanticsLabel,
  });

  final VoidCallback onTap;
  final String? label;
  final IconData? icon;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: Pressable(
        onPressed: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: ShapeDecoration(
            color: colors.surface,
            shape: StadiumBorder(side: BorderSide(color: colors.separator)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 18, color: colors.label),
              if (icon != null && label != null) const SizedBox(width: 6),
              if (label != null)
                Text(
                  label!,
                  style: context.typography.subheadline.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
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
    visualDensity: VisualDensity.compact,
    icon: Icon(icon, size: 16, color: context.appColors.labelSecondary),
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
  );
}

/// Sunday-first strip of the selected week: pills with up to three dots for
/// the day's tasks; the selected day is inverted, today is in tint.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selectedDate,
    required this.tasks,
    required this.onSelect,
  });

  final DateTime selectedDate;
  final List<TaskEntity> tasks;
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
        AppSpacing.screenMargin,
        0,
        AppSpacing.screenMargin,
        AppSpacing.spacing8,
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 4),
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
                  final day = tasksOnDay(tasks, date);
                  final fg = isSelected
                      ? colors.background
                      : isToday
                      ? colors.tint
                      : colors.label;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: localizations.formatFullDate(date),
                    value: day.isEmpty ? null : '${day.length}',
                    excludeSemantics: true,
                    child: Pressable(
                      onPressed: () => onSelect(date),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.label : colors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              names[i],
                              style: type.caption1.copyWith(
                                color: isSelected
                                    ? colors.background
                                    : colors.labelSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${date.day}',
                              textScaler: MediaQuery.textScalerOf(context)
                                  .clamp(maxScaleFactor: 1.2),
                              style: type.headline.copyWith(
                                color: fg,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 5,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final t in day.take(3))
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colors.background
                                            : CalendarTone.of(t.color).dot,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Algún día": unfinished tasks without a date. Rows swipe, open and edit
/// like everywhere else; giving one a date moves it onto the calendar.
class _SomedaySheet extends StatelessWidget {
  const _SomedaySheet({required this.tasks, required this.controller});

  final List<TaskEntity> tasks;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final now = DateTime.now();
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.spacing8,
        AppSpacing.screenMargin,
        AppSpacing.spacing32,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(l10n.someday, style: context.typography.title1),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        Text(
          l10n.somedayHint,
          style: context.typography.subheadline.copyWith(
            color: colors.labelSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        if (tasks.isEmpty)
          EmptyState(icon: CupertinoIcons.tray, title: l10n.somedayEmpty)
        else
          KairoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < tasks.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, color: colors.separator),
                  TaskListItem(
                    key: ValueKey(tasks[i].id),
                    task: tasks[i],
                    now: now,
                    onOpen: () => showTaskDetail(context, tasks[i]),
                    onEdit: () =>
                        unawaited(showTaskForm(context, task: tasks[i])),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
