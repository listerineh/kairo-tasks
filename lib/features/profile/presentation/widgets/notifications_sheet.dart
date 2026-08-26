import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/notification_service.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';

// ignore_for_file: avoid_positional_boolean_parameters

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  bool _taskReminders = false;
  bool _friendActivity = false;
  bool _sharedTasks = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _taskReminders = prefs.getBool(NotificationService.kTaskReminders) ?? false;
      _friendActivity =
          prefs.getBool(NotificationService.kFriendActivity) ?? false;
      _sharedTasks =
          prefs.getBool(NotificationService.kSharedTaskUpdates) ?? false;
      _isLoading = false;
    });
  }

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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _SwitchTile(
                title: context.l10n.taskReminders,
                subtitle: context.l10n.subtitleNotificationsRemind,
                value: _taskReminders,
                onChanged: _onTaskRemindersChanged,
              ),
              _SwitchTile(
                title: context.l10n.friendActivity,
                subtitle: context.l10n.friendActivitySubtitle,
                value: _friendActivity,
                onChanged: (v) => _onRemoteToggleChanged(
                  v,
                  key: NotificationService.kFriendActivity,
                  setter: (value) => _friendActivity = value,
                ),
              ),
              _SwitchTile(
                title: context.l10n.sharedTaskUpdates,
                subtitle: context.l10n.sharedTaskUpdatesSubtitle,
                value: _sharedTasks,
                onChanged: (v) => _onRemoteToggleChanged(
                  v,
                  key: NotificationService.kSharedTaskUpdates,
                  setter: (value) => _sharedTasks = value,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.spacing16),
          ],
        ),
      ),
    );
  }

  Future<void> _onTaskRemindersChanged(bool value) async {
    if (value) await NotificationService.instance.requestPermission();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationService.kTaskReminders, value);

    if (!mounted) return;
    setState(() => _taskReminders = value);

    final tasks = context.read<TasksBloc>().state.tasks;
    await NotificationService.instance.onToggleTaskReminders(value, tasks: tasks);
  }

  Future<void> _onRemoteToggleChanged(
    bool value, {
    required String key,
    required void Function(bool) setter,
  }) async {
    if (value) {
      await NotificationService.instance.requestPermission();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (!mounted) return;
    setState(() => setter(value));

    if (value && Platform.isAndroid) {
      await NotificationService.instance.registerFcmToken();
    }

    if (value && Platform.isIOS && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.iOSRemoteNotAvailable)),
      );
    }
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
