import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/session/current_user.dart';
import '../../../../core/widgets/grouped_section.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../../core/widgets/kairo_tab_bar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../dashboard/domain/mascot/mascot_mood.dart';
import '../../../dashboard/domain/today_summary.dart';
import '../../../dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import '../../../dashboard/presentation/widgets/mascot/mascot_behavior.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../widgets/kairo_lines.dart';

/// Kairo's page (Yo › Kairo): him large in today's mood, things to make him
/// do, and what he does when.
class KairoPage extends StatefulWidget {
  const KairoPage({super.key, this.now, this.userId});

  /// Fixed in goldens; otherwise the current time.
  final DateTime? now;
  final String? userId;

  @override
  State<KairoPage> createState() => _KairoPageState();
}

class _KairoPageState extends State<KairoPage> {
  MascotBehavior? _cue;
  int _cues = 0;
  int _tip = 0;

  String? get _userId =>
      widget.userId ??
      (getIt.isRegistered<CurrentUser>() ? getIt<CurrentUser>().id : null);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colors.label),
          child: BlocBuilder<TasksBloc, TasksState>(
            builder: (context, state) {
              final summary = TodaySummary.from(
                state.tasks,
                now: widget.now ?? DateTime.now(),
                userId: _userId,
              );
              final mood = summary.mood();
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.spacing12,
                  AppSpacing.screenMargin,
                  math.max(
                    MediaQuery.paddingOf(context).bottom,
                    KairoTabBar.contentPadding(context),
                  ),
                ),
                children: [
                  _Header(onBack: () => context.pop()),
                  const SizedBox(height: AppSpacing.spacing16),
                  _hero(context, summary, mood),
                  const SizedBox(height: AppSpacing.spacing16),
                  _things(context),
                  const SizedBox(height: AppSpacing.spacing16),
                  GroupedSection(
                    header: l10n.kairoWhatWhen,
                    margin: 0,
                    children: [
                      for (final (title, detail) in _behaviors(context))
                        GroupedRow(title: title, subtitle: detail),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, TodaySummary summary, MascotMood mood) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final taps = [l10n.mascotMeow, l10n.tipFocus, l10n.tipCheer];
    final line = _tip > 0 && mood != MascotMood.sleeping
        ? taps[(_tip - 1) % taps.length]
        : kairoLine(context, mood);
    return KairoCard(
      style: KairoCardStyle.hero,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          KairoMascot(
            mood: mood,
            progress: summary.progress,
            hopTrigger: summary.done.length,
            cue: _cue,
            cueTrigger: _cues,
            size: 220,
            onTap: () => setState(() => _tip++),
            onLongPress: () => context.push('/focus'),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Semantics(
            liveRegion: true,
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: context.typography.bodyMultiline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            l10n.kairoTapHint,
            textAlign: TextAlign.center,
            style: context.typography.footnote.copyWith(
              color: colors.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _things(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final actions = [
      (MascotBehavior.stand, l10n.kairoStand),
      (MascotBehavior.stretch, l10n.kairoStretch),
      (MascotBehavior.groom, l10n.kairoGroom),
      (MascotBehavior.yawn, l10n.kairoYawn),
      (MascotBehavior.look, l10n.kairoLook),
      (MascotBehavior.flick, l10n.kairoFlick),
    ];
    return KairoCard(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.kairoThings, style: context.typography.headline),
          const SizedBox(height: AppSpacing.spacing12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Three per row, two when text is large.
              final perRow = MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? 2
                  : 3;
              const gap = 8.0;
              final width =
                  (constraints.maxWidth - gap * (perRow - 1)) / perRow;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (behavior, label) in actions)
                    SizedBox(
                      width: width,
                      child: _ThingButton(
                        label: label,
                        onTap: () => setState(() {
                          _cue = behavior;
                          _cues++;
                          _tip = 0;
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.spacing12),
          Text(
            l10n.kairoThingsHint,
            style: context.typography.footnote.copyWith(
              color: colors.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static List<(String, String)> _behaviors(BuildContext context) {
    final l10n = context.l10n;
    return [
      (l10n.kairoWhenAlways, l10n.kairoWhatAlways),
      (l10n.kairoWhenCalm, l10n.kairoWhatCalm),
      (l10n.kairoWhenDone, l10n.kairoWhatDone),
      (l10n.kairoWhenTap, l10n.kairoWhatTap),
      (l10n.kairoWhenFocus, l10n.kairoWhatFocus),
      (l10n.kairoWhenRisk, l10n.kairoWhatRisk),
      (l10n.kairoWhenNight, l10n.kairoWhatNight),
      (l10n.kairoWhenReduced, l10n.kairoWhatReduced),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Row(
      children: [
        Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          excludeSemantics: true,
          child: Pressable(
            onPressed: onBack,
            child: Container(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              decoration: ShapeDecoration(
                color: colors.surface,
                shape: CircleBorder(side: BorderSide(color: colors.separator)),
              ),
              child: Icon(
                CupertinoIcons.chevron_back,
                size: 20,
                color: colors.label,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.kairoCompanion,
                style: context.typography.subheadline.copyWith(
                  color: colors.labelSecondary,
                ),
              ),
              Semantics(
                header: true,
                child: Text('Kairo', style: context.typography.title1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThingButton extends StatelessWidget {
  const _ThingButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onPressed: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.separator),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.typography.subheadline.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
