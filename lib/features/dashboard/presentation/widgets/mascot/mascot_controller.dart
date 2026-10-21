import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import '../../../../../app/theme/app_motion.dart';
import '../../../domain/mascot/mascot_mood.dart';
import 'mascot_pose.dart';

/// Drives every [MascotPose] field toward the current mood's pose with its
/// own spring, so mood changes morph instead of cutting between animations.
///
/// Behaviors (docs/redesign-plan.md §2.6) are impulses on those springs:
/// [hop] kicks `lift`, [twitch] kicks the ears and head, blinks close a
/// separate lid channel. Breathing and blinking are the only ambient motion
/// and stop when [reduced] is true; in that mode every change snaps.
class MascotController extends ChangeNotifier {
  MascotController({
    required TickerProvider vsync,
    MascotMood mood = MascotMood.idle,
    bool reduceMotion = false,
    math.Random? random,
  }) : _mood = mood,
       _reduced = reduceMotion,
       _random = random ?? math.Random() {
    _target = MascotPose.forMood(mood).values;
    _x = List.of(_target);
    _v = List.filled(_x.length, 0);
    _scheduleBlink();
    _ticker = vsync.createTicker(_onTick);
    _syncTicker();
  }

  // Index of each pose field in MascotPose.values.
  static const _eyeOpen = 0;
  static const _eyeCurve = 1;
  static const _earAngle = 4;
  static const _bodySquash = 7;
  static const _headTilt = 9;
  static const _lift = 11;

  /// Fields that should overshoot: hop, landing squash, ear twitch.
  static const _bouncyFields = {_earAngle, _bodySquash, _headTilt, _lift};

  static const _happyEyesFor = 1.2;

  final math.Random _random;
  late final Ticker _ticker;
  late List<double> _target;
  late List<double> _x;
  late List<double> _v;

  MascotMood _mood;
  bool _reduced;
  Duration _lastTick = Duration.zero;
  double _time = 0;
  double _happyEyesUntil = -1;
  double _nextBlinkAt = 0;
  double _lid = 1;
  double _lidVelocity = 0;
  double _lidTarget = 1;
  double _lookX = 0;
  double _lookY = 0;

  MascotMood get mood => _mood;
  bool get reduced => _reduced;

  /// The pose to paint now, including breathing and blinks.
  MascotPose get pose {
    final values = List.of(_x);
    values[_eyeOpen] *= _lid;
    if (!_reduced) values[_bodySquash] += _breath();
    return MascotPose.fromValues(values);
  }

  set reduced(bool value) {
    if (value == _reduced) return;
    _reduced = value;
    if (value) _snap();
    _syncTicker();
    notifyListeners();
  }

  void setMood(MascotMood mood) {
    if (mood == _mood) return;
    _mood = mood;
    _retarget();
  }

  /// Where the cat looks, -1..1 on each axis (e.g. scroll direction).
  void look(double x, double y) {
    _lookX = x.clamp(-1, 1);
    _lookY = y.clamp(-1, 1);
    _retarget();
  }

  /// A task was completed: hop, land with a squash, eyes ^^ for a moment.
  void hop() {
    if (_reduced) return;
    _v[_lift] += 1.6;
    _v[_bodySquash] -= 0.6;
    _happyEyesUntil = _time + _happyEyesFor;
    _retarget();
  }

  /// The cat was tapped: ear twitch and a small head tilt.
  void twitch() {
    if (_reduced) return;
    _v[_earAngle] += 4;
    _v[_headTilt] += (_random.nextBool() ? 1 : -1) * 1.2;
    _syncTicker();
  }

  /// Steps the physics by [dt] seconds. Called by the ticker; exposed so
  /// tests can drive time without frames.
  @visibleForTesting
  void advance(double dt) {
    const maxStep = 1 / 240;
    var remaining = dt;
    while (remaining > 0) {
      final step = math.min(remaining, maxStep);
      _step(step);
      remaining -= step;
    }
    if (_happyEyesUntil >= 0 && _time >= _happyEyesUntil) {
      _happyEyesUntil = -1;
      _retarget();
    }
    _maybeBlink();
    notifyListeners();
  }

  /// Whether every spring is at rest (ambient motion aside).
  @visibleForTesting
  bool get isSettled {
    for (var i = 0; i < _x.length; i++) {
      if ((_x[i] - _target[i]).abs() > 1e-3 || _v[i].abs() > 1e-3) {
        return false;
      }
    }
    return (_lid - _lidTarget).abs() < 1e-3 && _lidVelocity.abs() < 1e-3;
  }

  void _step(double dt) {
    _time += dt;
    for (var i = 0; i < _x.length; i++) {
      final spring = _bouncyFields.contains(i)
          ? KairoSpring.bouncy.description
          : KairoSpring.smooth.description;
      _integrate(i, spring, dt);
    }
    final lid = KairoSpring.snappy.description;
    final a = -lid.stiffness * (_lid - _lidTarget) - lid.damping * _lidVelocity;
    _lidVelocity += a * dt;
    _lid = (_lid + _lidVelocity * dt).clamp(0.0, 1.0);
    // A blink reopens as soon as the lid is shut.
    if (_lidTarget == 0 && _lid < 0.05) _lidTarget = 1;
  }

  void _integrate(int i, SpringDescription s, double dt) {
    final a = -s.stiffness * (_x[i] - _target[i]) - s.damping * _v[i];
    _v[i] += a * dt;
    _x[i] += _v[i] * dt;
  }

  void _retarget() {
    final target = MascotPose.forMood(_mood).values;
    target[2] += _lookX * 0.6;
    target[3] = (target[3] + _lookY * 0.6).clamp(-1, 1);
    if (_happyEyesUntil >= 0) {
      target[_eyeCurve] = 1;
      target[_eyeOpen] = 1;
    }
    _target = target;
    if (_reduced) _snap();
    _syncTicker();
    notifyListeners();
  }

  void _snap() {
    _x = List.of(_target);
    _v = List.filled(_x.length, 0);
    _lid = 1;
    _lidVelocity = 0;
    _lidTarget = 1;
  }

  double _breath() {
    final period = _mood == MascotMood.sleeping ? 6.0 : 4.0;
    return math.sin(2 * math.pi * _time / period) * 0.015;
  }

  void _scheduleBlink() {
    _nextBlinkAt = _time + 3 + _random.nextDouble() * 4;
  }

  void _maybeBlink() {
    if (_reduced || _time < _nextBlinkAt) return;
    // Closed or nearly closed eyes have nothing to blink.
    if (_x[_eyeOpen] > 0.3) _lidTarget = 0;
    _scheduleBlink();
  }

  /// Breathing keeps the ticker alive unless motion is reduced.
  void _syncTicker() {
    final shouldRun = !_reduced || !isSettled;
    if (shouldRun && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    // Clamp long gaps (app resumed) so springs never explode.
    advance(dt.clamp(0, 1 / 30));
    if (_reduced && isSettled) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
