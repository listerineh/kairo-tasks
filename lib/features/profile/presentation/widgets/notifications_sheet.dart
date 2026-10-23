import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/grouped_section.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';

/// Which pushes and reminders to get, stored on the device.
class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({required this.controller, super.key});

  final ScrollController controller;

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  bool _taskReminders = false;
  bool _friendActivity = true;
  bool _sharedTasks = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _taskReminders =
          prefs.getBool(NotificationService.kTaskReminders) ?? false;
      _friendActivity =
          prefs.getBool(NotificationService.kFriendActivity) ?? true;
      _sharedTasks =
          prefs.getBool(NotificationService.kSharedTaskUpdates) ?? true;
      _loading = false;
    });
  }

  Future<void> _setReminders({required bool value}) async {
    if (value) await _askPermission();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationService.kTaskReminders, value);
    if (!mounted) return;
    setState(() => _taskReminders = value);
    final tasks = context.read<TasksBloc>().state.tasks;
    await NotificationService.instance.onToggleTaskReminders(
      value,
      tasks: tasks,
    );
  }

  Future<void> _setRemote(String key, {required bool value}) async {
    if (value) await _askPermission();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() {
      if (key == NotificationService.kFriendActivity) _friendActivity = value;
      if (key == NotificationService.kSharedTaskUpdates) _sharedTasks = value;
    });
    if (value) {
      try {
        await NotificationService.instance.registerFcmToken();
      } on Exception {
        // FCM can fail on iOS without APNs; the choice is kept anyway.
      }
    }
  }

  Future<void> _askPermission() async {
    try {
      await NotificationService.instance.requestPermission();
    } on Exception {
      // The switch stays on; the OS will ask again later.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    Widget toggle({
      required bool value,
      required ValueChanged<bool> onChanged,
    }) => CupertinoSwitch(
      value: value,
      activeTrackColor: colors.tint,
      onChanged: onChanged,
    );

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(
        0,
        AppSpacing.spacing8,
        0,
        AppSpacing.spacing32,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
          ),
          child: Semantics(
            header: true,
            child: Text(l10n.notifications, style: context.typography.title1),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        if (_loading)
          const Center(child: CupertinoActivityIndicator())
        else
          GroupedSection(
            footer: l10n.notificationsSubtitle,
            children: [
              GroupedRow(
                title: l10n.taskReminders,
                subtitle: l10n.subtitleNotificationsRemind,
                trailing: toggle(
                  value: _taskReminders,
                  onChanged: (v) => _setReminders(value: v),
                ),
              ),
              GroupedRow(
                title: l10n.friendActivity,
                subtitle: l10n.friendActivitySubtitle,
                trailing: toggle(
                  value: _friendActivity,
                  onChanged: (v) =>
                      _setRemote(NotificationService.kFriendActivity, value: v),
                ),
              ),
              GroupedRow(
                title: l10n.sharedTaskUpdates,
                subtitle: l10n.sharedTaskUpdatesSubtitle,
                trailing: toggle(
                  value: _sharedTasks,
                  onChanged: (v) => _setRemote(
                    NotificationService.kSharedTaskUpdates,
                    value: v,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.spacing16),
        GroupedSection(
          children: [
            GroupedRow(
              title: l10n.viewNotificationHistory,
              showChevron: true,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/notifications');
              },
            ),
          ],
        ),
      ],
    );
  }
}
