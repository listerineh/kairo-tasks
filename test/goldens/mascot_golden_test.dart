import 'package:flutter/material.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/kairo_mascot.dart';

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
          body: Center(child: KairoMascot(mood: mood, size: 160)),
        ),
      ),
    );
  }
}
