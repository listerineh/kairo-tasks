import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Spring presets (docs/redesign-plan.md §2.5), described the way SwiftUI
/// does: `response` (seconds per oscillation) and `bounce` (0 = critically
/// damped).
///
/// Drive gestures with [description] and a `SpringSimulation` so they keep
/// the user's velocity. For implicit animations use `context.motion`, which
/// supplies a matching duration and [curve] and handles reduced motion.
@immutable
class KairoSpring {
  const KairoSpring._(
    this.response,
    this.bounce,
    this.description,
    this.settleDuration,
    this.curve,
  );

  factory KairoSpring._create(double response, double bounce) {
    final description = SpringDescription(
      mass: 1,
      stiffness: math.pow(2 * math.pi / response, 2).toDouble(),
      damping: 4 * math.pi * (1 - bounce) / response,
    );
    final settle = _settleTime(description);
    return KairoSpring._(
      response,
      bounce,
      description,
      settle,
      _SpringCurve(description, settle),
    );
  }

  /// No bounce: navigation, sheets, layout changes.
  static final smooth = KairoSpring._create(0.35, 0);

  /// Small bounce: toggles, check circle, chips, segmented control.
  static final snappy = KairoSpring._create(0.3, 0.15);

  /// Visible bounce: celebrations and the cat only.
  static final bouncy = KairoSpring._create(0.45, 0.3);

  final double response;
  final double bounce;
  final SpringDescription description;

  /// Time until the spring is visually at rest, starting from rest.
  final Duration settleDuration;

  /// The spring sampled over [settleDuration], for implicit animations.
  final Curve curve;

  // Within half a pixel per 100 px of travel and nearly still: the visible
  // end of the motion. The default tolerance adds an invisible tail.
  static const _settled = Tolerance(distance: 0.005, velocity: 0.05);

  static Duration _settleTime(SpringDescription spring) {
    const step = 1 / 240;
    final sim = SpringSimulation(spring, 0, 1, 0, tolerance: _settled);
    var t = 0.0;
    while (!sim.isDone(t) && t < 3) {
      t += step;
    }
    final micros = (t * Duration.microsecondsPerSecond).round();
    return Duration(microseconds: micros);
  }
}

class _SpringCurve extends Curve {
  _SpringCurve(SpringDescription spring, Duration duration)
    : _sim = SpringSimulation(spring, 0, 1, 0),
      _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;

  final SpringSimulation _sim;
  final double _seconds;

  @override
  double transformInternal(double t) => _sim.x(t * _seconds);
}

/// Motion settings resolved for one `BuildContext`; read it with
/// `context.motion` so no widget checks reduced motion by hand.
///
/// Reduced motion comes from `MediaQuery.disableAnimations` (the OS setting).
/// The in-app override (Phase 6) wraps the app in a MediaQuery that sets the
/// same flag, so this stays the only place that decides.
@immutable
class KairoMotion {
  const KairoMotion({required this.reduced});

  /// What springs become under reduced motion: a short cross-fade.
  static const reducedDuration = Duration(milliseconds: 150);

  final bool reduced;

  Duration duration(KairoSpring spring) =>
      reduced ? reducedDuration : spring.settleDuration;

  Curve curve(KairoSpring spring) => reduced ? Curves.easeInOut : spring.curve;

  /// Whether purely decorative motion (idle cat, parallax) should run.
  bool get ambient => !reduced;
}

extension KairoMotionContext on BuildContext {
  KairoMotion get motion =>
      KairoMotion(reduced: MediaQuery.disableAnimationsOf(this));
}
