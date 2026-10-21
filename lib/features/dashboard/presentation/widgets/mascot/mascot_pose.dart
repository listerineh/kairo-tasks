import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

import '../../../domain/mascot/mascot_mood.dart';

/// Everything the painter needs for one frame of the cat. Every field is a
/// plain number so poses lerp, and the controller can spring each one on
/// its own.
@immutable
class MascotPose {
  const MascotPose({
    this.eyeOpen = 1,
    this.eyeCurve = 0,
    this.pupilX = 0,
    this.pupilY = 0,
    this.earAngle = 0,
    this.earDroop = 0,
    this.mouthCurve = 0.3,
    this.bodySquash = 0,
    this.tailAngle = 0.2,
    this.headTilt = 0,
    this.blush = 0,
    this.lift = 0,
    this.stand = 0,
    this.lean = 0,
    this.paw = 0,
    this.yawn = 0,
    this.flick = 0,
    this.headY = 0,
  });

  /// Rebuilds a pose from [values] (the order of [values] getter).
  factory MascotPose.fromValues(List<double> v) => MascotPose(
    eyeOpen: v[0],
    eyeCurve: v[1],
    pupilX: v[2],
    pupilY: v[3],
    earAngle: v[4],
    earDroop: v[5],
    mouthCurve: v[6],
    bodySquash: v[7],
    tailAngle: v[8],
    headTilt: v[9],
    blush: v[10],
    lift: v[11],
    stand: v[12],
    lean: v[13],
    paw: v[14],
    yawn: v[15],
    flick: v[16],
    headY: v[17],
  );

  /// Target pose for a mood (docs/design.md § Kairo, the cat).
  factory MascotPose.forMood(MascotMood mood) => switch (mood) {
    MascotMood.idle => const MascotPose(),
    MascotMood.focused => const MascotPose(
      eyeOpen: 0.45,
      pupilY: 0.8,
      earAngle: 0.08,
      mouthCurve: 0,
      tailAngle: 0,
      headY: 0.006,
    ),
    MascotMood.happy => const MascotPose(
      eyeCurve: 1,
      earAngle: 0.1,
      mouthCurve: 1,
      tailAngle: 0.35,
      blush: 1,
    ),
    MascotMood.sad => const MascotPose(
      eyeOpen: 0.8,
      eyeCurve: -0.6,
      pupilY: 0.7,
      earDroop: 1,
      mouthCurve: -0.8,
      tailAngle: -0.4,
      headTilt: -0.06,
      headY: 0.02,
    ),
    MascotMood.sleeping => const MascotPose(
      eyeOpen: 0,
      earDroop: 0.2,
      mouthCurve: 0.1,
      bodySquash: 0.12,
      tailAngle: 0.45,
      headY: 0.055,
    ),
  };

  /// Field-by-field blend from [a] (t = 0) to [b] (t = 1).
  factory MascotPose.lerp(MascotPose a, MascotPose b, double t) {
    final av = a.values;
    final bv = b.values;
    return MascotPose.fromValues([
      for (var i = 0; i < av.length; i++) lerpDouble(av[i], bv[i], t)!,
    ]);
  }

  /// 0 closed, 1 open.
  final double eyeOpen;

  /// -1 sad (inner corners up) .. 0 neutral .. 1 happy closed arcs (^^).
  final double eyeCurve;

  /// Where the pupils look, -1..1 on each axis.
  final double pupilX;
  final double pupilY;

  /// Ear rotation in radians; positive points them forward and up.
  final double earAngle;

  /// 0 upright .. 1 folded down and out.
  final double earDroop;

  /// -1 frown .. 1 open smile.
  final double mouthCurve;

  /// Vertical squash as a fraction of height (breathing, landing).
  final double bodySquash;

  /// Tail rotation in radians; higher curls it up.
  final double tailAngle;

  /// Head rotation in radians.
  final double headTilt;

  /// 0..1 cheek blush.
  final double blush;

  /// Hop height as a fraction of the cat's size.
  final double lift;

  /// 0 sitting .. 1 standing on all fours.
  final double stand;

  /// 0 upright .. 1 stretched forward (front down, back up).
  final double lean;

  /// 0 paw resting .. 1 raised to the mouth (grooming).
  final double paw;

  /// 0 closed mouth .. 1 full yawn.
  final double yawn;

  /// Tail energy: 0 a lazy sway .. 1 a quick flick.
  final double flick;

  /// Head drop as a fraction of the cat's size (sleepy, worried).
  final double headY;

  List<double> get values => [
    eyeOpen,
    eyeCurve,
    pupilX,
    pupilY,
    earAngle,
    earDroop,
    mouthCurve,
    bodySquash,
    tailAngle,
    headTilt,
    blush,
    lift,
    stand,
    lean,
    paw,
    yawn,
    flick,
    headY,
  ];

  @override
  bool operator ==(Object other) =>
      other is MascotPose && listEquals(other.values, values);

  @override
  int get hashCode => Object.hashAll(values);
}
