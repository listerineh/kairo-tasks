import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kairotasks/core/extensions/context_extensions.dart';
import 'package:kairotasks/core/widgets/check_circle.dart';
import 'package:kairotasks/core/widgets/empty_state.dart';
import 'package:kairotasks/core/widgets/grouped_section.dart';
import 'package:kairotasks/core/widgets/kairo_avatar.dart';
import 'package:kairotasks/core/widgets/kairo_button.dart';
import 'package:kairotasks/core/widgets/kairo_card.dart';
import 'package:kairotasks/core/widgets/kairo_chip.dart';
import 'package:kairotasks/core/widgets/kairo_large_title_scaffold.dart';
import 'package:kairotasks/core/widgets/kairo_segmented_control.dart';
import 'package:kairotasks/core/widgets/kairo_sheet.dart';
import 'package:kairotasks/core/widgets/kairo_tab_bar.dart';
import 'package:kairotasks/core/widgets/priority_badge.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';

import '../helpers/golden.dart';

void main() {
  goldenTest(
    'kairo_button',
    size: const Size(390, 560),
    builder: (_) => GoldenCanvas(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KairoButton(label: 'Filled', onPressed: () {}),
            const SizedBox(height: 12),
            KairoButton(
              label: 'Outline',
              variant: KairoButtonVariant.outline,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            KairoButton(
              label: 'Tinted',
              icon: CupertinoIcons.plus,
              variant: KairoButtonVariant.tinted,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            KairoButton(
              label: 'Plain',
              variant: KairoButtonVariant.plain,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            KairoButton(label: 'Delete', destructive: true, onPressed: () {}),
            const SizedBox(height: 12),
            const KairoButton(label: 'Disabled', onPressed: null),
            const SizedBox(height: 12),
            KairoCard(
              style: KairoCardStyle.ink,
              child: KairoButton(
                label: 'Accent',
                variant: KairoButtonVariant.accent,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    ),
  );

  goldenTest(
    'grouped_section',
    size: const Size(390, 260),
    builder: (_) => GoldenCanvas(
      child: GroupedSection(
        header: 'Notifications',
        footer: 'Reminders arrive 10 minutes before a task starts.',
        children: [
          GroupedRow(
            leading: const Icon(CupertinoIcons.bell),
            title: 'Reminders',
            trailing: const Text('On'),
            showChevron: true,
            onTap: () {},
          ),
          GroupedRow(
            leading: const Icon(CupertinoIcons.person_2),
            title: 'Friend activity',
            subtitle: 'When a friend shares a task',
            showChevron: true,
            onTap: () {},
          ),
          GroupedRow(title: 'Sign out', destructive: true, onTap: () {}),
        ],
      ),
    ),
  );

  goldenTest(
    'task_rows',
    size: const Size(390, 260),
    builder: (_) => GoldenCanvas(
      child: GroupedSection(
        header: 'Today',
        children: [
          for (final (title, priority, done) in const [
            ('Call the dentist', TaskPriority.urgent, false),
            ('Write report', TaskPriority.high, true),
            ('Water the plants', TaskPriority.medium, false),
            ('Read a chapter', TaskPriority.low, false),
          ])
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 16),
              child: Row(
                children: [
                  CheckCircle(
                    value: done,
                    semanticLabel: title,
                    onChanged: (_) {},
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) => Text(
                        title,
                        style: context.typography.headline.copyWith(
                          color: context.appColors.label,
                        ),
                      ),
                    ),
                  ),
                  PriorityBadge(priority: priority),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  goldenTest(
    'avatar',
    size: const Size(390, 100),
    builder: (_) => const GoldenCanvas(
      child: Wrap(
        spacing: 12,
        children: [
          KairoAvatar(name: 'Ana Torres'),
          KairoAvatar(name: 'Luis'),
          KairoAvatar(name: 'María José Pérez', size: 56),
        ],
      ),
    ),
  );

  goldenTest(
    'segmented_control',
    size: const Size(390, 90),
    builder: (_) => GoldenCanvas(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: KairoSegmentedControl<int>(
          segments: const {0: 'Day', 1: 'Week', 2: 'Month'},
          selected: 1,
          onChanged: (_) {},
        ),
      ),
    ),
  );

  goldenTest(
    'empty_state',
    size: const Size(390, 340),
    builder: (_) => GoldenCanvas(
      child: EmptyState(
        icon: CupertinoIcons.tray,
        title: 'No tasks for today',
        message: 'Add one to plan your day, or enjoy the calm.',
        action: KairoButton(
          label: 'New task',
          variant: KairoButtonVariant.tinted,
          onPressed: () {},
        ),
      ),
    ),
  );

  goldenTest(
    'kairo_chips',
    size: const Size(390, 140),
    builder: (_) => GoldenCanvas(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            KairoChip(label: 'Hoy', selected: true, onSelected: () {}),
            KairoChip(label: 'Mañana', selected: false, onSelected: () {}),
            KairoChip(label: 'Este finde', selected: false, onSelected: () {}),
          ],
        ),
      ),
    ),
  );

  goldenTest(
    'kairo_cards',
    size: const Size(390, 300),
    builder: (context) => GoldenCanvas(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KairoCard(
              style: KairoCardStyle.hero,
              child: Text('Kairo sugiere', style: context.typography.title3),
            ),
            const SizedBox(height: 12),
            KairoCard(child: Text('Tile', style: context.typography.body)),
            const SizedBox(height: 12),
            KairoCard(
              style: KairoCardStyle.ink,
              child: Text('Ahora', style: context.typography.title3),
            ),
          ],
        ),
      ),
    ),
  );

  goldenTest(
    'tab_bar',
    size: const Size(390, 130),
    builder: (_) => Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: KairoTabBar(
          currentIndex: 0,
          onTap: (_) {},
          onCreate: () {},
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
      ),
    ),
  );

  goldenTest(
    'large_title_expanded',
    size: const Size(390, 360),
    builder: (_) => const _LargeTitleDemo(),
  );

  goldenTest(
    'large_title_collapsed',
    size: const Size(390, 360),
    builder: (_) => const _LargeTitleDemo(collapsed: true),
  );

  goldenTest(
    'sheet_medium',
    size: const Size(390, 700),
    builder: (_) => const _SheetDemo(),
  );
}

class _LargeTitleDemo extends StatefulWidget {
  const _LargeTitleDemo({this.collapsed = false});

  final bool collapsed;

  @override
  State<_LargeTitleDemo> createState() => _LargeTitleDemoState();
}

class _LargeTitleDemoState extends State<_LargeTitleDemo> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.collapsed) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _controller.jumpTo(200),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KairoLargeTitleScaffold(
      title: 'Tasks',
      controller: _controller,
      actions: [
        IconButton(
          tooltip: 'New task',
          icon: const Icon(CupertinoIcons.plus),
          onPressed: () {},
        ),
      ],
      slivers: [
        SliverList.list(
          children: [
            GroupedSection(
              header: 'Today',
              children: [
                for (var i = 1; i <= 12; i++) GroupedRow(title: 'Task $i'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SheetDemo extends StatefulWidget {
  const _SheetDemo();

  @override
  State<_SheetDemo> createState() => _SheetDemoState();
}

class _SheetDemoState extends State<_SheetDemo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showKairoSheet<void>(
        context: context,
        builder: (context, controller) => ListView(
          controller: controller,
          children: [
            GroupedSection(
              header: 'Share with',
              children: [
                for (final name in ['Ana Torres', 'Luis', 'María José'])
                  GroupedRow(
                    leading: KairoAvatar(name: name, size: 28),
                    title: name,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand());
  }
}
