import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/locale/locale_service.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/theme_service.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/grouped_section.dart';
import '../../../../core/widgets/kairo_avatar.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../../core/widgets/kairo_entrance.dart';
import '../../../../core/widgets/kairo_segmented_control.dart';
import '../../../../core/widgets/kairo_sheet.dart';
import '../../../../core/widgets/kairo_tab_bar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../calendar/presentation/widgets/calendar_colors.dart';
import '../../../calendar/presentation/widgets/tone_picker.dart';
import '../../../dashboard/domain/today_summary.dart';
import '../../../dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../../domain/entities/profile.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/kairo_lines.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/text_size_sheet.dart';

/// Yo (docs/design.md § Yo): who I am, Kairo, and every setting as an
/// iOS Settings-style grouped list.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.cubit, this.preferences, this.userId});

  /// Tests pass their own; the app builds them from DI.
  final ProfileCubit? cubit;
  final PreferencesService? preferences;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final injected = cubit;
    final view = ProfileView(
      preferences: preferences ?? registeredPreferences,
      userId: userId,
    );
    return injected != null
        ? BlocProvider.value(value: injected, child: view)
        : BlocProvider(
            create: (_) => getIt<ProfileCubit>()..load(),
            child: view,
          );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, this.preferences, this.userId, this.now});

  final PreferencesService? preferences;
  final String? userId;

  /// Fixed in goldens; otherwise the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (a, b) => b.status == AuthStatus.unauthenticated,
          listener: (context, _) => context.go('/login'),
        ),
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (a, b) => a.updateFailed != b.updateFailed,
          listener: (context, _) => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(context.l10n.settingSaveFailed),
                behavior: SnackBarBehavior.floating,
              ),
            ),
        ),
      ],
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: colors.label),
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) => switch (state.status) {
                ProfileStatus.loading => const Center(
                  child: CupertinoActivityIndicator(),
                ),
                ProfileStatus.failure => _loadError(context),
                ProfileStatus.ready => _content(context, state.profile!),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadError(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: EmptyState(
          icon: CupertinoIcons.exclamationmark_triangle,
          title: l10n.profileLoadError,
          action: KairoButton(
            label: l10n.tryAgain,
            variant: KairoButtonVariant.tinted,
            onPressed: () => context.read<ProfileCubit>().load(),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Profile profile) {
    final l10n = context.l10n;
    final cubit = context.read<ProfileCubit>();
    final prefs = preferences;
    final bottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      KairoTabBar.contentPadding(context),
    );

    final sections = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
        child: Semantics(
          header: true,
          child: Text(l10n.navMe, style: context.typography.largeTitle),
        ),
      ),
      _ProfileCard(profile: profile, onEdit: () => _openEdit(context)),
      _KairoRow(now: now, userId: userId ?? profile.id),
      _section(
        header: l10n.account,
        children: [
          GroupedRow(
            leading: const Icon(CupertinoIcons.person_crop_circle),
            title: l10n.editProfile,
            showChevron: true,
            onTap: () => _openEdit(context),
          ),
          GroupedRow(
            leading: const Icon(CupertinoIcons.circle_lefthalf_fill),
            title: l10n.myTaskColor,
            subtitle: l10n.myColorSubtitle,
            trailing: _Dot(color: CalendarTone.of(profile.color).dot),
            showChevron: true,
            onTap: () => _openColor(context, profile),
          ),
          GroupedRow(
            leading: const Icon(CupertinoIcons.eye),
            title: l10n.calendarPublicSetting,
            subtitle: profile.calendarPublic
                ? l10n.privacyPublic
                : l10n.privacyPrivate,
            trailing: _Switch(
              value: profile.calendarPublic,
              onChanged: (v) => cubit.setCalendarPublic(value: v),
            ),
          ),
        ],
      ),
      _section(
        header: l10n.preferences,
        children: [
          _ThemeRow(),
          _LanguageRow(),
          GroupedRow(
            leading: const Icon(CupertinoIcons.bell),
            title: l10n.notifications,
            showChevron: true,
            onTap: () => _openSheet(
              context,
              (controller) => NotificationsSheet(controller: controller),
            ),
          ),
        ],
      ),
      if (prefs != null)
        _section(
          header: l10n.accessibility,
          footer: l10n.reduceMotionHint,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: prefs.reduceMotion,
              builder: (context, value, _) => GroupedRow(
                leading: const Icon(CupertinoIcons.wand_rays),
                title: l10n.reduceMotion,
                trailing: _Switch(
                  value: value,
                  onChanged: (v) => prefs.setReduceMotion(value: v),
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: prefs.haptics,
              builder: (context, value, _) => GroupedRow(
                leading: const Icon(CupertinoIcons.waveform),
                title: l10n.hapticsSetting,
                trailing: _Switch(
                  value: value,
                  onChanged: (v) => prefs.setHaptics(value: v),
                ),
              ),
            ),
            ValueListenableBuilder<double?>(
              valueListenable: prefs.textScale,
              builder: (context, scale, _) => GroupedRow(
                leading: const Icon(CupertinoIcons.textformat_size),
                title: l10n.textSize,
                trailing: Text(
                  scale == null ? l10n.system : '${(scale * 100).round()}%',
                ),
                showChevron: true,
                onTap: () => _openSheet(
                  context,
                  (controller) =>
                      TextSizeSheet(preferences: prefs, controller: controller),
                ),
              ),
            ),
          ],
        ),
      _section(
        header: l10n.about,
        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) => GroupedRow(
              leading: const Icon(CupertinoIcons.info),
              title: l10n.version,
              trailing: Text(snapshot.data?.version ?? ''),
            ),
          ),
          GroupedRow(
            leading: const Icon(
              CupertinoIcons.chevron_left_slash_chevron_right,
            ),
            title: l10n.openSource,
            subtitle: l10n.openSourceSubtitle,
            showChevron: true,
            onTap: () => _openUrl('https://github.com/listerineh/kairo-tasks'),
          ),
          GroupedRow(
            leading: const Icon(CupertinoIcons.globe),
            title: l10n.developedBy,
            subtitle: l10n.developedBySubtitle,
            showChevron: true,
            onTap: () => _openUrl('https://listerineh.dev'),
          ),
          if (kDebugMode)
            GroupedRow(
              leading: const Icon(CupertinoIcons.square_grid_2x2),
              title: 'Component gallery',
              showChevron: true,
              onTap: () => context.push('/gallery'),
            ),
        ],
      ),
      _section(
        children: [
          GroupedRow(
            title: l10n.signOut,
            destructive: true,
            onTap: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
    ];

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.spacing12,
        AppSpacing.screenMargin,
        bottom,
      ),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.spacing16),
      itemBuilder: (context, i) =>
          KairoEntrance(index: i.clamp(0, 5), child: sections[i]),
    );
  }

  static Widget _section({
    required List<Widget> children,
    String? header,
    String? footer,
  }) => GroupedSection(
    header: header,
    footer: footer,
    margin: 0,
    children: children,
  );

  static void _openSheet(
    BuildContext context,
    Widget Function(ScrollController) builder,
  ) {
    unawaited(
      showKairoSheet<void>(
        context: context,
        builder: (context, controller) => builder(controller),
      ),
    );
  }

  /// Sheets live on the root navigator, above this page's provider.
  static void _openEdit(BuildContext context) {
    final cubit = context.read<ProfileCubit>()..clearError();
    unawaited(
      showKairoSheet<void>(
        context: context,
        detents: const [KairoSheetDetent.large],
        builder: (context, controller) => BlocProvider.value(
          value: cubit,
          child: EditProfileSheet(controller: controller),
        ),
      ),
    );
  }

  static void _openColor(BuildContext context, Profile profile) {
    final cubit = context.read<ProfileCubit>();
    unawaited(
      showKairoSheet<void>(
        context: context,
        detents: const [KairoSheetDetent.medium],
        builder: (context, controller) => BlocProvider.value(
          value: cubit,
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.spacing8,
                AppSpacing.screenMargin,
                AppSpacing.spacing32,
              ),
              children: [
                Text(
                  context.l10n.myTaskColor,
                  style: context.typography.title1,
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  context.l10n.myColorSubtitle,
                  style: context.typography.subheadline.copyWith(
                    color: context.appColors.labelSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                TonePicker(
                  selected: CalendarTone.of(state.profile?.color),
                  onPick: (tone) => cubit.setColor(TonePicker.hexOf(tone)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onEdit});

  final Profile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final email = profile.email;
    return Semantics(
      button: true,
      hint: context.l10n.editProfile,
      child: Pressable(
        onPressed: onEdit,
        child: KairoCard(
          style: KairoCardStyle.hero,
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Row(
            children: [
              KairoAvatar(
                name: profile.displayName,
                imageUrl: profile.avatarUrl,
                size: 64,
              ),
              const SizedBox(width: AppSpacing.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.displayName, style: context.typography.title3),
                    Text(
                      '@${profile.username}',
                      style: context.typography.subheadline.copyWith(
                        color: colors.labelSecondary,
                      ),
                    ),
                    if (email != null && email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.footnote.copyWith(
                          color: colors.labelSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: colors.labelTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kairo's row: a small Kairo in today's mood and what he'd say, opening
/// his page.
class _KairoRow extends StatelessWidget {
  const _KairoRow({required this.userId, this.now});

  final String userId;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        final summary = TodaySummary.from(
          state.tasks,
          now: now ?? DateTime.now(),
          userId: userId,
        );
        final mood = summary.mood();
        return Semantics(
          button: true,
          label: 'Kairo',
          hint: kairoLine(context, mood),
          excludeSemantics: true,
          child: Pressable(
            onPressed: () => context.push('/profile/kairo'),
            child: KairoCard(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IgnorePointer(
                    child: KairoMascot(
                      mood: mood,
                      progress: summary.progress,
                      size: 72,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kairo', style: context.typography.headline),
                        Text(
                          kairoLine(context, mood),
                          style: context.typography.footnote.copyWith(
                            color: colors.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: colors.labelTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, mode, _) => _ControlRow(
        icon: CupertinoIcons.circle_righthalf_fill,
        title: l10n.appearance,
        control: KairoSegmentedControl<ThemeMode>(
          segments: {
            ThemeMode.system: l10n.system,
            ThemeMode.light: l10n.light,
            ThemeMode.dark: l10n.dark,
          },
          selected: mode,
          onChanged: ThemeService.instance.setThemeMode,
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.locale,
      builder: (context, locale, _) => _ControlRow(
        icon: CupertinoIcons.globe,
        title: l10n.language,
        control: KairoSegmentedControl<String>(
          segments: {'es': l10n.spanish, 'en': l10n.english},
          selected: locale.languageCode,
          onChanged: (code) => LocaleService.instance.setLocale(Locale(code)),
        ),
      ),
    );
  }
}

/// A row with its title on top and a full-width control below, for
/// segmented choices that don't fit beside the title.
class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.icon,
    required this.title,
    required this.control,
  });

  final IconData icon;
  final String title;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Icon(icon, size: 22, color: colors.tint),
              ),
              const SizedBox(width: 12),
              Text(title, style: context.typography.body),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          control,
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CupertinoSwitch(
    value: value,
    activeTrackColor: context.appColors.tint,
    onChanged: onChanged,
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
