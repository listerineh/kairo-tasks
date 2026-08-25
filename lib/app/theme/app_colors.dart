import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const AppColorScheme light = AppColorScheme(
    surface: Color(0xFFFAF9F7),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF3F1ED),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    textMuted: Color(0xFF9B9B9B),
    accent: Color(0xFF4A6741),
    accentSoft: Color(0xFFE8F0E6),
    urgent: Color(0xFFC45D4A),
    high: Color(0xFFD4894A),
    medium: Color(0xFF6B8FA3),
    low: Color(0xFF8B9D83),
    border: Color(0xFFE5E2DE),
  );

  static const AppColorScheme dark = AppColorScheme(
    surface: Color(0xFF1A1B1E),
    surfaceElevated: Color(0xFF242529),
    surfaceSubtle: Color(0xFF2C2D31),
    textPrimary: Color(0xFFF0EDE8),
    textSecondary: Color(0xFFB0ADA8),
    textMuted: Color(0xFF6B6964),
    accent: Color(0xFF7CAD71),
    accentSoft: Color(0xFF2A3528),
    urgent: Color(0xFFE07B6A),
    high: Color(0xFFE8A366),
    medium: Color(0xFF7FAABB),
    low: Color(0xFFA3B59B),
    border: Color(0xFF3A3B3F),
  );
}

class AppColorScheme {
  const AppColorScheme({
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.urgent,
    required this.high,
    required this.medium,
    required this.low,
    required this.border,
  });

  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color urgent;
  final Color high;
  final Color medium;
  final Color low;
  final Color border;
}
