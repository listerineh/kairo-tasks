import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

// TODO: Connect to push notification permissions and user preferences.
// The toggles are currently local placeholders. When FCM is implemented,
// persist choices in Supabase `profiles` table and request notification
// permissions. Also wire task reminders, friend activity, and shared task
// updates to the notification service.
class _NotificationsSheetState extends State<NotificationsSheet> {
  bool _taskReminders = true;
  bool _friendActivity = true;
  bool _sharedTasks = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
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
            const SizedBox(height: AppSpacing.spacing24),
            Text(context.l10n.notifications,
                style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              context.l10n.notificationsSubtitle,
              style: context.textTheme.bodySmall
                  ?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.spacing20),
            _SwitchTile(
              title: context.l10n.taskReminders,
              subtitle: context.l10n.subtitleNotificationsRemind,
              value: _taskReminders,
              onChanged: (v) => setState(() => _taskReminders = v),
            ),
            _SwitchTile(
              title: context.l10n.friendActivity,
              subtitle: context.l10n.friendActivitySubtitle,
              value: _friendActivity,
              onChanged: (v) => setState(() => _friendActivity = v),
            ),
            _SwitchTile(
              title: context.l10n.sharedTaskUpdates,
              subtitle: context.l10n.sharedTaskUpdatesSubtitle,
              value: _sharedTasks,
              onChanged: (v) => setState(() => _sharedTasks = v),
            ),
            const SizedBox(height: AppSpacing.spacing16),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.accent,
          ),
        ],
      ),
    );
  }
}
