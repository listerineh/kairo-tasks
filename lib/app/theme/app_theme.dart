import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'kairo_colors.dart';
import 'kairo_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  /// The theme golden tests use. Fonts are bundled, so it matches the app;
  /// it stays a separate entry point for test-only tweaks.
  @visibleForTesting
  static ThemeData golden(Brightness brightness) => _buildTheme(brightness);

  static ThemeData _buildTheme(Brightness brightness) {
    const fonts = _LegacyFonts();
    final isLight = brightness == Brightness.light;
    final colors = isLight ? KairoColors.light : KairoColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors, KairoTypography.standard()],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.onTint,
        secondary: colors.accentSoft,
        onSecondary: colors.textPrimary,
        error: colors.destructive,
        onError: colors.onDestructive,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        surfaceContainerHighest: colors.surfaceRaised,
        outline: colors.border,
      ),
      textTheme: _buildTextTheme(colors, fonts),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: fonts.serif(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: colors.textPrimary,
          height: 1.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          side: BorderSide(color: colors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onTint,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          textStyle: fonts.sans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          side: BorderSide(color: colors.accent),
          textStyle: fonts.sans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing16,
          vertical: AppSpacing.spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: BorderSide(color: colors.urgent),
        ),
        hintStyle: fonts.sans(color: colors.textMuted, fontSize: 14),
        labelStyle: fonts.sans(color: colors.textSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfaceElevated,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: fonts.sans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: fonts.sans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 0.5,
        space: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.onTint,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(KairoColors colors, _LegacyFonts fonts) {
    return TextTheme(
      displayLarge: fonts.serif(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
        height: 1.3,
      ),
      displayMedium: fonts.serif(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
        height: 1.3,
      ),
      titleLarge: fonts.serif(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
        height: 1.3,
      ),
      titleMedium: fonts.sans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.4,
      ),
      titleSmall: fonts.sans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.4,
      ),
      bodyLarge: fonts.sans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
        height: 1.6,
        letterSpacing: 0.2,
      ),
      bodyMedium: fonts.sans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
        height: 1.6,
        letterSpacing: 0.2,
      ),
      bodySmall: fonts.sans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textMuted,
        height: 1.5,
      ),
      labelLarge: fonts.sans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.4,
        letterSpacing: 0.3,
      ),
      labelMedium: fonts.sans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
        height: 1.4,
      ),
      labelSmall: fonts.sans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colors.textMuted,
        height: 1.4,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// The Material text theme for screens not yet migrated to
/// [KairoTypography]. Both the old sans and serif roles render in Manrope;
/// the serif (display) roles become heavy and tight like the new titles.
/// V11 removes this.
class _LegacyFonts {
  const _LegacyFonts();

  TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final weight = fontWeight ?? FontWeight.w500;
    return TextStyle(
      fontFamily: KairoTypography.family,
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle serif({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return sans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: color,
      height: height,
      letterSpacing: letterSpacing ?? -0.5,
    );
  }
}
