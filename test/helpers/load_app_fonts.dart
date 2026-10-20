import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads every font declared in the app (and its packages) so golden tests
/// render real glyphs instead of the Ahem placeholder boxes.
///
/// Reads the `FontManifest.json` that `flutter test` builds from pubspec, so
/// fonts added under `flutter: fonts:` are picked up without touching this file.
Future<void> loadAppFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;

  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}
