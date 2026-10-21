import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_motion.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/services/haptics_service.dart';
import '../../../domain/mascot/mascot_mood.dart';
import 'mascot_controller.dart';
import 'mascot_painter.dart';

/// Kairo the cat. Shows [mood] and reacts to what happens
/// (docs/redesign-plan.md §2.6):
///
/// - Idle life: breathing and random blinks (off under reduced motion).
/// - Tap: ear twitch + head tilt + selection haptic; one tap in five says
///   "miau"; tapping while asleep lets a "z" drift up.
/// - [hopTrigger] increases (a task was completed): hop with ^^ eyes.
/// - Mood changes morph through springs; under reduced motion they snap.
class KairoMascot extends StatefulWidget {
  const KairoMascot({
    required this.mood,
    this.hopTrigger = 0,
    this.size = 120,
    this.random,
    super.key,
  });

  final MascotMood mood;

  /// Any increase makes the cat hop once; pass e.g. today's completed count.
  final int hopTrigger;
  final double size;

  /// Injectable for deterministic tests.
  final math.Random? random;

  @override
  State<KairoMascot> createState() => _KairoMascotState();
}

enum _Bubble { meow, sleepy }

class _KairoMascotState extends State<KairoMascot>
    with SingleTickerProviderStateMixin {
  late final math.Random _random = widget.random ?? math.Random();
  late final MascotController _controller = MascotController(
    vsync: this,
    mood: widget.mood,
    random: _random,
  );
  _Bubble? _bubble;
  int _bubbleId = 0;
  Timer? _bubbleTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.reduced = context.motion.reduced;
  }

  @override
  void didUpdateWidget(KairoMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.setMood(widget.mood);
    if (widget.hopTrigger > oldWidget.hopTrigger) _controller.hop();
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    final haptics = registeredHaptics;
    if (haptics != null) unawaited(haptics.selection());
    _controller.twitch();

    final bubble = widget.mood == MascotMood.sleeping
        ? _Bubble.sleepy
        : (_random.nextInt(5) == 0 ? _Bubble.meow : null);
    if (bubble == null) return;
    _bubbleTimer?.cancel();
    setState(() {
      _bubble = bubble;
      _bubbleId++;
    });
    _bubbleTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  String _label(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.mood) {
      MascotMood.idle => l10n.mascotIdle,
      MascotMood.focused => l10n.mascotFocused,
      MascotMood.happy => l10n.mascotHappy,
      MascotMood.sad => l10n.mascotSad,
      MascotMood.sleeping => l10n.mascotSleeping,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tint = context.appColors.tint;

    return Semantics(
      label: _label(context),
      image: true,
      onTap: _onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: SizedBox.square(
          dimension: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: MascotPainter(pose: _controller.pose, tint: tint),
                  ),
                ),
              ),
              if (_bubble != null)
                _BubbleView(
                  key: ValueKey(_bubbleId),
                  text: _bubble == _Bubble.meow ? context.l10n.mascotMeow : 'z',
                  size: widget.size,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "miau" or "z" rising from the cat's head and fading out.
class _BubbleView extends StatelessWidget {
  const _BubbleView({required this.text, required this.size, super.key});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final drift = motion.reduced ? 0.0 : size * 0.18;

    return Positioned(
      right: size * 0.02,
      top: -size * 0.02,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: motion.reduced
            ? KairoMotion.reducedDuration
            : const Duration(milliseconds: 1400),
        builder: (context, t, child) => Opacity(
          // Fade in fast, hold, fade out over the last third.
          opacity: t < 0.15 ? t / 0.15 : (t > 0.66 ? (1 - t) / 0.34 : 1),
          child: Transform.translate(
            offset: Offset(0, -drift * t),
            child: child,
          ),
        ),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.surfaceRaised,
            shape: const StadiumBorder(),
            shadows: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              text,
              style: context.typography.footnote.copyWith(
                color: colors.label,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
