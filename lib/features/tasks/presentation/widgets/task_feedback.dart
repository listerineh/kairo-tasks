import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/tasks_bloc.dart';
import 'task_detail_sheet.dart';
import 'task_form_sheet.dart';

/// Snackbars for task actions on any screen that lists tasks: a failed
/// action in plain language (technical details are logged by the bloc), and
/// "Task deleted · Undo" during the bloc's undo window.
class TaskFeedbackListener extends StatelessWidget {
  const TaskFeedbackListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // A failed load already shows its own full-screen state.
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
      child: child,
    );
  }

  static void _snack(
    BuildContext context,
    String message, {
    VoidCallback? undo,
  }) {
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
}

/// Opens [task]'s detail sheet; its Edit button opens the task form.
void showTaskDetail(BuildContext context, TaskEntity task) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TaskDetailSheet(
        task: task,
        onEdit: () {
          Navigator.pop(sheetContext);
          unawaited(showTaskForm(context, task: task));
        },
      ),
    ),
  );
}
