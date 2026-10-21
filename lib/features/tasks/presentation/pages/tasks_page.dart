import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/grouped_section.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_large_title_scaffold.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/task_sections.dart';
import '../bloc/tasks_bloc.dart';
import '../widgets/create_task_sheet.dart';
import '../widgets/edit_task_sheet.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/task_list_item.dart';
import '../widgets/task_row.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Technical details are logged by the bloc; people get plain
        // language. A failed load already shows its own full-screen state.
        BlocListener<TasksBloc, TasksState>(
          listenWhen: (prev, curr) =>
              curr.errorMessage != null &&
              curr.errorMessage != prev.errorMessage &&
              curr.status != TasksStatus.error,
          listener: (context, state) =>
              _snack(context, context.l10n.taskActionFailed),
        ),
        BlocListener<TasksBloc, TasksState>(
          listenWhen: (prev, curr) =>
              curr.pendingDeletion != null &&
              curr.pendingDeletion?.id != prev.pendingDeletion?.id,
          listener: (context, state) => _snack(
            context,
            context.l10n.taskDeletedMessage,
            undo: () => context.read<TasksBloc>().add(const TaskDeleteUndone()),
          ),
        ),
      ],
      child: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) => KairoLargeTitleScaffold(
          title: context.l10n.tasks,
          actions: [
            _FilterButton(filter: state.filter),
            IconButton(
              tooltip: context.l10n.newTask,
              icon: const Icon(CupertinoIcons.plus),
              onPressed: () => _showCreateSheet(context),
            ),
          ],
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: () => _refresh(context)),
            ..._content(context, state),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, TasksState state) {
    final l10n = context.l10n;
    if (state.tasks.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: switch (state.status) {
              TasksStatus.initial ||
              TasksStatus.loading => const CupertinoActivityIndicator(),
              TasksStatus.error => EmptyState(
                icon: CupertinoIcons.exclamationmark_triangle,
                title: l10n.tasksLoadError,
                action: KairoButton(
                  label: l10n.tryAgain,
                  variant: KairoButtonVariant.tinted,
                  onPressed: () =>
                      context.read<TasksBloc>().add(const TasksLoadRequested()),
                ),
              ),
              TasksStatus.loaded => EmptyState(
                icon: CupertinoIcons.checkmark_circle,
                title: l10n.emptyAllClear,
                message: l10n.emptyTaskHint,
                action: KairoButton(
                  label: l10n.newTask,
                  icon: CupertinoIcons.plus,
                  variant: KairoButtonVariant.tinted,
                  onPressed: () => _showCreateSheet(context),
                ),
              ),
            },
          ),
        ),
      ];
    }

    final now = DateTime.now();
    final sections = groupTasks(_filtered(state), now);
    if (sections.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              icon: CupertinoIcons.line_horizontal_3_decrease,
              title: l10n.emptyAllClear,
            ),
          ),
        ),
      ];
    }

    return [
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.spacing8)),
      for (final section in sections)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacing24),
            child: section.kind == TaskSectionKind.completed
                ? _completedSection(context, section, now)
                : GroupedSection(
                    header: _title(context, section.kind),
                    separatorInset: TaskRow.separatorInset,
                    children: _items(context, section.tasks, now),
                  ),
          ),
        ),
    ];
  }

  Widget _completedSection(
    BuildContext context,
    TaskSection section,
    DateTime now,
  ) {
    final motion = context.motion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompletedHeader(
          count: section.tasks.length,
          expanded: _showCompleted,
          onToggle: () => setState(() => _showCompleted = !_showCompleted),
        ),
        AnimatedSize(
          duration: motion.duration(KairoSpring.smooth),
          curve: motion.curve(KairoSpring.smooth),
          alignment: Alignment.topCenter,
          child: _showCompleted
              ? GroupedSection(
                  separatorInset: TaskRow.separatorInset,
                  children: _items(context, section.tasks, now),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  List<Widget> _items(
    BuildContext context,
    List<TaskEntity> tasks,
    DateTime now,
  ) => [
    for (final task in tasks)
      TaskListItem(
        key: ValueKey(task.id),
        task: task,
        now: now,
        onOpen: () => _showDetail(context, task),
        onEdit: () => _showEditSheet(context, task),
      ),
  ];

  List<TaskEntity> _filtered(TasksState state) {
    final priority = switch (state.filter) {
      TasksFilter.urgent => TaskPriority.urgent,
      TasksFilter.high => TaskPriority.high,
      TasksFilter.medium => TaskPriority.medium,
      TasksFilter.low => TaskPriority.low,
      TasksFilter.all || TasksFilter.completed => null,
    };
    if (priority == null) return state.tasks;
    return state.tasks.where((t) => t.priority == priority).toList();
  }

  String _title(BuildContext context, TaskSectionKind kind) {
    final l10n = context.l10n;
    return switch (kind) {
      TaskSectionKind.overdue => l10n.overdueTasks,
      TaskSectionKind.today => l10n.today,
      TaskSectionKind.upcoming => l10n.sectionUpcoming,
      TaskSectionKind.noDate => l10n.sectionNoDate,
      TaskSectionKind.completed => l10n.completed,
    };
  }

  void _snack(BuildContext context, String message, {VoidCallback? undo}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          // Matches the bloc's undo window before the delete is committed.
          duration: const Duration(seconds: 4),
          action: undo == null
              ? null
              : SnackBarAction(label: context.l10n.undo, onPressed: undo),
        ),
      );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<TasksBloc>()..add(const TasksLoadRequested());
    await bloc.stream.firstWhere((s) => s.status != TasksStatus.loading);
  }

  void _showCreateSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: context.read<TasksBloc>(),
          child: const CreateTaskSheet(),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, TaskEntity task) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => TaskDetailSheet(
          task: task,
          onEdit: () {
            Navigator.pop(sheetContext);
            _showEditSheet(context, task);
          },
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, TaskEntity task) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: context.read<TasksBloc>(),
          child: EditTaskSheet(task: task),
        ),
      ),
    );
  }
}

