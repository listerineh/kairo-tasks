import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_motion.dart';

void main() {
  group('KairoSpring', () {
    test('settle durations match the presets', () {
      Matcher between(int lo, int hi) => allOf(
        greaterThanOrEqualTo(Duration(milliseconds: lo)),
        lessThanOrEqualTo(Duration(milliseconds: hi)),
      );

      expect(KairoSpring.smooth.settleDuration, between(350, 550));
      expect(KairoSpring.snappy.settleDuration, between(250, 450));
      expect(KairoSpring.bouncy.settleDuration, between(450, 750));
    });

    test('curves start at 0 and end at 1', () {
      for (final spring in [
        KairoSpring.smooth,
        KairoSpring.snappy,
        KairoSpring.bouncy,
      ]) {
        expect(spring.curve.transform(0), 0);
        expect(spring.curve.transform(1), 1);
      }
    });

    test('smooth never overshoots; bouncy does', () {
      final samples = List.generate(101, (i) => i / 100);
      final smooth = samples.map(KairoSpring.smooth.curve.transform);
      final bouncy = samples.map(KairoSpring.bouncy.curve.transform);

      expect(smooth.every((v) => v <= 1.0001), isTrue);
      expect(bouncy.any((v) => v > 1.02), isTrue);
    });
  });

  group('context.motion', () {
    Future<KairoMotion> motionWith(
      WidgetTester tester, {
      required bool disableAnimations,
    }) async {
      late KairoMotion motion;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Builder(
            builder: (context) {
              motion = context.motion;
              return const SizedBox();
            },
          ),
        ),
      );
      return motion;
    }

    testWidgets('uses the spring when motion is allowed', (tester) async {
      final motion = await motionWith(tester, disableAnimations: false);

      expect(motion.reduced, isFalse);
      expect(
        motion.duration(KairoSpring.snappy),
        KairoSpring.snappy.settleDuration,
      );
      expect(motion.curve(KairoSpring.snappy), KairoSpring.snappy.curve);
    });

    testWidgets('becomes a 150 ms cross-fade under reduced motion', (
      tester,
    ) async {
      final motion = await motionWith(tester, disableAnimations: true);

      expect(motion.reduced, isTrue);
      expect(motion.ambient, isFalse);
      expect(
        motion.duration(KairoSpring.bouncy),
        const Duration(milliseconds: 150),
      );
      expect(motion.curve(KairoSpring.bouncy), Curves.easeInOut);
    });
  });
}
