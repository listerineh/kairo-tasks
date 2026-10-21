import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../../../core/widgets/swipe_actions.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/tasks_bloc.dart';
import 'task_row.dart';

/// A [TaskRow] with its gestures: swipe right to complete, swipe left to
/// delete or edit, long press for the context menu (docs/redesign-plan.md
/// §3, Tasks). Completing shows an undo snackbar; deleting is undone from
/// the page, which owns the deletion undo window.
class TaskListItem extends StatelessWidget {
  const TaskListItem({
    required this.task,
    required this.now,
    required this.onOpen,
    required this.onEdit,
    super.key,
  });

  final TaskEntity task;
  final DateTime now;
  final VoidCallback onOpen;

  /// Opens the edit sheet (also used for "Share with...").
  final VoidCallback onEdit;

  bool get _done => task.status == TaskStatus.completed;

  void _toggle(BuildContext context) {
    final bloc = context.read<TasksBloc>()..add(TaskStatusToggled(task.id));
    if (_done) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.taskCompletedMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => bloc.add(TaskStatusToggled(task.id)),
          ),
        ),
      );
  }

  void _delete(BuildContext context) =>
      context.read<TasksBloc>().add(TaskDeleted(task.id));

  void _duplicate(BuildContext context) {
    context.read<TasksBloc>().add(
      TaskCreateRequested(
        title: task.title,
        description: task.description,
        priority: task.priority,
        startDate: task.startDate,
        dueDate: task.dueDate,
      ),
    );
  }

  Future<void> _pickPriority(BuildContext context) async {
    final bloc = context.read<TasksBloc>();
    final l10n = context.l10n;
    final picked = await showCupertinoModalPopup<TaskPriority>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(l10n.priority),
        actions: [
          for (final p in TaskPriority.values)
            CupertinoActionSheetAction(
              isDefaultAction: p == task.priority,
              onPressed: () => Navigator.pop(sheetContext, p),
              child: PriorityBadge(priority: p),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (picked == null || picked == task.priority) return;
    bloc.add(
      TaskEdited(
        task.id,
        TaskDraft(
          title: task.title,
          description: task.description,
          priority: picked,
          startDate: task.startDate,
          dueDate: task.dueDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    final row = TaskRow(
      task: task,
      now: now,
      onToggle: () => _toggle(context),
      onTap: onOpen,
    );

    return CupertinoContextMenu.builder(
      enableHapticFeedback: true,
      actions: [
        _menuAction(
          context,
          icon: _done
              ? CupertinoIcons.arrow_uturn_left
              : CupertinoIcons.checkmark,
          label: _done ? l10n.taskActionReopen : l10n.taskActionComplete,
          onPressed: () => _toggle(context),
        ),
        _menuAction(
          context,
          icon: CupertinoIcons.pencil,
          label: l10n.taskActionEdit,
          onPressed: onEdit,
        ),
        _menuAction(
          context,
          icon: CupertinoIcons.doc_on_doc,
          label: l10n.taskActionDuplicate,
          onPressed: () => _duplicate(context),
        ),
        _menuAction(
          context,
          icon: CupertinoIcons.flag,
          label: l10n.taskActionPriority,
          onPressed: () => _pickPriority(context),
        ),
        _menuAction(
          context,
          icon: CupertinoIcons.person_badge_plus,
          label: l10n.shareWith,
          onPressed: onEdit,
        ),
        _menuAction(
          context,
          icon: CupertinoIcons.trash,
          label: l10n.taskActionDelete,
          destructive: true,
          onPressed: () => _delete(context),
        ),
      ],
      builder: (context, animation) {
        // Lifted preview: rounded, on its own surface. In the list it sits
        // flush inside its grouped section.
        if (animation.value > CupertinoContextMenu.animationOpensAt) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 340, child: row),
          );
        }
        return SwipeActions(
          leading: SwipeAction(
            icon: _done
                ? CupertinoIcons.arrow_uturn_left
                : CupertinoIcons.checkmark,
            label: _done ? l10n.taskActionReopen : l10n.taskActionComplete,
            color: colors.tint,
            onTriggered: () => _toggle(context),
          ),
          trailing: [
            SwipeAction(
              icon: CupertinoIcons.trash,
              label: l10n.taskActionDelete,
              color: colors.destructive,
              foreground: colors.onDestructive,
              onTriggered: () => _delete(context),
            ),
            SwipeAction(
              icon: CupertinoIcons.pencil,
              label: l10n.taskActionEdit,
              color: colors.labelSecondary,
              foreground: colors.surface,
              onTriggered: onEdit,
            ),
          ],
          child: row,
        );
      },
    );
  }

  /// Menu entry that closes the menu before acting, so sheets and
  /// snackbars open over the list rather than the menu.
  Widget _menuAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool destructive = false,
  }) {
    return CupertinoContextMenuAction(
      trailingIcon: icon,
      isDestructiveAction: destructive,
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
        onPressed();
      },
      child: Text(label),
    );
  }
}
