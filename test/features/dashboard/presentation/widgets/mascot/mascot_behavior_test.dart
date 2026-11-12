import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/mascot_behavior.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/mascot_pose.dart';

void main() {
  MascotBehaviorScheduler scheduler({double firstAt = 4}) =>
      MascotBehaviorScheduler(math.Random(7), firstAt: firstAt);

  /// Runs the scheduler from [from] to [to] seconds in 10 Hz steps and
  /// returns every behavior that started.
  List<MascotBehavior> run(
    MascotBehaviorScheduler s,
    MascotMood mood, {
    required double to,
    double from = 0,
  }) {
    final started = <MascotBehavior>[];
    ActiveBehavior? last;
    for (var t = from; t <= to; t += 0.1) {
      s.update(t, mood);
      final active = s.active;
      if (active != null && !identical(active, last)) {
        started.add(active.behavior);
      }
      last = active;
    }
    return started;
  }

  test('waits for the first slot, then does one thing at a time', () {
    final s = scheduler()..update(3.9, MascotMood.idle);
    expect(s.active, isNull);

    s.update(4, MascotMood.idle);
    expect(s.active, isNotNull);
    final first = s.active!;

    s.update(first.start + first.behavior.duration / 2, MascotMood.idle);
    expect(identical(s.active, first), isTrue);
  });

  test('leaves 5-11 s of calm between behaviors', () {
    final s = scheduler()..update(4, MascotMood.idle);
    final first = s.active!;

    s.update(first.end, MascotMood.idle);
    expect(s.active, isNull);
    final gap = s.nextAt - first.end;
    expect(gap, inInclusiveRange(5, 11));
  });

  test('a minute of idle life brings several different cat things', () {
    final started = run(scheduler(), MascotMood.idle, to: 60);
    expect(started.length, inInclusiveRange(4, 9));
    expect(started.toSet().length, greaterThan(1));
  });

  test('focused, sad and sleeping cats stay still', () {
    for (final mood in [
      MascotMood.focused,
      MascotMood.sad,
      MascotMood.sleeping,
    ]) {
      expect(run(scheduler(), mood, to: 60), isEmpty, reason: mood.name);
    }
  });

  test('a mood without behaviors stops the running one', () {
    final s = scheduler()
      ..trigger(MascotBehavior.groom, 0)
      ..update(0.5, MascotMood.focused);
    expect(s.active, isNull);
  });

  test('trigger starts right away and cancel ends it', () {
    final s = scheduler()..trigger(MascotBehavior.yawn, 1);
    expect(s.active?.behavior, MascotBehavior.yawn);
    s.cancel(1.2);
    expect(s.active, isNull);
  });

  group('apply', () {
    final idle = MascotPose.forMood(MascotMood.idle).values;
    MascotPose at(MascotBehavior b, double k) => MascotPose.fromValues(
      MascotBehaviorScheduler.apply(idle, ActiveBehavior(b, 0), b.duration * k),
    );

    test('stand raises the cat', () {
      expect(at(MascotBehavior.stand, 0.5).stand, 1);
    });

    test('stretch leans forward with squeezed eyes', () {
      final pose = at(MascotBehavior.stretch, 0.5);
      expect(pose.lean, 1);
      expect(pose.eyeOpen, lessThan(0.5));
    });

    test('groom raises the paw', () {
      expect(at(MascotBehavior.groom, 0.5).paw, 1);
    });

    test('a yawn opens and closes with the eyes shutting', () {
      expect(at(MascotBehavior.yawn, 0).yawn, closeTo(0, 1e-9));
      final mid = at(MascotBehavior.yawn, 0.5);
      expect(mid.yawn, closeTo(1, 1e-9));
      expect(mid.eyeOpen, lessThan(0.2));
      expect(at(MascotBehavior.yawn, 1).yawn, closeTo(0, 1e-9));
    });

    test('look turns eyes and head to one side', () {
      final pose = MascotPose.fromValues(
        MascotBehaviorScheduler.apply(
          idle,
          const ActiveBehavior(MascotBehavior.look, 0, direction: -1),
          0.5,
        ),
      );
      expect(pose.pupilX, -1);
      expect(pose.headTilt, lessThan(0));
    });

    test('flick energizes the tail', () {
      expect(at(MascotBehavior.flick, 0.5).flick, 1);
    });
  });
}
