import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
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
        return Scaffold(
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
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/app_icon.svg',
                              height: 32,
                            ),
                            const SizedBox(width: AppSpacing.spacing12),
                            Text(
                              context.l10n.kairoTasks,
                              style: context.textTheme.displayMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.spacing4),
                        Text(
                          _greeting(context),
                          style: context.textTheme.bodyMedium,
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
                    child: _MetricCards(tasks: tasks),
                  ),
                ),
                if (tasks.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing24,
                      vertical: AppSpacing.spacing8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _CompletionChart(tasks: tasks),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing24,
                      vertical: AppSpacing.spacing8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _PriorityChart(tasks: tasks),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing24,
                      vertical: AppSpacing.spacing8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _UpcomingChart(tasks: tasks),
                    ),
                  ),
                ],
                if (tasks.isEmpty)
                  const SliverFillRemaining(
                    child: _EmptyDashboard(),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.spacing24,
                    AppSpacing.spacing16,
                    AppSpacing.spacing24,
                    AppSpacing.spacing64,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _ViewAllTasksButton(onTap: () => context.go('/tasks')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.goodMorning;
    if (hour < 17) return context.l10n.goodAfternoon;
    return context.l10n.goodEvening;
  }
}

class _MetricCards extends StatelessWidget {
  const _MetricCards({required this.tasks});

  final List<TaskEntity> tasks;

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final pending = total - completed;
    final overdue = tasks.where((t) => t.isOverdue).length;

    final metrics = [
      (context.l10n.totalTasks, total.toString()),
      (context.l10n.completedTasks, completed.toString()),
      (context.l10n.pendingTasks, pending.toString()),
      (context.l10n.overdueTasks, overdue.toString()),
    ];

    return Wrap(
      spacing: AppSpacing.spacing32,
      runSpacing: AppSpacing.spacing20,
      children: metrics
          .map((m) => _MetricItem(label: m.$1, value: m.$2))
          .toList(),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

class _CompletionChart extends StatelessWidget {
  const _CompletionChart({required this.tasks});

  final List<TaskEntity> tasks;

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final remaining = tasks.length - completed;
    final rate = tasks.isEmpty ? 0.0 : (completed / tasks.length) * 100;
    final colors = context.appColors;

    return _ChartSection(
      title: context.l10n.completionChart,
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 48,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    value: completed.toDouble(),
                    color: colors.accent,
                    radius: 32,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: remaining.toDouble(),
                    color: colors.textMuted,
                    radius: 32,
                    showTitle: false,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${rate.toStringAsFixed(0)}%',
                  style: context.textTheme.titleMedium,
                ),
                Text(
                  context.l10n.completed,
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChart extends StatelessWidget {
  const _PriorityChart({required this.tasks});

  final List<TaskEntity> tasks;

  @override
  Widget build(BuildContext context) {
    final counts = {
      TaskPriority.urgent:
          tasks.where((t) => t.priority == TaskPriority.urgent).length,
      TaskPriority.high:
          tasks.where((t) => t.priority == TaskPriority.high).length,
      TaskPriority.medium:
          tasks.where((t) => t.priority == TaskPriority.medium).length,
      TaskPriority.low:
          tasks.where((t) => t.priority == TaskPriority.low).length,
    };

    final colors = context.appColors;
    final priorityColors = {
      TaskPriority.urgent: colors.urgent,
      TaskPriority.high: colors.high,
      TaskPriority.medium: colors.medium,
      TaskPriority.low: colors.low,
    };

    const priorities = TaskPriority.values;
    final maxY = _maxValue(counts.values) * 1.2;

    return _ChartSection(
      title: context.l10n.priorityChart,
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.spacing16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY > 0 ? maxY : 1,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= priorities.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.spacing8),
                        child: Text(
                          _priorityLabel(context, priorities[index]),
                          style: context.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: priorities.asMap().entries.map((entry) {
                final priority = entry.value;
                final count = counts[priority] ?? 0;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: count.toDouble(),
                      color: priorityColors[priority],
                      width: 24,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusSmall),
                        topRight: Radius.circular(AppSpacing.radiusSmall),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _priorityLabel(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return context.l10n.urgent;
      case TaskPriority.high:
        return context.l10n.high;
      case TaskPriority.medium:
        return context.l10n.medium;
      case TaskPriority.low:
        return context.l10n.low;
    }
  }

  double _maxValue(Iterable<int> values) {
    final max = values.reduce((a, b) => a > b ? a : b).toDouble();
    return max == 0 ? 1 : max;
  }
}

class _UpcomingChart extends StatelessWidget {
  const _UpcomingChart({required this.tasks});

  final List<TaskEntity> tasks;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.add(Duration(days: i)));
    final counts = days
        .map(
          (d) => tasks
              .where(
                (t) =>
                    t.dueDate != null &&
                    t.status != TaskStatus.completed &&
                    _isSameDay(t.dueDate!, d),
              )
              .length,
        )
        .toList();
    final maxY = _maxValue(counts) * 1.2;
    final labels = days.map(_weekdayLabel).toList();

    return _ChartSection(
      title: context.l10n.upcomingChart,
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.spacing16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY > 0 ? maxY : 1,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.spacing8),
                        child: Text(
                          labels[index],
                          style: context.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: counts.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: context.appColors.accent,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusSmall),
                        topRight: Radius.circular(AppSpacing.radiusSmall),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  double _maxValue(List<int> values) {
    final max = values.reduce((a, b) => a > b ? a : b).toDouble();
    return max == 0 ? 1 : max;
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.spacing8),
        child,
      ],
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_outlined,
              size: 64,
              color: context.appColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              context.l10n.noTasksYet,
              style: context.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewAllTasksButton extends StatelessWidget {
  const _ViewAllTasksButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(context.l10n.viewAllTasks),
    );
  }
}
