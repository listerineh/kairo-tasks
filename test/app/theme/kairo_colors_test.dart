import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/kairo_colors.dart';

/// WCAG 2.x contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [
    ('light', KairoColors.light),
    ('dark', KairoColors.dark),
  ]) {
    group('$name palette meets WCAG AA', () {
      final surfaces = {
        'background': c.background,
        'surface': c.surface,
        'surfaceRaised': c.surfaceRaised,
      };
      final textTokens = {
        'label': c.label,
        'labelSecondary': c.labelSecondary,
        'tint': c.tint,
        'destructive': c.destructive,
        'priorityUrgent': c.priorityUrgent,
        'priorityHigh': c.priorityHigh,
        'priorityMedium': c.priorityMedium,
        'priorityLow': c.priorityLow,
      };

      for (final text in textTokens.entries) {
        for (final surface in surfaces.entries) {
          test('${text.key} on ${surface.key}', () {
            expect(
              contrast(text.value, surface.value),
              greaterThanOrEqualTo(4.5),
            );
          });
        }
      }

      test('onTint on tint', () {
        expect(contrast(c.onTint, c.tint), greaterThanOrEqualTo(4.5));
      });

      test('text on the ink surface', () {
        expect(contrast(c.onInk, c.ink), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onInkSecondary, c.ink), greaterThanOrEqualTo(4.5));
        expect(contrast(c.lime, c.ink), greaterThanOrEqualTo(4.5));
      });

      test('onLime on lime buttons', () {
        expect(contrast(c.onLime, c.lime), greaterThanOrEqualTo(4.5));
      });

      test('onDestructive on destructive and priorityUrgent fills', () {
        expect(
          contrast(c.onDestructive, c.destructive),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(c.onDestructive, c.priorityUrgent),
          greaterThanOrEqualTo(4.5),
        );
      });
    });
  }

  test('legacy textMuted resolves to an accessible token', () {
    expect(KairoColors.light.textMuted, KairoColors.light.labelSecondary);
    expect(KairoColors.dark.textMuted, KairoColors.dark.labelSecondary);
  });

  test('lerp reaches both ends for animated theme switches', () {
    expect(
      KairoColors.light.lerp(KairoColors.dark, 0).tint,
      KairoColors.light.tint,
    );
    expect(
      KairoColors.light.lerp(KairoColors.dark, 1).tint,
      KairoColors.dark.tint,
    );
  });
}