/// "Completed · 3" with a chevron; tapping shows or hides the section.
class _CompletedHeader extends StatelessWidget {
  const _CompletedHeader({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final l10n = context.l10n;

    return Semantics(
      button: true,
      expanded: expanded,
      label: expanded ? l10n.hideCompleted : l10n.showCompleted,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Text(
                  '${l10n.completed} · $count',
                  style: context.typography.footnote.copyWith(
                    color: colors.labelSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing4),
                AnimatedRotation(
                  turns: expanded ? 0 : -0.25,
                  duration: motion.duration(KairoSpring.snappy),
                  curve: motion.curve(KairoSpring.snappy),
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 13,
                    color: colors.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Priority filter in the navigation bar; filled icon while filtering.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.filter});

  final TasksFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = filter != TasksFilter.all && filter != TasksFilter.completed;
    final options = {
      TasksFilter.all: l10n.all,
      TasksFilter.urgent: l10n.urgent,
      TasksFilter.high: l10n.high,
      TasksFilter.medium: l10n.medium,
      TasksFilter.low: l10n.low,
    };

    return PopupMenuButton<TasksFilter>(
      tooltip: l10n.filterTasks,
      icon: Icon(
        active
            ? CupertinoIcons.line_horizontal_3_decrease_circle_fill
            : CupertinoIcons.line_horizontal_3_decrease_circle,
      ),
      initialValue: filter,
      onSelected: (f) => context.read<TasksBloc>().add(TasksFilterChanged(f)),
      itemBuilder: (_) => [
        for (final entry in options.entries)
          CheckedPopupMenuItem<TasksFilter>(
            value: entry.key,
            checked:
                entry.key == filter ||
                (entry.key == TasksFilter.all && !active),
            child: Text(entry.value),
          ),
      ],
    );
  }
}
