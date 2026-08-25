import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/tasks_bloc.dart';
import '../widgets/create_task_sheet.dart';
import '../widgets/edit_task_sheet.dart';
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

                final active = state.activeTasks;
                final completed = state.completedTasks;

                if (active.isEmpty && completed.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(filter: state.filter),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing24,
                  ),
                  sliver: SliverList.separated(
                    itemCount: active.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.spacing12),
                    itemBuilder: (context, index) {
                      final task = active[index];
                      return _AnimatedTaskCard(
                        task: task,
                        onToggleStatus: () => context
                            .read<TasksBloc>()
                            .add(TaskStatusToggled(task.id)),
                        onDismissed: () => context
                            .read<TasksBloc>()
                            .add(TaskDeleted(task.id)),
                        onTap: () =>
                            _showEditTaskSheet(context, task),
                      );
                    },
                  ),
                );
              },
            ),
            // Completed section
            BlocBuilder<TasksBloc, TasksState>(
              builder: (context, state) {
                final completed = state.completedTasks;
                if (completed.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.spacing24),
                      Text(
                        'Completed',
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.appColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing12),
                      ...completed.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.spacing12,
                          ),
                          child: _AnimatedTaskCard(
                            task: task,
                            onToggleStatus: () => context
                                .read<TasksBloc>()
                                .add(TaskStatusToggled(task.id)),
                            onDismissed: () => context
                                .read<TasksBloc>()
                                .add(TaskDeleted(task.id)),
                            onTap: () =>
                                _showEditTaskSheet(context, task),
                          ),
                        ),
                      ),
                    ]),
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

  void _showEditTaskSheet(BuildContext context, TaskEntity task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TasksBloc>(),
        child: EditTaskSheet(task: task),
      ),
    );
  }
}

class _AnimatedTaskCard extends StatefulWidget {
  const _AnimatedTaskCard({
    required this.task,
    required this.onToggleStatus,
    this.onDismissed,
    this.onTap,
  });

  final TaskEntity task;
  final VoidCallback onToggleStatus;
  final VoidCallback? onDismissed;
  final VoidCallback? onTap;

  @override
  State<_AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<_AnimatedTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: TaskCard(
          task: widget.task,
          onToggleStatus: widget.onToggleStatus,
          onDismissed: widget.onDismissed,
          onTap: widget.onTap,
        ),
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
