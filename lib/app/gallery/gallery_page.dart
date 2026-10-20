import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/check_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/grouped_section.dart';
import '../../core/widgets/kairo_avatar.dart';
import '../../core/widgets/kairo_button.dart';
import '../../core/widgets/kairo_large_title_scaffold.dart';
import '../../core/widgets/kairo_segmented_control.dart';
import '../../core/widgets/kairo_sheet.dart';
import '../../core/widgets/kairo_tab_bar.dart';
import '../../core/widgets/priority_badge.dart';
import '../../features/tasks/domain/entities/task_entity.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_service.dart';

/// Debug-only catalog of the Kairo 2.0 components (route `/gallery`).
///
/// Not localized on purpose: it never ships in release builds.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int _tab = 0;
  String _range = 'day';
  final _done = <String>{'Write report'};

  void _toggleTheme() {
    final dark = context.isDarkMode;
    ThemeService.instance.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.spacing32);

    return KairoLargeTitleScaffold(
      title: 'Components',
      actions: [
        IconButton(
          tooltip: 'Toggle dark mode',
          icon: Icon(
            context.isDarkMode ? CupertinoIcons.sun_max : CupertinoIcons.moon,
            color: context.appColors.tint,
          ),
          onPressed: _toggleTheme,
        ),
      ],
      bottomNavigationBar: KairoTabBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          KairoTabItem(
            icon: CupertinoIcons.square_grid_2x2,
            activeIcon: CupertinoIcons.square_grid_2x2_fill,
            label: 'Today',
          ),
          KairoTabItem(
            icon: CupertinoIcons.checkmark_circle,
            activeIcon: CupertinoIcons.checkmark_circle_fill,
            label: 'Tasks',
          ),
          KairoTabItem(
            icon: CupertinoIcons.person_2,
            activeIcon: CupertinoIcons.person_2_fill,
            label: 'Friends',
          ),
        ],
      ),
      slivers: [
        SliverList.list(
          children: [
            const SizedBox(height: AppSpacing.spacing16),
            _buttons(),
            gap,
            _settingsRows(),
            gap,
            _tasks(),
            gap,
            _segmented(),
            gap,
            _avatars(),
            gap,
            GroupedSection(
              header: 'Empty state',
              children: [
                EmptyState(
                  icon: CupertinoIcons.tray,
                  title: 'No tasks for today',
                  message: 'Add one to plan your day, or enjoy the calm.',
                  action: KairoButton(
                    label: 'New task',
                    icon: CupertinoIcons.plus,
                    variant: KairoButtonVariant.tinted,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            gap,
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: KairoButton(
                label: 'Open sheet',
                variant: KairoButtonVariant.tinted,
                expand: true,
                onPressed: _openSheet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buttons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KairoButton(label: 'Filled', onPressed: () {}),
          const SizedBox(height: AppSpacing.spacing12),
          KairoButton(
            label: 'Tinted',
            variant: KairoButtonVariant.tinted,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.spacing12),
          KairoButton(
            label: 'Plain',
            variant: KairoButtonVariant.plain,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.spacing12),
          KairoButton(label: 'Delete', destructive: true, onPressed: () {}),
          const SizedBox(height: AppSpacing.spacing12),
          const KairoButton(label: 'Disabled', onPressed: null),
          const SizedBox(height: AppSpacing.spacing12),
          KairoButton(label: 'Saving', loading: true, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _settingsRows() {
    return GroupedSection(
      header: 'Settings rows',
      footer: 'Footers explain a setting in one plain sentence.',
      children: [
        GroupedRow(
          leading: const Icon(CupertinoIcons.bell),
          title: 'Notifications',
          trailing: const Text('On'),
          showChevron: true,
          onTap: () {},
        ),
        GroupedRow(
          leading: const Icon(CupertinoIcons.textformat_size),
          title: 'Text size',
          subtitle: 'Follows the system setting',
          showChevron: true,
          onTap: () {},
        ),
        GroupedRow(title: 'Sign out', destructive: true, onTap: () {}),
      ],
    );
  }

  Widget _tasks() {
    const tasks = [
      ('Call the dentist', TaskPriority.urgent),
      ('Write report', TaskPriority.high),
      ('Water the plants', TaskPriority.medium),
      ('Read a chapter', TaskPriority.low),
    ];
    return GroupedSection(
      header: 'Tasks',
      children: [
        for (final (title, priority) in tasks)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.spacing16),
            child: Row(
              children: [
                const SizedBox(width: 4),
                CheckCircle(
                  value: _done.contains(title),
                  semanticLabel: title,
                  onChanged: (v) => setState(
                    () => v ? _done.add(title) : _done.remove(title),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: context.typography.headline.copyWith(
                      color: context.appColors.label,
                    ),
                  ),
                ),
                PriorityBadge(priority: priority),
              ],
            ),
          ),
      ],
    );
  }

  Widget _segmented() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: KairoSegmentedControl<String>(
        segments: const {'day': 'Day', 'week': 'Week', 'month': 'Month'},
        selected: _range,
        onChanged: (v) => setState(() => _range = v),
      ),
    );
  }

  Widget _avatars() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Wrap(
        spacing: AppSpacing.spacing12,
        children: [
          KairoAvatar(name: 'Ana Torres'),
          KairoAvatar(name: 'Luis'),
          KairoAvatar(name: 'María José Pérez', size: 56),
        ],
      ),
    );
  }

  Future<void> _openSheet() {
    return showKairoSheet<void>(
      context: context,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          GroupedSection(
            header: 'Inside a sheet',
            children: [
              for (var i = 1; i <= 12; i++) GroupedRow(title: 'Row $i'),
            ],
          ),
        ],
      ),
    );
  }
}
