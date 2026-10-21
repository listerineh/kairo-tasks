import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/widgets/notification_bell.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/session/current_user.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../../core/widgets/kairo_entrance.dart';
import '../../../../core/widgets/kairo_tab_bar.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../../../tasks/presentation/widgets/task_feedback.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../../../tasks/presentation/widgets/task_list_item.dart';
import '../../domain/today_summary.dart';
import '../widgets/mascot/kairo_mascot.dart';

/// Hoy (docs/redesign-plan.md §2.3): Kairo with a suggestion, three
/// metrics, the dark "Ahora" card, today's pending tasks and the ones done.
/// Replaces the Dashboard and Tasks tabs.
class TodayPage extends StatefulWidget {
  const TodayPage({this.now, this.currentUserId, super.key});

  /// Reference time (tests); defaults to the clock.
  final DateTime Function()? now;

  /// Defaults to the signed-in user.
  final String? currentUserId;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  int _tip = 0;
  bool _showDone = false;
  bool _cheer = false;
  int? _lastDone;
  Timer? _cheerTimer;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  String? get _userId =>
      widget.currentUserId ??
      (getIt.isRegistered<CurrentUser>() ? getIt<CurrentUser>().id : null);

  @override
  void dispose() {
    _cheerTimer?.cancel();
    super.dispose();
  }

