import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/widgets/kairo_header.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/tasks_bloc.dart';
import '../widgets/create_task_sheet.dart';
import '../widgets/edit_task_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/task_filter_chips.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TasksView();
  }
}

class _TasksView extends StatelessWidget {
  const _TasksView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<TasksBloc, TasksState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      },
      child: Scaffold(
        body: SafeArea(
        child: RefreshIndicator(
          color: context.appColors.accent,
          backgroundColor: context.appColors.surfaceElevated,
          onRefresh: () => _onRefresh(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                            _showTaskDetail(context, task),
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
                        context.l10n.completed,
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
                                _showTaskDetail(context, task),
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
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskSheet(context),
        child: const Icon(Icons.add),
      ),
    ),
  );
  }

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.goodMorning;
    if (hour < 17) return context.l10n.goodAfternoon;
    return context.l10n.goodEvening;
  }

  Future<void> _onRefresh(BuildContext context) async {
    final bloc = context.read<TasksBloc>()..add(const TasksLoadRequested());
    await bloc.stream.firstWhere((state) => state.status != TasksStatus.loading);
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

  void _showTaskDetail(BuildContext context, TaskEntity task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TaskDetailSheet(
        task: task,
        onEdit: () {
          Navigator.pop(sheetContext);
          _showEditTaskSheet(context, task);
        },
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
                  ? context.l10n.emptyCompletedTitle
                  : context.l10n.emptyAllClear,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              filter == TasksFilter.completed
                  ? context.l10n.emptyCompletedHint
                  : context.l10n.emptyTaskHint,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
