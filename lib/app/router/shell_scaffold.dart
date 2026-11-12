import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/kairo_tab_bar.dart';
import '../../features/tasks/presentation/widgets/task_form_sheet.dart';

/// The app shell: four tabs (Hoy, Planear, Juntos, Yo) in the floating
/// `KairoTabBar`, with "new task" in the middle (docs/design.md
/// § Navigation). Content scrolls under the bar.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: KairoTabBar(
        currentIndex: navigationShell.currentIndex,
        // Tapping the current tab returns to its root (e.g. Tasks → Hoy).
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        onCreate: () => unawaited(showTaskForm(context)),
        createLabel: l10n.newTask,
        items: [
          KairoTabItem(
            icon: CupertinoIcons.sun_max,
            activeIcon: CupertinoIcons.sun_max_fill,
            label: l10n.navToday,
          ),
          KairoTabItem(
            icon: CupertinoIcons.calendar,
            activeIcon: CupertinoIcons.calendar_today,
            label: l10n.navPlan,
          ),
          KairoTabItem(
            icon: CupertinoIcons.person_2,
            activeIcon: CupertinoIcons.person_2_fill,
            label: l10n.navTogether,
          ),
          KairoTabItem(
            icon: CupertinoIcons.person_crop_circle,
            activeIcon: CupertinoIcons.person_crop_circle_fill,
            label: l10n.navMe,
          ),
        ],
      ),
    );
  }
}
