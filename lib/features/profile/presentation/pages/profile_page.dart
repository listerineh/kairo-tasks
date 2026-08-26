import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/appearance_sheet.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/notifications_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;

    final displayName =
        metadata?['display_name'] as String? ??
        metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        user?.email?.split('@').first ??
        'User';
    final email = user?.email ?? '';
    final avatarUrl = metadata?['avatar_url'] as String? ??
        metadata?['picture'] as String?;
    final createdAt = user?.createdAt;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.spacing24),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.spacing24),

                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: colors.accentSoft,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: context.textTheme.displaySmall?.copyWith(
                            color: colors.accent,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.spacing16),

                // Name
                Text(
                  displayName,
                  style: context.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.spacing4),

                // Email
                Text(
                  email,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),

                // Member since
                if (createdAt != null)
                  Text(
                    'Member since ${_formatDate(createdAt)}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                const SizedBox(height: AppSpacing.spacing32),

                // Settings section
                const _SectionHeader(title: 'Account'),
                const SizedBox(height: AppSpacing.spacing12),

                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => _showEditProfileSheet(context),
                ),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme, colors',
                  onTap: () => _showAppearanceSheet(context),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => _showNotificationsSheet(context),
                ),

                const SizedBox(height: AppSpacing.spacing24),
                const _SectionHeader(title: 'About'),
                const SizedBox(height: AppSpacing.spacing12),

                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData
                        ? snapshot.data!.version
                        : '...';
                    return _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'Version',
                      subtitle: version,
                      onTap: null,
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.code,
                  title: 'Open Source',
                  subtitle: 'View on GitHub',
                  onTap: () {
                    // TODO: Open GitHub repo
                  },
                ),

                const SizedBox(height: AppSpacing.spacing32),

                // Sign out button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context
                          .read<AuthBloc>()
                          .add(const AuthSignOutRequested());
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.urgent,
                      side: BorderSide(color: colors.urgent),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditProfileSheet(),
    );
  }

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppearanceSheet(
        currentMode: ThemeMode.system,
        onChanged: (mode) {
          // Theme changes require app-level rebuild; kept as placeholder
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          color: context.appColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListTile(
      leading: Icon(icon, color: colors.textSecondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: colors.textMuted)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
