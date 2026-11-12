import 'package:flutter/material.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/mascot_behavior.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/mascot_painter.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/mascot_pose.dart';

import '../helpers/golden.dart';

void main() {
  for (final mood in MascotMood.values) {
    goldenTest(
      'mascot_${mood.name}',
      size: const Size(200, 200),
      // Reduced motion freezes the cat on its mood pose: no breathing or
      // blinks, so the render is deterministic.
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: KairoMascot(mood: mood, progress: 0.6, size: 160),
          ),
        ),
      ),
    );
  }

  // Cat things never run under reduced motion, so their peak poses are
  // painted directly.
  for (final behavior in [
    MascotBehavior.stand,
    MascotBehavior.stretch,
    MascotBehavior.groom,
    MascotBehavior.yawn,
  ]) {
    final pose = MascotPose.fromValues(
      MascotBehaviorScheduler.apply(
        MascotPose.forMood(MascotMood.idle).values,
        ActiveBehavior(behavior, 0),
        behavior.duration / 2,
      ),
    );
    goldenTest(
      'mascot_behavior_${behavior.name}',
      size: const Size(200, 200),
      builder: (context) => Scaffold(
        body: Center(
          child: SizedBox.square(
            dimension: 160,
            child: CustomPaint(
              painter: MascotPainter(pose: pose, progress: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
