import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../dashboard/domain/mascot/mascot_mood.dart';
import '../../../dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import '../../../dashboard/presentation/widgets/mascot/mascot_behavior.dart';

/// The login's `ink` hero: Kairo in the middle reacting to the form, the
/// greeting, and a few task chips drifting around him that check
/// themselves off, a glimpse of what the app does.
///
/// [compact] shrinks it while the keyboard is up; [caption] shows under
/// Kairo (e.g. "No miro, lo prometo." while typing the password).
class LoginHero extends StatefulWidget {
  const LoginHero({
    required this.mood,
    required this.title,
    required this.subtitle,
    this.compact = false,
    this.caption,
    this.hopTrigger = 0,
    this.cue,
    this.cueTrigger = 0,
    this.onTapKairo,
    this.drift,
    super.key,
  });

  final MascotMood mood;
  final String title;
  final String subtitle;
  final bool compact;
  final String? caption;
  final int hopTrigger;
  final MascotBehavior? cue;
  final int cueTrigger;
  final VoidCallback? onTapKairo;

  /// Fixed drift phase for goldens (0..1); null animates.
  final double? drift;

  static const fullHeight = 360.0;
  static const compactHeight = 210.0;

  @override
  State<LoginHero> createState() => _LoginHeroState();
}

class _LoginHeroState extends State<LoginHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = context.motion.reduced || widget.drift != null;
    if (still) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final duration = motion.duration(KairoSpring.smooth);
    final curve = motion.curve(KairoSpring.smooth);
    final caption = widget.caption;
    final topInset = MediaQuery.paddingOf(context).top;

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      height:
          topInset +
          (widget.compact ? LoginHero.compactHeight : LoginHero.fullHeight),
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Chips only while there is room for them.
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: widget.compact ? 0 : 1,
              duration: duration,
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _drift,
                  builder: (context, _) =>
                      _Chips(phase: widget.drift ?? _drift.value),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: topInset,
            // Bottom-anchored; while the hero animates between heights the
            // top clips instead of overflowing.
            child: SingleChildScrollView(
              reverse: true,
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Shrinks in layout too, so the compact hero never overflows.
                  AnimatedContainer(
                    duration: duration,
                    curve: curve,
                    height: widget.compact ? 96 : 150,
                    child: FittedBox(
                      child: KairoMascot(
                        mood: widget.mood,
                        hopTrigger: widget.hopTrigger,
                        cue: widget.cue,
                        cueTrigger: widget.cueTrigger,
                        onTap: widget.onTapKairo,
                        size: 150,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 22,
                    child: AnimatedSwitcher(
                      duration: duration,
                      child: caption == null
                          ? const SizedBox.shrink()
                          : Text(
                              caption,
                              key: ValueKey(caption),
                              style: context.typography.footnote.copyWith(
                                color: colors.lime,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // The greeting steps aside while typing.
                  AnimatedSize(
                    duration: duration,
                    curve: curve,
                    child: widget.compact
                        ? const SizedBox(width: double.infinity)
                        : AnimatedSwitcher(
                            duration: duration,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0, 0.25),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: Column(
                              key: ValueKey(widget.title),
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    textScaler: MediaQuery.textScalerOf(context)
                                        .clamp(maxScaleFactor: 1.4),
                                    style: context.typography.title1.copyWith(
                                      color: colors.onInk,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle,
                                  textAlign: TextAlign.center,
                                  textScaler: MediaQuery.textScalerOf(context)
                                      .clamp(maxScaleFactor: 1.4),
                                  style: context.typography.subheadline
                                      .copyWith(color: colors.onInkSecondary),
                                ),
                              ],
                            ),
                          ),
                  ),
                  // Room for the form card that overlaps the hero's edge.
                  const SizedBox(height: 44),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four chips placed around Kairo, each bobbing on its own phase; two of
/// them tick their check on and off through the loop.
class _Chips extends StatelessWidget {
  const _Chips({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topInset = MediaQuery.paddingOf(context).top;
    final t = phase * 2 * math.pi;

    // (alignment, label, icon kind, phase offset, checks within loop)
    final chips = [
      (const Alignment(-0.92, -0.7), l10n.loginChipCall, _Kind.check, 0.0),
      (const Alignment(0.92, -0.98), l10n.loginChipRun, _Kind.check, 4.4),
      (const Alignment(-0.98, -0.05), l10n.loginChipStreak, _Kind.streak, 3.1),
      (const Alignment(0.98, -0.3), l10n.loginChipFocus, _Kind.focus, 1.7),
    ];

    return Padding(
      padding: EdgeInsets.only(top: topInset + 8, left: 10, right: 10),
      child: Stack(
        children: [
          for (final (align, label, kind, offset) in chips)
            Align(
              alignment: align,
              child: Transform.translate(
                offset: Offset(
                  math.sin(t + offset) * 6,
                  math.cos(t * 2 + offset) * 5,
                ),
                child: _Chip(
                  label: label,
                  kind: kind,
                  // Each check chip is done for half of the loop.
                  done: kind == _Kind.check && math.sin(t + offset) > 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _Kind { check, focus, streak }

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.kind, required this.done});

  final String label;
  final _Kind kind;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final icon = switch (kind) {
      _Kind.check => AnimatedContainer(
        duration: motion.duration(KairoSpring.snappy),
        curve: motion.curve(KairoSpring.snappy),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? colors.lime : Colors.transparent,
          border: Border.all(
            color: done ? colors.lime : colors.onInkSecondary,
            width: 1.6,
          ),
        ),
        child: done
            ? Icon(CupertinoIcons.checkmark_alt, size: 11, color: colors.onLime)
            : null,
      ),
      _Kind.focus => Icon(CupertinoIcons.timer, size: 15, color: colors.lime),
      _Kind.streak => Icon(
        CupertinoIcons.flame_fill,
        size: 15,
        color: colors.apricot,
      ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
      decoration: BoxDecoration(
        color: colors.onInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.onInk.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            label,
            textScaler: TextScaler.noScaling,
            style: context.typography.caption1.copyWith(
              color: done ? colors.onInkSecondary : colors.onInk,
              fontWeight: FontWeight.w700,
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: colors.onInkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
