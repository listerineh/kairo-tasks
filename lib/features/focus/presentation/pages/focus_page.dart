import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/session/current_user.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../dashboard/domain/mascot/mascot_mood.dart';
import '../../../dashboard/domain/today_summary.dart';
import '../../../dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../../domain/focus_session.dart';
import '../cubit/focus_cubit.dart';
import '../cubit/focus_state.dart';

/// Foco (docs/design.md § Focus screen): dark whatever the theme, a lime
/// ring that drains, Kairo concentrating with you, rounds and rests.
class FocusPage extends StatelessWidget {
  const FocusPage({this.initialTask, this.cubit, super.key});

  /// Starts on this task (from Hoy's "Ahora" card).
  final TaskEntity? initialTask;

  /// Defaults to the app-wide session.
  final FocusCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: BlocProvider.value(
        value: cubit ?? getIt<FocusCubit>(),
        child: _FocusView(initialTask: initialTask),
      ),
    );
  }
}

class _FocusView extends StatefulWidget {
  const _FocusView({this.initialTask});

  final TaskEntity? initialTask;

  @override
  State<_FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends State<_FocusView> {
  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    if (task == null) return;
    final cubit = context.read<FocusCubit>();
    // Opening Focus on another task starts over; the same one continues.
    if (!cubit.state.chosen || cubit.state.task?.id != task.id) {
      cubit.choose(task);
    }
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colors.label),
          child: BlocBuilder<FocusCubit, FocusState>(
            builder: (context, state) => Column(
              children: [
                _TopBar(state: state, onClose: () => _leave(context)),
                Expanded(
                  child: state.chosen
                      ? _Timer(state: state)
                      : const _TaskPicker(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.onClose});

  final FocusState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final session = state.session;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: AppSpacing.spacing8,
      ),
      child: Row(
        children: [
          _RoundButton(
            label: l10n.focusLeave,
            onPressed: onClose,
            child: Icon(CupertinoIcons.xmark, size: 18, color: colors.label),
          ),
          const Spacer(),
          if (state.chosen)
            Semantics(
              label: l10n.focusRoundOf(session.round, FocusSession.rounds),
              excludeSemantics: true,
              child: Row(
                children: [
                  for (var i = 1; i <= FocusSession.rounds; i++) ...[
                    if (i > 1) const SizedBox(width: 6),
                    Container(
                      width: 22,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color:
                            i < session.round ||
                                (i == session.round &&
                                    session.phase == FocusPhase.rest)
                            ? colors.lime
                            : i == session.round
                            ? colors.lime.withValues(alpha: 0.45)
                            : colors.fill,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _TaskPicker extends StatelessWidget {
  const _TaskPicker();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final me = getIt.isRegistered<CurrentUser>()
        ? getIt<CurrentUser>().id
        : null;

    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, tasks) {
        final now = DateTime.now();
        final today = TodaySummary.from(tasks.tasks, now: now, userId: me);
        final rest = [
          for (final t in tasks.tasks)
            if (t.status != TaskStatus.completed &&
                (me == null || t.ownerId == me) &&
                !today.pending.contains(t))
              t,
        ]..sort((a, b) => a.priority.index.compareTo(b.priority.index));
        final options = [...today.pending, ...rest];

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.spacing8,
            AppSpacing.screenMargin,
            AppSpacing.spacing32,
          ),
          children: [
            const Center(
              child: KairoMascot(mood: MascotMood.focused, size: 120),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            Semantics(
              header: true,
              child: Text(
                l10n.focusPickTitle,
                textAlign: TextAlign.center,
                style: context.typography.title1,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing20),
            if (options.isNotEmpty)
              KairoCard(
                padding: EdgeInsets.zero,
                // ListTile ink needs a Material above it, inside the card.
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      for (var i = 0; i < options.length && i < 8; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colors.separator,
                          ),
                        ListTile(
                          minVerticalPadding: 12,
                          title: Text(
                            options[i].title,
                            style: context.typography.body,
                          ),
                          trailing: Icon(
                            CupertinoIcons.play_circle_fill,
                            color: colors.lime,
                          ),
                          onTap: () =>
                              context.read<FocusCubit>().choose(options[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.spacing16),
            KairoButton(
              label: l10n.focusJustFocus,
              variant: KairoButtonVariant.accent,
              expand: true,
              onPressed: () => context.read<FocusCubit>().choose(null),
            ),
          ],
        );
      },
    );
  }
}

class _Timer extends StatelessWidget {
  const _Timer({required this.state});

  final FocusState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final cubit = context.read<FocusCubit>();
    final rest = state.session.phase == FocusPhase.rest;
    final left = state.remaining;
    final clock =
        '${left.inMinutes.toString().padLeft(2, '0')}:'
        '${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    final status = state.finished
        ? l10n.focusComplete
        : !state.running
        ? l10n.focusPaused
        : rest
        ? l10n.focusRestHint
        : l10n.focusBreathe;
    final mood = state.finished
        ? MascotMood.happy
        : state.running && !rest
        ? MascotMood.focused
        : MascotMood.idle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final ring = math.min<double>(310, constraints.maxWidth - 64);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: AppSpacing.spacing12),
                    Text(
                      rest ? l10n.focusRestTitle : l10n.focusOn,
                      style: context.typography.footnote.copyWith(
                        color: colors.labelSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      state.task?.title ?? l10n.focusJustFocus,
                      textAlign: TextAlign.center,
                      style: context.typography.title2,
                    ),
                    if (!rest)
                      CupertinoButton(
                        minimumSize: const Size(44, 44),
                        onPressed: cubit.changeTask,
                        child: Text(
                          l10n.focusChange,
                          style: context.typography.subheadline.copyWith(
                            color: colors.lime,
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.spacing24,
                  ),
                  child: _Ring(
                    size: ring,
                    progress: state.progress,
                    running: state.running,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: KairoMascot(
                            mood: mood,
                            progress: state.progress,
                            size: ring * 0.34,
                          ),
                        ),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            clock,
                            style: context.typography.timer,
                            textScaler: MediaQuery.textScalerOf(context)
                                .clamp(maxScaleFactor: 1.2),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacing4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            // Inside the ring there is no room to grow.
                            textScaler: MediaQuery.textScalerOf(context)
                                .clamp(maxScaleFactor: 1.2),
                            style: context.typography.subheadline.copyWith(
                              color: colors.labelSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.spacing24),
                  child: state.finished
                      ? _FinishedActions(state: state)
                      : _Controls(state: state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final FocusState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final cubit = context.read<FocusCubit>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          label: l10n.focusReset,
          size: 60,
          onPressed: cubit.reset,
          child: Icon(
            CupertinoIcons.arrow_counterclockwise,
            color: colors.label,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing24),
        _RoundButton(
          label: state.running ? l10n.focusPause : l10n.focusResume,
          size: 84,
          color: colors.lime,
          onPressed: cubit.toggle,
          child: Icon(
            state.running
                ? CupertinoIcons.pause_fill
                : CupertinoIcons.play_fill,
            size: 32,
            color: colors.onLime,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing24),
        _RoundButton(
          label: l10n.focusAddFive,
          size: 60,
          onPressed: cubit.addExtra,
          child: Text(
            '+5',
            style: context.typography.headline.copyWith(color: colors.label),
          ),
        ),
      ],
    );
  }
}

/// After a phase: rest (or complete the task), or the next round.
class _FinishedActions extends StatelessWidget {
  const _FinishedActions({required this.state});

  final FocusState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<FocusCubit>();
    final task = state.task;
    final rest = state.session.phase == FocusPhase.rest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KairoButton(
          label: rest ? l10n.focusNextRound : l10n.focusTakeRest,
          variant: KairoButtonVariant.accent,
          expand: true,
          onPressed: cubit.next,
        ),
        if (!rest && task != null) ...[
          const SizedBox(height: AppSpacing.spacing12),
          KairoButton(
            label: l10n.completeTask,
            variant: KairoButtonVariant.outline,
            icon: CupertinoIcons.checkmark_alt,
            expand: true,
            onPressed: () {
              context.read<TasksBloc>().add(TaskStatusToggled(task.id));
              cubit.next();
            },
          ),
        ],
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.onPressed,
    required this.child,
    this.size = 44,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget child;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: color ?? context.appColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// The lime ring: the remaining time drains clockwise from the top, with a
/// dot at its head; a soft halo breathes while the timer runs.
class _Ring extends StatefulWidget {
  const _Ring({
    required this.size,
    required this.progress,
    required this.running,
    required this.child,
  });

  final double size;
  final double progress;
  final bool running;
  final Widget child;

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> with SingleTickerProviderStateMixin {
  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Ring oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final breathe = widget.running && context.motion.ambient;
    if (breathe && !_halo.isAnimating) {
      _halo.repeat(reverse: true);
    } else if (!breathe && _halo.isAnimating) {
      _halo
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _halo,
            builder: (context, _) => Transform.scale(
              scale: 1 + 0.03 * _halo.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.lime.withValues(
                      alpha: widget.running ? 0.12 + 0.25 * _halo.value : 0,
                    ),
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: widget.progress),
              duration: context.motion.duration(KairoSpring.smooth),
              builder: (context, progress, _) => CustomPaint(
                size: Size.square(widget.size - 16),
                painter: _RingPainter(
                  progress: progress,
                  track: colors.fill,
                  arc: colors.lime,
                  head: colors.background,
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.arc,
    required this.head,
  });

  final double progress;
  final Color track;
  final Color arc;
  final Color head;

  static const _stroke = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(_stroke / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ring, 0, math.pi * 2, false, stroke..color = track);

    final left = (1 - progress).clamp(0.0, 1.0);
    if (left <= 0) return;
    final start = -math.pi / 2 + math.pi * 2 * progress;
    canvas.drawArc(ring, start, math.pi * 2 * left, false, stroke..color = arc);

    final center = ring.center;
    final r = ring.width / 2;
    final dot = center + Offset(math.cos(start), math.sin(start)) * r;
    canvas
      ..drawCircle(dot, 9, Paint()..color = head)
      ..drawCircle(
        dot,
        9,
        Paint()
          ..color = arc
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.arc != arc ||
      old.head != head;
}
