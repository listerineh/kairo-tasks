import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/notification_store.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: NotificationStore.instance.markAllRead,
            child: Text(l10n.markAllAsRead),
          ),
        ],
      ),
      backgroundColor: colors.surface,
      body: ValueListenableBuilder(
        valueListenable: NotificationStore.instance.notifications,
        builder: (context, list, _) {
          if (list.isEmpty) {
            return Center(child: Text(l10n.noNotifications));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final n = list[index];
              return ListTile(
                tileColor:
                    n.read ? null : colors.accentSoft.withValues(alpha: 0.15),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.body),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(n.createdAt),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                trailing: n.read
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.mark_email_read_outlined),
                        onPressed: () =>
                            NotificationStore.instance.markRead(n.id),
                      ),
                onTap: () => NotificationStore.instance.markRead(n.id),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
