import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../cubit/focus_cubit.dart';
import '../cubit/focus_state.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FocusCubit(),
      child: const _FocusView(),
    );
  }
}

class _FocusView extends StatelessWidget {
  const _FocusView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.focus),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<FocusCubit, FocusState>(
        builder: (context, state) {
          if (state.selectedTask == null) {
            return const _TaskPicker();
          }
          return const _TimerView();
        },
      ),
    );
  }
}

class _TaskPicker extends StatelessWidget {
  const _TaskPicker();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        final tasks = state.tasks
            .where(
              (t) =>
                  t.status != TaskStatus.completed &&
                  (userId == null || t.ownerId == userId),
            )
            .toList()
          ..sort((a, b) => a.priority.index.compareTo(b.priority.index));

        if (tasks.isEmpty) {
          return Center(
            child: Text(context.l10n.noTasksToFocus),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _TaskListTile(
              task: task,
              onTap: () => context.read<FocusCubit>().selectTask(task),
            );
          },
        );
      },
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({
    required this.task,
    required this.onTap,
  });

  final TaskEntity task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      color: colors.surfaceSubtle,
      child: ListTile(
        leading: Icon(
          _priorityIcon(task.priority),
          color: _priorityColor(context, task.priority),
        ),
        title: Text(task.title),
        subtitle: task.dueDate != null
            ? Text(
                '${context.l10n.due}: ${_formatDate(task.dueDate!)}',
                style: context.textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary),
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Color _priorityColor(BuildContext context, TaskPriority priority) {
    return switch (priority) {
      TaskPriority.urgent => context.appColors.urgent,
      TaskPriority.high => context.appColors.high,
      TaskPriority.medium => context.appColors.medium,
      TaskPriority.low => context.appColors.low,
    };
  }

  IconData _priorityIcon(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.urgent => Icons.error_outline,
      TaskPriority.high => Icons.flag,
      TaskPriority.medium => Icons.outlined_flag,
      TaskPriority.low => Icons.turned_in_not,
    };
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _TimerView extends StatelessWidget {
  const _TimerView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<FocusCubit, FocusState>(
      builder: (context, state) {
        final isDone = state.remaining.inSeconds == 0;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.mode == FocusMode.focus &&
                  state.selectedTask != null) ...[
                Text(
                  state.selectedTask!.title,
                  style: context.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.spacing8),
                Text(
                  context.l10n.focusMode,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.spacing32),
              ],
              if (state.mode == FocusMode.break_) ...[
                Text(
                  context.l10n.breakMode,
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.spacing32),
              ],
              Text(
                _formatDuration(state.remaining),
                style: context.textTheme.displayLarge?.copyWith(
                  fontSize: 80,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing32),
              if (!isDone) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: state.isRunning
                          ? Icons.pause
                          : Icons.play_arrow,
                      onPressed: () => state.isRunning
                          ? context.read<FocusCubit>().pause()
                          : context.read<FocusCubit>().start(),
                    ),
                    const SizedBox(width: AppSpacing.spacing16),
                    _ControlButton(
                      icon: Icons.stop,
                      onPressed: () => context.read<FocusCubit>().reset(),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  state.mode == FocusMode.focus
                      ? context.l10n.focusComplete
                      : context.l10n.breakComplete,
                  style: context.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.spacing24),
                if (state.mode == FocusMode.focus) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final task = state.selectedTask!;
                          context.read<TasksBloc>().add(
                                TaskStatusToggled(task.id),
                              );
                          context.pop();
                        },
                        icon: const Icon(Icons.check),
                        label: Text(context.l10n.completeTask),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      OutlinedButton(
                        onPressed: () {
                          context.read<FocusCubit>().startBreak();
                          context.read<FocusCubit>().start();
                        },
                        child: Text(context.l10n.takeBreak),
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text(context.l10n.backToDashboard),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.accent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
