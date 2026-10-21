import 'package:flutter/material.dart';

/// Parses a stored task color (`#RRGGBB` or `#AARRGGBB`); null if invalid.
Color? calendarColor(String? hex) {
  if (hex == null) return null;
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(parsed);
}

/// One of the five muted calendar tones (docs/design.md § Calendar and
/// people). Text on a tone is always dark in light mode and `label` in dark.
@immutable
class CalendarTone {
  const CalendarTone({
    required this.name,
    required this.fill,
    required this.dot,
    required this.ink,
  });

  final String name;

  /// Block background in light mode.
  final Color fill;

  /// Owner marker; also the base of the dark-mode fill.
  final Color dot;

  /// Secondary text on [fill] in light mode.
  final Color ink;

  static const sage = CalendarTone(
    name: 'sage',
    fill: Color(0xFFDCEBE1),
    dot: Color(0xFF3E8A62),
    ink: Color(0xFF2C5B42),
  );
  static const blue = CalendarTone(
    name: 'blue',
    fill: Color(0xFFDDE7F2),
    dot: Color(0xFF3F6FA8),
    ink: Color(0xFF2D4F78),
  );
  static const clay = CalendarTone(
    name: 'clay',
    fill: Color(0xFFF4E2D7),
    dot: Color(0xFFC26A3D),
    ink: Color(0xFF7A3B1A),
  );
  static const iris = CalendarTone(
    name: 'iris',
    fill: Color(0xFFE6E3F5),
    dot: Color(0xFF6A62B8),
    ink: Color(0xFF3B3570),
  );
  static const sand = CalendarTone(
    name: 'sand',
    fill: Color(0xFFF1EAD2),
    dot: Color(0xFFA1842A),
    ink: Color(0xFF5E4C12),
  );

  static const all = [sage, blue, clay, iris, sand];

  /// The tone closest in hue to a stored owner color. Grays and unknown
  /// colors fall back to [blue].
  static CalendarTone of(String? hex) {
    final color = calendarColor(hex);
    if (color == null) return blue;
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < 0.08) return blue;
    var best = blue;
    var bestDistance = double.infinity;
    for (final tone in all) {
      final d = _hueDistance(hsl.hue, HSLColor.fromColor(tone.dot).hue);
      if (d < bestDistance) {
        bestDistance = d;
        best = tone;
      }
    }
    return best;
  }

  static double _hueDistance(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  /// Block background for [brightness]: the light fill, or the dot blended
  /// into the dark surface.
  Color fillFor(Brightness brightness, Color darkSurface) =>
      brightness == Brightness.light
      ? fill
      : Color.alphaBlend(dot.withValues(alpha: 0.32), darkSurface);
}
