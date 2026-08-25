import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../bloc/tasks_bloc.dart';
import '../widgets/create_task_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_chips.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TasksBloc()..add(const TasksLoadRequested()),
      child: const _TasksView(),
    );
  }
}

class _TasksView extends StatelessWidget {
  const _TasksView();

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      'KairoTasks',
                      style: context.textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      _greeting(),
                      style: context.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing24,
                  vertical: AppSpacing.spacing12,
                ),
                child: TaskFilterChips(),
              ),
            ),
            BlocBuilder<TasksBloc, TasksState>(
              builder: (context, state) {
                if (state.status == TasksStatus.loading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final tasks = state.filteredTasks;

                if (tasks.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(filter: state.filter),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing24,
                  ),
                  sliver: SliverList.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.spacing12),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskCard(
                        task: task,
                        onToggleStatus: () => context
                            .read<TasksBloc>()
                            .add(TaskStatusToggled(task.id)),
                        onDismissed: () => context
                            .read<TasksBloc>()
                            .add(TaskDeleted(task.id)),
                      );
                    },
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.spacing64),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning. Here are your tasks.';
    if (hour < 17) return 'Good afternoon. Stay focused.';
    return 'Good evening. Review your progress.';
  }

  void _showCreateTaskSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TasksBloc>(),
        child: const CreateTaskSheet(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final TasksFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: context.appColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              filter == TasksFilter.completed
                  ? 'No completed tasks yet'
                  : 'All clear',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              filter == TasksFilter.completed
                  ? 'Complete some tasks to see them here.'
                  : 'Tap + to create your first task.',
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