  /// A new completion shows "One less" for a moment.
  void _watchCompletions(int done) {
    final last = _lastDone;
    _lastDone = done;
    if (last == null || done <= last) return;
    _cheerTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _cheer = true);
    });
    _cheerTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _cheer = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TaskFeedbackListener(
      child: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          final now = _now;
          final summary = TodaySummary.from(
            state.tasks,
            now: now,
            userId: _userId,
          );
          _watchCompletions(summary.done.length);
          final loading =
              state.tasks.isEmpty &&
              (state.status == TasksStatus.initial ||
                  state.status == TasksStatus.loading);

          return Scaffold(
            backgroundColor: context.appColors.background,
            body: SafeArea(
              bottom: false,
              // Kairo styles carry no color; the legacy theme default is
              // secondary gray.
              child: DefaultTextStyle.merge(
                style: TextStyle(color: context.appColors.label),
                child: loading
                    ? const Center(child: CupertinoActivityIndicator())
                    : state.status == TasksStatus.error && state.tasks.isEmpty
                    ? _loadError(context)
                    : _content(context, summary, now),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, TodaySummary summary, DateTime now) {
    // Clear the floating tab bar (the shell's padding does not reach this
    // page's own Scaffold).
    final bottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      KairoTabBar.contentPadding(context),
    );
    final sections = <Widget>[
      _Header(now: now),
      _Hero(
        summary: summary,
        tip: _tipText(context, summary),
        onTapCat: () => setState(() {
          _tip++;
          _cheer = false;
        }),
      ),
      _Metrics(summary: summary),
      if (summary.next != null) _NowCard(summary: summary, now: now),
      ..._pending(context, summary, now),
      if (summary.done.isNotEmpty) _done(context, summary, now),
      Align(
        alignment: Alignment.centerLeft,
        child: KairoButton(
          label: context.l10n.viewAllTasks,
          variant: KairoButtonVariant.plain,
          onPressed: () => context.go('/dashboard/tasks'),
        ),
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
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.spacing12),
      itemBuilder: (context, i) =>
          KairoEntrance(index: i.clamp(0, 5), child: sections[i]),
    );
  }

  /// Without tasks a failed load must not look like an empty day.
  Widget _loadError(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: EmptyState(
          icon: CupertinoIcons.exclamationmark_triangle,
          title: l10n.tasksLoadError,
          action: KairoButton(
            label: l10n.tryAgain,
            variant: KairoButtonVariant.tinted,
            onPressed: () =>
                context.read<TasksBloc>().add(const TasksLoadRequested()),
          ),
        ),
      ),
    );
  }

  String _tipText(BuildContext context, TodaySummary summary) {
    final l10n = context.l10n;
    if (_cheer && summary.pending.isNotEmpty) return l10n.tipCheer;
    final tips = summary.tips;
    return switch (tips[_tip % tips.length]) {
      KairoTipKind.startWith => l10n.tipStartWith(summary.firstStep!.title),
      KairoTipKind.progress => l10n.tipProgress(
        summary.done.length,
        summary.total,
      ),
      KairoTipKind.focus => l10n.tipFocus,
      KairoTipKind.allDone => l10n.tipAllDone,
      KairoTipKind.rest => l10n.tipRest,
    };
  }

  List<Widget> _pending(
    BuildContext context,
    TodaySummary summary,
    DateTime now,
  ) {
    final l10n = context.l10n;
    final header = _SectionHeader(
      title: l10n.pendingTitle,
      trailing: summary.pending.isEmpty
          ? null
          : l10n.pendingCount(summary.pending.length),
    );
    if (summary.pending.isEmpty) {
      if (summary.done.isNotEmpty) return [header];
      return [
        header,
        KairoCard(
          child: EmptyState(
            icon: CupertinoIcons.sun_max,
            title: l10n.nothingForToday,
            message: l10n.nothingForTodayHint,
            action: KairoButton(
              label: l10n.newTask,
              icon: CupertinoIcons.plus,
              variant: KairoButtonVariant.tinted,
              onPressed: () => unawaited(showTaskForm(context)),
            ),
          ),
        ),
      ];
    }
    return [
      header,
      KairoCard(
        padding: EdgeInsets.zero,
        child: _TaskList(tasks: summary.pending, now: now),
      ),
    ];
  }

  Widget _done(BuildContext context, TodaySummary summary, DateTime now) {
    final motion = context.motion;
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _showDone,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
            onTap: () => setState(() => _showDone = !_showDone),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.spacing4),
                  Text(
                    context.l10n.doneTitle(summary.done.length),
                    style: context.typography.headline.copyWith(
                      color: colors.labelSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing4),
                  AnimatedRotation(
                    turns: _showDone ? 0.5 : 0,
                    duration: motion.duration(KairoSpring.snappy),
                    curve: motion.curve(KairoSpring.snappy),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: colors.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: motion.duration(KairoSpring.smooth),
          curve: motion.curve(KairoSpring.smooth),
          alignment: Alignment.topCenter,
          child: _showDone
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.spacing4),
                  child: KairoCard(
                    padding: EdgeInsets.zero,
                    child: _TaskList(tasks: summary.done, now: now),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final greeting = now.hour < 12
        ? l10n.greetMorning
        : now.hour < 19
        ? l10n.greetAfternoon
        : l10n.greetEvening;
    final date = DateFormat.MMMMEEEEd(locale).format(now);

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalized(date),
                  style: context.typography.subheadline.copyWith(
                    color: context.appColors.labelSecondary,
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(greeting, style: context.typography.largeTitle),
                ),
              ],
            ),
          ),
          const NotificationBell(),
        ],
      ),
    );
  }

  static String _capitalized(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.summary,
    required this.tip,
    required this.onTapCat,
  });

  final TodaySummary summary;
  final String tip;
  final VoidCallback onTapCat;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final l10n = context.l10n;

    return KairoCard(
      style: KairoCardStyle.hero,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacing8,
        AppSpacing.spacing16,
        AppSpacing.spacing16,
        AppSpacing.spacing16,
      ),
      child: Row(
        children: [
          KairoMascot(
            mood: summary.mood(),
            progress: summary.progress,
            hopTrigger: summary.done.length,
            size: 124,
            onTap: onTapCat,
            onLongPress: () => context.push('/focus'),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colors.tintSoft,
                    shape: const StadiumBorder(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      l10n.kairoSuggests,
                      style: context.typography.caption1.copyWith(
                        color: colors.tint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                AnimatedSwitcher(
                  duration: motion.duration(KairoSpring.smooth),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: Text(
                    tip,
                    key: ValueKey(tip),
                    style: context.typography.bodyMultiline,
                  ),
                ),
                if (summary.total > 0) ...[
                  const SizedBox(height: AppSpacing.spacing12),
                  _ProgressSegments(
                    done: summary.done.length,
                    total: summary.total,
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    l10n.doneOfTotal(summary.done.length, summary.total),
                    style: context.typography.footnote.copyWith(
                      color: colors.labelSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One segment per task (a continuous bar past 8), filled in [done] order.
class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final count = total > 8 ? 1 : total;

    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: count == 1 && total > 1
                      ? LinearProgressIndicator(
                          value: done / total,
                          color: colors.tint,
                          backgroundColor: colors.fill,
                        )
                      : AnimatedContainer(
                          duration: motion.duration(KairoSpring.smooth),
                          color: i < done ? colors.tint : colors.fill,
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final metrics = [
      _Metric(
        icon: CupertinoIcons.flame_fill,
        color: colors.apricot,
        value: '${summary.streak}',
        label: l10n.metricStreak,
      ),
      _Metric(
        icon: CupertinoIcons.exclamationmark_circle,
        color: summary.overdue > 0
            ? colors.priorityUrgent
            : colors.labelSecondary,
        value: '${summary.overdue}',
        label: l10n.metricOverdue,
      ),
      _Metric(
        icon: CupertinoIcons.checkmark_alt,
        color: colors.tint,
        value: '${(summary.progress * 100).round()}%',
        label: l10n.metricDay,
      ),
    ];
    // Three tiles in a row break words at large text sizes; stack them.
    if (isLargeText(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.spacing8),
            metrics[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.spacing8),
          Expanded(child: metrics[i]),
        ],
      ],
    );
  }
}

/// Text scaled past 140%, where side-by-side layouts stack.
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) > 14;

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: KairoCard(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              value,
              style: context.typography.title2.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              style: context.typography.caption1.copyWith(
                color: context.appColors.labelSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowCard extends StatelessWidget {
  const _NowCard({required this.summary, required this.now});

  final TodaySummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final task = summary.next!;
    final at = summary.nextAt!;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(at),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final minutes = at.difference(now).inMinutes;
    final when = minutes <= 0
        ? l10n.nowLabel
        : minutes <= 60
        ? l10n.inMinutes(minutes)
        : l10n.atTime(time);

    final title = Text(
      task.title,
      style: context.typography.title3.copyWith(color: colors.onInk),
    );
    final focus = KairoButton(
      label: l10n.focusAction,
      icon: CupertinoIcons.play_fill,
      variant: KairoButtonVariant.accent,
      onPressed: () => context.push('/focus', extra: task),
    );

    return KairoCard(
      style: KairoCardStyle.ink,
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: colors.lime,
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    when,
                    style: context.typography.caption1.copyWith(
                      color: colors.onLime,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: context.typography.footnote.copyWith(
                  color: colors.onInkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
          if (isLargeText(context)) ...[
            title,
            const SizedBox(height: AppSpacing.spacing12),
            focus,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: title),
                const SizedBox(width: AppSpacing.spacing12),
                focus,
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacing4,
        AppSpacing.spacing8,
        AppSpacing.spacing4,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: context.typography.title2),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: context.typography.subheadline.copyWith(
                color: context.appColors.labelSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Task rows (swipe, context menu, check) separated by hairlines.
class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.now});

  final List<TaskEntity> tasks;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final separator = context.appColors.separator;
    return Column(
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: separator),
          TaskListItem(
            key: ValueKey(tasks[i].id),
            task: tasks[i],
            now: now,
            onOpen: () => showTaskDetail(context, tasks[i]),
            onEdit: () => unawaited(showTaskForm(context, task: tasks[i])),
          ),
        ],
      ],
    );
  }
}
