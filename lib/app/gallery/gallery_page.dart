import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/grouped_section.dart';
import '../../core/widgets/kairo_avatar.dart';
import '../../core/widgets/kairo_button.dart';
import '../../core/widgets/kairo_card.dart';
import '../../core/widgets/kairo_chip.dart';
import '../../core/widgets/kairo_entrance.dart';
import '../../core/widgets/kairo_large_title_scaffold.dart';
import '../../core/widgets/kairo_segmented_control.dart';
import '../../core/widgets/kairo_sheet.dart';
import '../../core/widgets/kairo_tab_bar.dart';
import '../../core/widgets/swipe_actions.dart';
import '../../features/dashboard/domain/mascot/mascot_mood.dart';
import '../../features/dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import '../../features/tasks/domain/entities/task_entity.dart';
import '../../features/tasks/presentation/widgets/task_row.dart';
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
  MascotMood _mood = MascotMood.idle;
  int _hops = 0;
  final _done = <String>{};
  final _deleted = <String>{};

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
        onCreate: _openSheet,
        createLabel: 'New task',
        items: const [
          KairoTabItem(
            icon: CupertinoIcons.sun_max,
            activeIcon: CupertinoIcons.sun_max_fill,
            label: 'Hoy',
          ),
          KairoTabItem(
            icon: CupertinoIcons.calendar,
            activeIcon: CupertinoIcons.calendar,
            label: 'Planear',
          ),
          KairoTabItem(
            icon: CupertinoIcons.person_2,
            activeIcon: CupertinoIcons.person_2_fill,
            label: 'Juntos',
          ),
          KairoTabItem(
            icon: CupertinoIcons.person_crop_circle,
            activeIcon: CupertinoIcons.person_crop_circle_fill,
            label: 'Yo',
          ),
        ],
      ),
      slivers: [
        SliverList.list(
          children: [
            const SizedBox(height: AppSpacing.spacing16),
            _buttons(),
            gap,
            const _CardsAndChips(),
            gap,
            _settingsRows(),
            gap,
            _tasks(),
            gap,
            _segmented(),
            gap,
            _avatars(),
            gap,
            _cat(),
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
            label: 'Outline',
            variant: KairoButtonVariant.outline,
            onPressed: () {},
          ),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tasks = [
      TaskEntity(
        id: 'dentist',
        ownerId: 'me',
        title: 'Call the dentist',
        priority: TaskPriority.urgent,
        startDate: today.add(const Duration(hours: 10)),
        dueDate: today.add(const Duration(hours: 10, minutes: 30)),
        sharedWith: const [
          {'display_name': 'Ana'},
        ],
        createdAt: today,
      ),
      TaskEntity(
        id: 'report',
        ownerId: 'me',
        title: 'Write report',
        priority: TaskPriority.high,
        dueDate: today.add(const Duration(days: 1, hours: 9)),
        createdAt: today,
      ),
      TaskEntity(
        id: 'plants',
        ownerId: 'me',
        title: 'Water the plants',
        createdAt: today,
      ),
      TaskEntity(
        id: 'book',
        ownerId: 'me',
        title: 'Read a chapter',
        priority: TaskPriority.low,
        createdAt: today,
      ),
    ];
    final colors = context.appColors;
    return GroupedSection(
      header: 'Tasks (swipe either way)',
      separatorInset: TaskRow.separatorInset,
      children: [
        for (final t in tasks)
          if (!_deleted.contains(t.id))
            SwipeActions(
              leading: SwipeAction(
                icon: CupertinoIcons.checkmark,
                label: 'Complete',
                color: colors.tint,
                onTriggered: () => _toggleDemo(t.id),
              ),
              trailing: [
                SwipeAction(
                  icon: CupertinoIcons.trash,
                  label: 'Delete',
                  color: colors.destructive,
                  foreground: colors.onDestructive,
                  onTriggered: () => setState(() => _deleted.add(t.id)),
                ),
                SwipeAction(
                  icon: CupertinoIcons.pencil,
                  label: 'Edit',
                  color: colors.labelSecondary,
                  foreground: colors.surface,
                  onTriggered: () {},
                ),
              ],
              child: TaskRow(
                task: _done.contains(t.id)
                    ? t.copyWith(status: TaskStatus.completed)
                    : t,
                now: now,
                onToggle: () => _toggleDemo(t.id),
              ),
            ),
      ],
    );
  }

  void _toggleDemo(String id) =>
      setState(() => _done.contains(id) ? _done.remove(id) : _done.add(id));

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

  Widget _cat() {
    return GroupedSection(
      header: 'Kairo the cat',
      footer: 'Tap the cat to pet it. Hop simulates a completed task.',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            children: [
              KairoMascot(mood: _mood, hopTrigger: _hops, size: 140),
              const SizedBox(height: AppSpacing.spacing16),
              KairoSegmentedControl<MascotMood>(
                segments: {for (final m in MascotMood.values) m: m.name},
                selected: _mood,
                onChanged: (m) => setState(() => _mood = m),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              KairoButton(
                label: 'Hop',
                variant: KairoButtonVariant.plain,
                onPressed: () => setState(() => _hops++),
              ),
            ],
          ),
        ),
      ],
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

class _CardsAndChips extends StatefulWidget {
  const _CardsAndChips();

  @override
  State<_CardsAndChips> createState() => _CardsAndChipsState();
}

class _CardsAndChipsState extends State<_CardsAndChips> {
  String _day = 'Hoy';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: [
              for (final day in const ['Hoy', 'Mañana', 'Este finde'])
                KairoChip(
                  label: day,
                  selected: _day == day,
                  onSelected: () => setState(() => _day = day),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
          KairoEntrance(
            child: KairoCard(
              style: KairoCardStyle.hero,
              child: Text('Hero card', style: context.typography.title3),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          KairoEntrance(
            index: 1,
            child: KairoCard(
              style: KairoCardStyle.ink,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Escribir informe Q3',
                      style: context.typography.title3.copyWith(
                        color: colors.onInk,
                      ),
                    ),
                  ),
                  KairoButton(
                    label: 'Enfocar',
                    icon: CupertinoIcons.play_fill,
                    variant: KairoButtonVariant.accent,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
