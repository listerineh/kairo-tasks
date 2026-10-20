import 'kairo_colors.dart';

export 'kairo_colors.dart';

/// Legacy entry points for the 1.x palette. Screens still typed against
/// [AppColorScheme] now receive [KairoColors]; Phase 9 removes this file.
typedef AppColorScheme = KairoColors;

class AppColors {
  AppColors._();

  static const AppColorScheme light = KairoColors.light;
  static const AppColorScheme dark = KairoColors.dark;
}
