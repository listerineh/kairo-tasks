import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/mascot_controller.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/mascot_pose.dart';

void main() {
  MascotController controller({
    MascotMood mood = MascotMood.idle,
    bool reduced = false,
  }) {
    final c = MascotController(
      vsync: const TestVSync(),
      mood: mood,
      reduceMotion: reduced,
      random: math.Random(1),
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Steps [seconds] of physics in 60 Hz frames.
  void run(MascotController c, double seconds) {
    for (var t = 0.0; t < seconds; t += 1 / 60) {
      c.advance(1 / 60);
    }
  }

  test('starts at rest in the mood pose', () {
    final c = controller(mood: MascotMood.sad);
    expect(c.pose.earDroop, MascotPose.forMood(MascotMood.sad).earDroop);
    expect(c.isSettled, isTrue);
  });

  test('morphs toward the new mood instead of jumping', () {
    final c = controller()
      ..setMood(MascotMood.happy)
      ..advance(1 / 60);
    final early = c.pose.mouthCurve;
    expect(early, greaterThan(0.3));
    expect(early, lessThan(1));

    run(c, 2);
    expect(c.pose.mouthCurve, closeTo(1, 0.01));
    expect(c.pose.blush, closeTo(1, 0.01));
  });

  test('hop lifts the cat, lands, and shows ^^ eyes for a moment', () {
    final c = controller()..hop();

    run(c, 0.12);
    expect(c.pose.lift, greaterThan(0.02));
    expect(c.pose.eyeCurve, greaterThan(0.3));

    run(c, 2);
    expect(c.pose.lift.abs(), lessThan(0.005));
    expect(c.pose.eyeCurve.abs(), lessThan(0.01));
  });

  test('twitch moves the ears and settles back', () {
    final c = controller()..twitch();
    run(c, 0.08);
    expect(c.pose.earAngle, greaterThan(0.05));
    run(c, 2);
    expect(c.pose.earAngle.abs(), lessThan(0.005));
  });

  test('blinks every few seconds while awake', () {
    final c = controller();
    var minOpen = 1.0;
    for (var i = 0; i < 60 * 8; i++) {
      c.advance(1 / 60);
      minOpen = math.min(minOpen, c.pose.eyeOpen);
    }
    expect(minOpen, lessThan(0.2));
  });

  test('looking shifts the pupils', () {
    final c = controller()..look(1, 0);
    run(c, 2);
    expect(c.pose.pupilX, greaterThan(0.4));
  });

  group('reduced motion', () {
    test('mood changes snap without animation', () {
      final c = controller(reduced: true)..setMood(MascotMood.sleeping);
      expect(c.pose, MascotPose.forMood(MascotMood.sleeping));
      expect(c.isSettled, isTrue);
    });

    test('no breathing, blinking, hop or twitch', () {
      final c = controller(reduced: true)
        ..hop()
        ..twitch();
      run(c, 8);
      expect(c.pose, MascotPose.forMood(MascotMood.idle));
    });

    test('switching it on mid-animation snaps to the target', () {
      final c = controller()
        ..setMood(MascotMood.happy)
        ..advance(1 / 60)
        ..reduced = true;
      expect(c.pose, MascotPose.forMood(MascotMood.happy));
    });
  });

  test('poses lerp field by field', () {
    final mid = MascotPose.lerp(
      MascotPose.forMood(MascotMood.idle),
      MascotPose.forMood(MascotMood.happy),
      0.5,
    );
    expect(mid.mouthCurve, closeTo(0.65, 1e-9));
    expect(mid.blush, closeTo(0.5, 1e-9));
  });
}
