import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/widgets/kairo_header.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        if (state.status == TasksStatus.loading && state.tasks.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final tasks = state.tasks;
        final now = DateTime.now();
        final today = _dateOnly(now);
        final userId = Supabase.instance.client.auth.currentUser?.id;

        final todayList = _todayTasks(tasks, today);
        final upcomingGroups = _upcomingGroups(tasks, today);
        final urgentList = _urgentTasks(tasks);
        final sharedList = _sharedTasks(tasks, userId);

        final overdueCount = tasks.where((t) => t.isOverdue).length;
        final completedTodayCount = tasks.where((t) {
          if (t.status != TaskStatus.completed) return false;
          final timestamp = t.updatedAt ?? t.createdAt;
          return _isSameDay(timestamp, today);
        }).length;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go('/tasks'),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.newTask),
            tooltip: context.l10n.newTask,
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.spacing24,
                    AppSpacing.spacing24,
                    AppSpacing.spacing24,
                    AppSpacing.spacing8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const KairoHeader(),
                        const SizedBox(height: AppSpacing.spacing4),
                        Text(
                          _greeting(context),
                          style: context.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.spacing2),
                        Text(
                          _todayLabel(context),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing24,
                    vertical: AppSpacing.spacing16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MicroStat(
                          label: context.l10n.todayTasks,
                          value: todayList.length.toString(),
                        ),
                        _MicroStat(
                          label: context.l10n.overdueTasks,
                          value: overdueCount.toString(),
                        ),
                        _MicroStat(
                          label: context.l10n.completedToday,
                          value: completedTodayCount.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing24,
                    vertical: AppSpacing.spacing8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.today,
                          style: context.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.spacing12),
                        if (todayList.isEmpty)
                          const _EmptyToday()
                        else
                          Column(
                            children: todayList
                                .take(5)
                                .map((t) => _DashboardTaskTile(task: t))
                                .toList(),
                          ),
                        const SizedBox(height: AppSpacing.spacing8),
                        TextButton(
                          onPressed: () => context.go('/tasks'),
                          child: Text(context.l10n.viewAllTasks),
                        ),
                      ],
                    ),
                  ),
                ),
                if (upcomingGroups.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing24,
                      vertical: AppSpacing.spacing8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.thisWeek,
                            style: context.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.spacing12),
                          ...upcomingGroups.entries.map(
                            (e) => _DayGroup(
                              day: e.key,
                              tasks: e.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (urgentList.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing24,
                      vertical: AppSpacing.spacing8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.urgentHigh,
                            style: context.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.spacing12),
                          Column(
                            children: urgentList
                                .take(5)
                                .map((t) => _DashboardTaskTile(task: t))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (sharedList.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing24,
                      vertical: AppSpacing.spacing8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.sharedWithYou,
                            style: context.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.spacing12),
                          Column(
                            children: sharedList
                                .take(3)
                                .map(
                                  (t) => _DashboardTaskTile(
                                    task: t,
                                    subtitle: _sharedByLabel(context, t),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: AppSpacing.spacing64),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MicroStat extends StatelessWidget {
  const _MicroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: context.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.spacing4),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DashboardTaskTile extends StatelessWidget {
  const _DashboardTaskTile({required this.task, this.subtitle});

  final TaskEntity task;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: _priorityColor(context, task.priority),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.spacing2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.planYourDay,
            style: context.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            context.l10n.emptyTaskHint,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.tasks});

  final DateTime day;
  final List<TaskEntity> tasks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dayHeader(context, day),
            style: context.textTheme.labelLarge?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: tasks
                .take(3)
                .map((t) => _TaskChip(task: t))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _priorityColor(context, task.priority),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Flexible(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isSameDay(DateTime a, DateTime b) => _dateOnly(a) == _dateOnly(b);

String _greeting(BuildContext context) {
  final hour = DateTime.now().hour;
  if (hour < 12) return context.l10n.goodMorning;
  if (hour < 17) return context.l10n.goodAfternoon;
  return context.l10n.goodEvening;
}

String _todayLabel(BuildContext context) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMMEEEEd(locale).format(DateTime.now());
}

String _dayHeader(BuildContext context, DateTime day) {
  final locale = Localizations.localeOf(context).toString();
  return '${DateFormat.E(locale).format(day)} ${day.day}';
}

Color _priorityColor(BuildContext context, TaskPriority priority) {
  switch (priority) {
    case TaskPriority.urgent:
      return context.appColors.urgent;
    case TaskPriority.high:
      return context.appColors.high;
    case TaskPriority.medium:
      return context.appColors.medium;
    case TaskPriority.low:
      return context.appColors.low;
  }
}

List<TaskEntity> _todayTasks(List<TaskEntity> tasks, DateTime today) {
  final tomorrow = today.add(const Duration(days: 1));
  return tasks
      .where(
        (t) =>
            t.status != TaskStatus.completed &&
            t.dueDate != null &&
            _dateOnly(t.dueDate!).isBefore(tomorrow),
      )
      .toList()
    ..sort((a, b) => _dateOnly(a.dueDate!).compareTo(_dateOnly(b.dueDate!)));
}

Map<DateTime, List<TaskEntity>> _upcomingGroups(
  List<TaskEntity> tasks,
  DateTime today,
) {
  final end = today.add(const Duration(days: 8));
  final groups = <DateTime, List<TaskEntity>>{};

  for (final t in tasks) {
    if (t.status == TaskStatus.completed || t.dueDate == null) continue;
    final d = _dateOnly(t.dueDate!);
    if (d.isAfter(today) && d.isBefore(end)) {
      groups.putIfAbsent(d, () => []).add(t);
    }
  }

  for (final list in groups.values) {
    list.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  final sorted = groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return Map.fromEntries(sorted);
}

List<TaskEntity> _urgentTasks(List<TaskEntity> tasks) {
  return tasks
      .where(
        (t) =>
            t.status != TaskStatus.completed &&
            (t.priority == TaskPriority.urgent ||
                t.priority == TaskPriority.high),
      )
      .toList()
    ..sort((a, b) {
      final priorityDiff = a.priority.index.compareTo(b.priority.index);
      if (priorityDiff != 0) return priorityDiff;
      final ad = a.dueDate ?? DateTime(9999);
      final bd = b.dueDate ?? DateTime(9999);
      return ad.compareTo(bd);
    });
}

List<TaskEntity> _sharedTasks(List<TaskEntity> tasks, String? userId) {
  if (userId == null) return [];
  return tasks
      .where(
        (t) =>
            t.status != TaskStatus.completed &&
            t.isShared &&
            t.ownerId != userId,
      )
      .toList()
    ..sort((a, b) => (a.dueDate ?? DateTime(9999)).compareTo(
          b.dueDate ?? DateTime(9999),
        ));
}

String? _sharedByLabel(BuildContext context, TaskEntity task) {
  if (task.sharedWith.isEmpty) return null;
  final profile = task.sharedWith.first;
  final name = profile['display_name'] as String? ??
      profile['username'] as String?;
  if (name == null || name.isEmpty) return null;
  return '${context.l10n.sharedBy} $name';
}
