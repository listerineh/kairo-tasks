import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/grouped_section.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/calendar_range.dart';
import '../../domain/timeline_layout.dart';
import 'calendar_colors.dart';

/// Month grid with up to three colored dots per day; the selected day's
/// agenda is listed below (the iOS Calendar pattern).
class MonthView extends StatelessWidget {
  const MonthView({
    required this.selectedDate,
    required this.tasks,
    required this.onDateTap,
    required this.onTaskTap,
    this.now,
    this.bottomInset = 0,
    super.key,
  });

  final DateTime selectedDate;
  final List<TaskEntity> tasks;
  final ValueChanged<DateTime> onDateTap;
  final ValueChanged<TaskEntity> onTaskTap;

  /// Marks today (tests).
  final DateTime? now;

  /// Extra space after the agenda (e.g. for the tab bar).
  final double bottomInset;

  static const int maxDots = 3;

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    final agenda = tasksOnDay(tasks, selectedDate);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
          ),
          sliver: SliverList.list(
            children: [
              KairoCard(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                child: Column(
                  children: [
                    const _WeekdayHeader(),
                    _MonthGrid(
                      selectedDate: selectedDate,
                      today: today,
                      tasks: tasks,
                      onDateTap: onDateTap,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              _Agenda(day: selectedDate, tasks: agenda, onTaskTap: onTaskTap),
            ],
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacing.spacing24 + bottomInset),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    // Sunday first, like [startOfWeek].
    final names = MaterialLocalizations.of(context).narrowWeekdays;
    final style = context.typography.caption1.copyWith(
      color: context.appColors.labelSecondary,
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.spacing4),
        child: Row(
          children: [
            for (final name in names)
              Expanded(
                child: Text(name, textAlign: TextAlign.center, style: style),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.selectedDate,
    required this.today,
    required this.tasks,
    required this.onDateTap,
  });

  final DateTime selectedDate;
  final DateTime today;
  final List<TaskEntity> tasks;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(selectedDate.year, selectedDate.month);
    final days = DateUtils.getDaysInMonth(first.year, first.month);
    final leading = first.weekday % 7;
    final rows = ((leading + days) / 7).ceil();

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _cell(r * 7 + c - leading + 1, days, first)),
            ],
          ),
      ],
    );
  }

  Widget _cell(int dayNumber, int daysInMonth, DateTime first) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: _DayCell.height);
    }
    final date = DateTime(first.year, first.month, dayNumber);
    return _DayCell(
      date: date,
      isToday: DateUtils.isSameDay(date, today),
      isSelected: DateUtils.isSameDay(date, selectedDate),
      tasks: tasksOnDay(tasks, date),
      onTap: () => onDateTap(date),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.tasks,
    required this.onTap,
  });

  static const double height = 52;

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final List<TaskEntity> tasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final type = context.typography;
    final localizations = MaterialLocalizations.of(context);

    final Color? circle;
    final Color number;
    if (isSelected && isToday) {
      circle = colors.tint;
      number = colors.onTint;
    } else if (isSelected) {
      circle = colors.label;
      number = colors.background;
    } else {
      circle = null;
      number = isToday ? colors.tint : colors.label;
    }

    final dots = [
      for (final t in tasks.take(MonthView.maxDots))
        CalendarTone.of(t.color).dot,
    ];

    return Semantics(
      button: true,
      selected: isSelected,
      label: localizations.formatFullDate(date),
      value: tasks.isEmpty ? null : '${tasks.length}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final dot in dots)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: dot,
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
  }
}

class _Agenda extends StatelessWidget {
  const _Agenda({
    required this.day,
    required this.tasks,
    required this.onTaskTap,
  });

  final DateTime day;
  final List<TaskEntity> tasks;
  final ValueChanged<TaskEntity> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final header = MaterialLocalizations.of(context).formatFullDate(day);
    if (tasks.isEmpty) {
      return GroupedSection(
        header: header,
        margin: 0,
        children: [GroupedRow(title: l10n.calendarNothingPlanned)],
      );
    }
    final sorted = [...tasks]..sort(_byTime);
    return GroupedSection(
      header: header,
      margin: 0,
      separatorInset: 34,
      children: [
        for (final t in sorted)
          GroupedRow(
            title: t.title,
            subtitle: _time(context, t),
            leading: _ToneDot(tone: CalendarTone.of(t.color)),
            onTap: () => onTaskTap(t),
          ),
      ],
    );
  }

  static int _byTime(TaskEntity a, TaskEntity b) {
    final x = isAllDay(a) ? null : taskSpan(a)?.$1;
    final y = isAllDay(b) ? null : taskSpan(b)?.$1;
    if (x == null) return y == null ? 0 : -1;
    if (y == null) return 1;
    return x.compareTo(y);
  }

  String _time(BuildContext context, TaskEntity t) {
    if (isAllDay(t)) return context.l10n.calendarAllDay;
    final span = taskSpan(t);
    if (span == null) return '';
    final localizations = MaterialLocalizations.of(context);
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    String fmt(DateTime d) => localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(d),
      alwaysUse24HourFormat: use24,
    );
    final (from, to) = span;
    return '${fmt(from)} – ${fmt(to)}';
  }
}

class _ToneDot extends StatelessWidget {
  const _ToneDot({required this.tone});

  final CalendarTone tone;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: tone.dot, shape: BoxShape.circle),
  );
}
