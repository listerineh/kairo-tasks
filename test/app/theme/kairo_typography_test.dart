import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/kairo_typography.dart';

void main() {
  group('KairoTypography', () {
    final t = KairoTypography.standard();
    final all = [
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
      t.timer,
    ];

    test('every style is Manrope with the wght axis matching its weight', () {
      for (final style in all) {
        expect(style.fontFamily, 'Manrope');
        expect(style.fontVariations, [
          FontVariation.weight(style.fontWeight!.value.toDouble()),
        ]);
      }
    });

    test('titles are heavy and tight, text is not tracked', () {
      expect(t.largeTitle.fontWeight, FontWeight.w800);
      expect(t.largeTitle.letterSpacing, lessThan(0));
      expect(t.body.letterSpacing, 0);
    });

    test('line heights follow the scale', () {
      expect(t.largeTitle.fontSize! * t.largeTitle.height!, closeTo(36, 0.01));
      expect(t.footnote.fontSize! * t.footnote.height!, closeTo(18, 0.01));
    });

    test('multi-line body keeps line height of at least 1.35', () {
      expect(t.bodyMultiline.height, greaterThanOrEqualTo(1.35));
    });

    test('no text style is smaller than caption1', () {
      expect(all.every((s) => s.fontSize! >= 12), isTrue);
    });

    test('timer uses tabular figures', () {
      expect(
        t.timer.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
