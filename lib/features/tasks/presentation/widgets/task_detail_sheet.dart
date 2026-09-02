import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/task_entity.dart';

class TaskDetailSheet extends StatelessWidget {
  const TaskDetailSheet({
    required this.task,
    this.onEdit,
    super.key,
  });

  final TaskEntity task;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.spacing48),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.spacing24,
        AppSpacing.spacing16,
        AppSpacing.spacing24,
        AppSpacing.spacing24 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLarge),
          topRight: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              task.title,
              style: context.textTheme.headlineSmall,
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.spacing12),
              Text(
                task.description!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.spacing16),
            Wrap(
              spacing: AppSpacing.spacing8,
              runSpacing: AppSpacing.spacing8,
              children: [
                _StatusChip(task: task, colors: colors),
                _PriorityChip(task: task, colors: colors),
              ],
            ),
            if (task.startDate != null || task.dueDate != null) ...[
              const SizedBox(height: AppSpacing.spacing16),
              _DateSection(task: task, colors: colors),
            ],
            if (task.isShared) ...[
              const SizedBox(height: AppSpacing.spacing16),
              _SharedSection(task: task, colors: colors),
            ],
            const SizedBox(height: AppSpacing.spacing24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onEdit,
                child: Text(context.l10n.editTask),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            _SoftReminderSection(task: task),
          ],
        ),
      ),
    );
  }
}

class _SoftReminderSection extends StatelessWidget {
  const _SoftReminderSection({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const options = [10, 15, 30, 60];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.remindMe,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Wrap(
          spacing: AppSpacing.spacing8,
          children: options
              .map(
                (minutes) => ActionChip(
                  label: Text(context.l10n.remindInMinutes(minutes)),
                  onPressed: () => _schedule(context, minutes),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<void> _schedule(BuildContext context, int minutes) async {
    await NotificationService.instance.scheduleSoftReminder(
      taskId: task.id,
      taskTitle: task.title,
      delay: Duration(minutes: minutes),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.reminderSet(minutes)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.task, required this.colors});

  final TaskEntity task;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    return _Chip(
      icon: isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
      label: _capitalize(task.status.name),
      color: isCompleted ? colors.accent : colors.textMuted,
      colors: colors,
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.task, required this.colors});

  final TaskEntity task;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      icon: Icons.flag,
      label: _capitalize(task.priority.name),
      color: _priorityColor(colors, task.priority),
      colors: colors,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final Color color;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.spacing8),
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({required this.task, required this.colors});

  final TaskEntity task;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.when,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        if (task.startDate != null)
          _DateRow(
            icon: Icons.play_arrow,
            label: context.l10n.starts,
            value: _formatDateTime(task.startDate!),
            colors: colors,
          ),
        if (task.dueDate != null)
          _DateRow(
            icon: Icons.flag,
            label: context.l10n.due,
            value: _formatDateTime(task.dueDate!),
            colors: colors,
          ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textMuted),
          const SizedBox(width: AppSpacing.spacing8),
          Text(
            '$label: ',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SharedSection extends StatelessWidget {
  const _SharedSection({required this.task, required this.colors});

  final TaskEntity task;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = task.ownerId == currentUserId;
    final count = task.sharedWith.length;
    final header = isOwner
        ? 'Shared with $count ${count == 1 ? 'friend' : 'friends'}'
        : 'Shared by';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        ...task.sharedWith
            .map((friend) => _SharedRow(friend: friend, colors: colors)),
      ],
    );
  }
}

class _SharedRow extends StatelessWidget {
  const _SharedRow({
    required this.friend,
    required this.colors,
  });

  final Map<String, dynamic> friend;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final displayName = friend['display_name'] as String? ?? '';
    final username = friend['username'] as String? ?? '';
    final avatarUrl = friend['avatar_url'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.accentSoft,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    (displayName.isNotEmpty ? displayName[0] : '?')
                        .toUpperCase(),
                    style: context.textTheme.titleSmall?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty
                      ? displayName
                      : (username.isNotEmpty ? '@$username' : context.l10n.shared),
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (displayName.isNotEmpty && username.isNotEmpty)
                  Text(
                    '@$username',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day}/${local.month}/${local.year} at $hour:$minute';
}

Color _priorityColor(AppColorScheme colors, TaskPriority priority) {
  switch (priority) {
    case TaskPriority.urgent:
      return colors.urgent;
    case TaskPriority.high:
      return colors.high;
    case TaskPriority.medium:
      return colors.medium;
    case TaskPriority.low:
      return colors.low;
  }
}
