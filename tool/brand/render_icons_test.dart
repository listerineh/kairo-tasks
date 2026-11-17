// Renders the app icon and splash images from their SVG sources.
//
//   flutter test tool/brand/render_icons_test.dart
//   dart run flutter_launcher_icons
//
// Sources: assets/icons/app_icon.svg (the icon) and
// tool/brand/app_icon_foreground.svg (Android's adaptive foreground).
// It runs as a test only to use Flutter's own SVG renderer; it is not part
// of `flutter test` (that runs test/).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _render(
  String source,
  String out,
  int size, {
  double cornerRadius = 0,
}) async {
  final info = await vg.loadPicture(
    SvgStringLoader(File(source).readAsStringSync()),
    null,
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = size.toDouble();
  if (cornerRadius > 0) {
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & Size.square(side),
        Radius.circular(side * cornerRadius),
      ),
    );
  }
  canvas
    ..scale(side / info.size.width)
    ..drawPicture(info.picture);
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(out)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
  info.picture.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders the icon and splash images', () async {
    const icon = 'assets/icons/app_icon.svg';
    await _render(icon, 'assets/icons/app_icon_1024.png', 1024);
    await _render(
      'tool/brand/app_icon_foreground.svg',
      'assets/icons/app_icon_foreground.png',
      1024,
    );

    // The launch screen shows the icon as a 96 pt rounded tile.
    const launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
    for (final (scale, suffix) in [(1, ''), (2, '@2x'), (3, '@3x')]) {
      await _render(
        icon,
        '$launch/LaunchImage$suffix.png',
        96 * scale,
        cornerRadius: 0.224,
      );
    }
  });
}
