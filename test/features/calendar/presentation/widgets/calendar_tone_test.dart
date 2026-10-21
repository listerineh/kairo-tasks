import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/calendar/presentation/widgets/calendar_colors.dart';

void main() {
  group('CalendarTone.of', () {
    test('maps owner colors to the nearest tone by hue', () {
      expect(CalendarTone.of('#3A7449'), CalendarTone.sage);
      expect(CalendarTone.of('#0062CC'), CalendarTone.blue);
      expect(CalendarTone.of('#C93400'), CalendarTone.clay);
      expect(CalendarTone.of('#AF52DE'), CalendarTone.iris);
      expect(CalendarTone.of('#C9A227'), CalendarTone.sand);
    });

    test('falls back to blue for grays, invalid and missing colors', () {
      expect(CalendarTone.of('#6C6C70'), CalendarTone.blue);
      expect(CalendarTone.of('nope'), CalendarTone.blue);
      expect(CalendarTone.of(null), CalendarTone.blue);
    });
  });

  test('fillFor uses the light fill, or blends the dot into dark', () {
    const surface = Color(0xFF1B1E22);
    expect(
      CalendarTone.sage.fillFor(Brightness.light, surface),
      CalendarTone.sage.fill,
    );
    expect(
      CalendarTone.sage.fillFor(Brightness.dark, surface),
      Color.alphaBlend(CalendarTone.sage.dot.withValues(alpha: 0.32), surface),
    );
  });
}
