import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/check_circle.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/task_sections.dart';

/// One task in a grouped list (Reminders style): check circle, title,
/// a metadata line (when · who it's shared with) and a priority symbol.
///
/// Opaque on purpose: swipe actions are painted behind it.
class TaskRow extends StatelessWidget {
  const TaskRow({
    required this.task,
    required this.now,
    required this.onToggle,
    this.onTap,
    super.key,
  });

  final TaskEntity task;

  /// Reference time for "today", "tomorrow" and overdue styling.
  final DateTime now;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  /// Where the hairline under a row starts: at the title.
  static const double separatorInset = 52;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final type = context.typography;
    final done = task.status == TaskStatus.completed;
    final meta = _metadata(context);
    final showPriority = !done && task.priority != TaskPriority.medium;

    return ColoredBox(
      color: colors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            const SizedBox(width: 4),
            CheckCircle(
              value: done,
              semanticLabel: task.title,
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Semantics(
                  button: onTap != null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpacing.spacing8,
                      AppSpacing.spacing16,
                      AppSpacing.spacing8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: type.body.copyWith(
                                  color: done
                                      ? colors.labelSecondary
                                      : colors.label,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: colors.labelSecondary,
                                ),
                              ),
                              if (meta != null) meta,
                            ],
                          ),
                        ),
                        if (showPriority) ...[
                          const SizedBox(width: AppSpacing.spacing8),
                          PriorityBadge(
                            priority: task.priority,
                            showLabel: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _metadata(BuildContext context) {
    final colors = context.appColors;
    final when = whenLabel(context, task, now);
    final names = [
      for (final p in task.sharedWith)
        (p['display_name'] as String?) ?? (p['username'] as String?) ?? '',
    ].where((n) => n.isNotEmpty).toList();
    final shared = names.isEmpty ? null : names.join(', ');
    if (when == null && shared == null) return null;

    final date = taskDate(task);
    final today = DateTime(now.year, now.month, now.day);
    final overdue =
        task.status != TaskStatus.completed &&
        date != null &&
        date.isBefore(today);

    return Text.rich(
      TextSpan(
        children: [
          if (when != null)
            TextSpan(
              text: when,
              style: overdue ? TextStyle(color: colors.destructive) : null,
            ),
          if (when != null && shared != null) const TextSpan(text: ' · '),
          if (shared != null)
            TextSpan(
              text: shared,
              semanticsLabel: context.l10n.sharedWithNames(shared),
            ),
        ],
      ),
      style: context.typography.subheadline.copyWith(
        color: colors.labelSecondary,
      ),
    );
  }

  /// "10:00 – 10:30", "Tomorrow, 9:00", "21 Oct" ...; null without a date.
  static String? whenLabel(
    BuildContext context,
    TaskEntity task,
    DateTime now,
  ) {
    final date = taskDate(task);
    if (date == null) return null;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(today).inDays;

    String time(DateTime d) =>
        MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(d),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        );
    bool hasTime(DateTime d) => d.hour != 0 || d.minute != 0;

    final dayLabel = switch (diff) {
      0 => null,
      1 => l10n.tomorrow,
      -1 => l10n.yesterday,
      _ when date.year == now.year => DateFormat.MMMd(locale).format(date),
      _ => DateFormat.yMMMd(locale).format(date),
    };

    final start = task.startDate;
    String? timeLabel;
    if (hasTime(date)) {
      final sameDayStart =
          start != null &&
          task.dueDate != null &&
          DateUtils.isSameDay(start, date) &&
          hasTime(start) &&
          start.isBefore(date);
      timeLabel = sameDayStart ? '${time(start)} – ${time(date)}' : time(date);
    }

    if (dayLabel == null) return timeLabel ?? l10n.today;
    return timeLabel == null ? dayLabel : '$dayLabel, $timeLabel';
  }
}
