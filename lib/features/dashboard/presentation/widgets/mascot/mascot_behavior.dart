import 'dart:math' as math;

import '../../../domain/mascot/mascot_mood.dart';

/// The cat things Kairo does on his own (docs/design.md § Kairo, the cat).
enum MascotBehavior {
  /// Stands up on all fours and looks around.
  stand(2.6),

  /// Front down, back up, eyes squeezed.
  stretch(2.4),

  /// Raises a paw to his mouth and licks it.
  groom(2.8),

  /// Opens wide, eyes shut, ears back.
  yawn(1.7),

  /// Glances to one side.
  look(1.8),

  /// A quick tail flick.
  flick(1.4);

  const MascotBehavior(this.duration);

  /// Seconds the behavior lasts.
  final double duration;
}

/// One running behavior.
class ActiveBehavior {
  const ActiveBehavior(this.behavior, this.start, {this.direction = 1});

  final MascotBehavior behavior;

  /// Controller time (seconds) when it started.
  final double start;

  /// -1 left or 1 right, for [MascotBehavior.look].
  final double direction;

  double get end => start + behavior.duration;

  /// 0..1 through the behavior at [time].
  double progress(double time) =>
      ((time - start) / behavior.duration).clamp(0.0, 1.0);
}

/// Decides when Kairo does a cat thing and what it does to his pose.
///
/// Pure: time comes in as seconds and randomness from an injected
/// `math.Random`, so tests run it with a fake clock and a fixed seed. Behaviors only start on
/// their own while the cat is idle or happy, 5-11 s after the previous one
/// ended; [trigger] starts one right away (a tap, the gallery).
class MascotBehaviorScheduler {
  MascotBehaviorScheduler(this._random, {double firstAt = minGap})
    : _nextAt = firstAt;

  static const double minGap = 5;
  static const double maxGap = 11;

  /// What starts on its own; look and flick are twice as likely as the
  /// bigger moves so the cat stays calm.
  static const _pool = [
    MascotBehavior.stand,
    MascotBehavior.stretch,
    MascotBehavior.groom,
    MascotBehavior.yawn,
    MascotBehavior.look,
    MascotBehavior.look,
    MascotBehavior.flick,
    MascotBehavior.flick,
  ];

  final math.Random _random;
  double _nextAt;
  ActiveBehavior? _active;

  ActiveBehavior? get active => _active;

  /// Time at which the next spontaneous behavior may start.
  double get nextAt => _nextAt;

  static bool allowsBehaviors(MascotMood mood) =>
      mood == MascotMood.idle || mood == MascotMood.happy;

  /// Ends a finished behavior and maybe starts the next one.
  void update(double time, MascotMood mood) {
    final active = _active;
    if (active != null && time >= active.end) {
      _active = null;
      _scheduleAfter(time);
    }
    if (!allowsBehaviors(mood)) {
      // Moods without behaviors stop the current one too.
      if (_active != null) {
        _active = null;
        _scheduleAfter(time);
      }
      return;
    }
    if (_active == null && time >= _nextAt) {
      _start(_pool[_random.nextInt(_pool.length)], time);
    }
  }

  /// Starts [behavior] now, replacing any running one.
  void trigger(MascotBehavior behavior, double time) => _start(behavior, time);

  /// Stops the current behavior (e.g. a hop takes over).
  void cancel(double time) {
    if (_active == null) return;
    _active = null;
    _scheduleAfter(time);
  }

  void _start(MascotBehavior behavior, double time) {
    _active = ActiveBehavior(
      behavior,
      time,
      direction: _random.nextBool() ? 1 : -1,
    );
  }

  void _scheduleAfter(double time) {
    _nextAt = time + minGap + _random.nextDouble() * (maxGap - minGap);
  }

  /// [target] (pose values, in `MascotPose.values` order) changed by [active]
  /// at [time]. Fields not involved keep the mood's value.
  static List<double> apply(
    List<double> target,
    ActiveBehavior active,
    double time,
  ) {
    final t = List.of(target);
    final k = active.progress(time);
    switch (active.behavior) {
      case MascotBehavior.stand:
        t[_stand] = 1;
        t[_tailAngle] = 0.45;
        // Looks around while up.
        t[_pupilX] = math.sin(k * 6) * 0.8;
        t[_headTilt] = t[_pupilX] * 0.1;
      case MascotBehavior.stretch:
        t[_stand] = 0.7;
        t[_lean] = 1;
        t[_tailAngle] = 0.5;
        t[_eyeOpen] = 0.25;
        t[_earAngle] = -0.1;
      case MascotBehavior.groom:
        t[_paw] = 1;
        t[_headTilt] = -0.15;
        t[_eyeOpen] = 0.2;
        t[_pupilX] = -0.4;
        t[_headY] = 0.012;
      case MascotBehavior.yawn:
        final open = math.sin(k * math.pi);
        t[_yawn] = open;
        t[_eyeOpen] = 1 - 0.85 * open;
        t[_earAngle] = -0.14 * open;
        t[_headY] = -0.012 * open;
      case MascotBehavior.look:
        t[_pupilX] = active.direction;
        t[_headTilt] = active.direction * 0.17;
      case MascotBehavior.flick:
        t[_flick] = 1;
    }
    return t;
  }

  // Indexes into MascotPose.values.
  static const _eyeOpen = 0;
  static const _pupilX = 2;
  static const _earAngle = 4;
  static const _tailAngle = 8;
  static const _headTilt = 9;
  static const _stand = 12;
  static const _lean = 13;
  static const _paw = 14;
  static const _yawn = 15;
  static const _flick = 16;
  static const _headY = 17;
}
