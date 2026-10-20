import 'package:flutter/material.dart';

import '../../app/theme/kairo_colors.dart';
import '../../app/theme/kairo_typography.dart';
import '../../generated/app_localizations.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Kairo color tokens from the active theme (animates with theme changes).
  KairoColors get appColors => Theme.of(this).extension<KairoColors>()!;

  /// Kairo 2.0 type scale for the current platform.
  KairoTypography get typography =>
      Theme.of(this).extension<KairoTypography>()!;

  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
