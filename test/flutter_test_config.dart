import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/load_app_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppFonts();
  await testMain();
}
