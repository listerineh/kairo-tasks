import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/kairo_typography.dart';

void main() {
  group('KairoTypography', () {
    test('Android uses bundled Inter with Inter tracking', () {
      final t = KairoTypography.forPlatform(TargetPlatform.android);

      expect(t.body.fontFamily, 'Inter');
      expect(t.largeTitle.fontFamily, 'Inter');
      expect(t.body.letterSpacing, KairoTypography.interTracking(17));
    });

    test('iOS uses SF Text below 20 pt and SF Display from 20 pt', () {
      final t = KairoTypography.forPlatform(TargetPlatform.iOS);

      expect(t.body.fontFamily, 'CupertinoSystemText');
      expect(t.title3.fontFamily, 'CupertinoSystemDisplay');
      expect(t.body.letterSpacing, -0.41);
    });

    test('Inter tracking tightens as size grows', () {
      expect(KairoTypography.interTracking(12).abs(), lessThan(0.05));
      expect(KairoTypography.interTracking(17), lessThan(0));
      expect(
        KairoTypography.interTracking(34),
        lessThan(KairoTypography.interTracking(17)),
      );
    });

    test('follows Apple leading for the Large size', () {
      final t = KairoTypography.forPlatform(TargetPlatform.android);

      expect(t.largeTitle.fontSize! * t.largeTitle.height!, closeTo(41, 0.01));
      expect(t.footnote.fontSize! * t.footnote.height!, closeTo(18, 0.01));
    });

    test('multi-line body keeps line height of at least 1.35', () {
      final t = KairoTypography.forPlatform(TargetPlatform.android);
      expect(t.bodyMultiline.height, greaterThanOrEqualTo(1.35));
    });

    test('no text style is smaller than caption1', () {
      final t = KairoTypography.forPlatform(TargetPlatform.android);
      final sizes = [
        t.largeTitle,
        t.title1,
        t.title2,
        t.title3,
        t.headline,
        t.body,
        t.bodyMultiline,
        t.callout,
        t.subheadline,
        t.footnote,
        t.caption1,
      ].map((s) => s.fontSize!);
      expect(sizes.every((s) => s >= 12), isTrue);
    });

    test('timer uses tabular figures', () {
      final t = KairoTypography.forPlatform(TargetPlatform.android);
      expect(
        t.timer.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
