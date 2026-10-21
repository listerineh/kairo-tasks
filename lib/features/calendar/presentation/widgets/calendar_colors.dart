import 'package:flutter/painting.dart';

/// Parses a stored task color (`#RRGGBB` or `#AARRGGBB`); null if invalid.
Color? calendarColor(String? hex) {
  if (hex == null) return null;
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(parsed);
}
