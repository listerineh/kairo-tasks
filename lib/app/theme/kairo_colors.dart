import 'package:flutter/material.dart';

/// Kairo 2.0 color tokens (see docs/redesign-plan.md §2.1).
///
/// Every text pair passes WCAG AA (4.5:1) on `background`, `surface` and
/// `surfaceRaised`; `test/app/theme/kairo_colors_test.dart` enforces it.
/// Read them with `context.appColors`.
@immutable
class KairoColors extends ThemeExtension<KairoColors> {
  const KairoColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.fill,
    required this.label,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.separator,
    required this.tint,
    required this.tintSoft,
    required this.onTint,
    required this.destructive,
    required this.onDestructive,
    required this.priorityUrgent,
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
  });

  static const light = KairoColors(
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    fill: Color(0x1F787880),
    label: Color(0xFF000000),
    labelSecondary: Color(0xFF6C6C70),
    labelTertiary: Color(0x4D3C3C43),
    separator: Color(0x4A3C3C43),
    tint: Color(0xFF3A7449),
    tintSoft: Color(0x1F3A7449),
    onTint: Color(0xFFFFFFFF),
    destructive: Color(0xFFD70015),
    onDestructive: Color(0xFFFFFFFF),
    priorityUrgent: Color(0xFFD70015),
    priorityHigh: Color(0xFFC93400),
    priorityMedium: Color(0xFF0062CC),
    priorityLow: Color(0xFF6C6C70),
  );

  // Red and blue use Apple's increased-contrast dark variants: the standard
  // #FF453A / #0A84FF drop below 4.5:1 on surfaceRaised (#2C2C2E).
  static const dark = KairoColors(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceRaised: Color(0xFF2C2C2E),
    fill: Color(0x3D787880),
    label: Color(0xFFFFFFFF),
    labelSecondary: Color(0xFF98989F),
    labelTertiary: Color(0x4DEBEBF5),
    separator: Color(0x99545458),
    tint: Color(0xFF5FC27A),
    tintSoft: Color(0x335FC27A),
    onTint: Color(0xFF000000),
    destructive: Color(0xFFFF6961),
    onDestructive: Color(0xFF000000),
    priorityUrgent: Color(0xFFFF6961),
    priorityHigh: Color(0xFFFF9F0A),
    priorityMedium: Color(0xFF409CFF),
    priorityLow: Color(0xFF98989D),
  );

  /// systemGroupedBackground: behind grouped sections.
  final Color background;

  /// Cards and grouped rows.
  final Color surface;

  /// Sheets, menus, focused rows.
  final Color surfaceRaised;

  /// Inputs and segmented control tracks (translucent).
  final Color fill;

  final Color label;
  final Color labelSecondary;

  /// Placeholders and decoration only. Never informative text.
  final Color labelTertiary;

  /// Hairlines (0.5 logical px).
  final Color separator;

  final Color tint;
  final Color tintSoft;

  /// Text and icons on top of [tint].
  final Color onTint;

  final Color destructive;

  /// Text and icons on top of [destructive] or [priorityUrgent] fills.
  final Color onDestructive;

  final Color priorityUrgent;
  final Color priorityHigh;
  final Color priorityMedium;
  final Color priorityLow;

  // Legacy names from the 1.x palette, kept so unredesigned screens pick up
  // the accessible colors. Each phase migrates its screens; Phase 9 deletes
  // these.
  Color get surfaceElevated => surface;
  Color get surfaceSubtle => fill;
  Color get textPrimary => label;
  Color get textSecondary => labelSecondary;

  /// The old muted gray failed AA, so it maps to [labelSecondary].
  Color get textMuted => labelSecondary;
  Color get accent => tint;
  Color get accentSoft => tintSoft;
  Color get border => separator;
  Color get urgent => priorityUrgent;
  Color get high => priorityHigh;
  Color get medium => priorityMedium;
  Color get low => priorityLow;

  @override
  KairoColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? fill,
    Color? label,
    Color? labelSecondary,
    Color? labelTertiary,
    Color? separator,
    Color? tint,
    Color? tintSoft,
    Color? onTint,
    Color? destructive,
    Color? onDestructive,
    Color? priorityUrgent,
    Color? priorityHigh,
    Color? priorityMedium,
    Color? priorityLow,
  }) {
    return KairoColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      fill: fill ?? this.fill,
      label: label ?? this.label,
      labelSecondary: labelSecondary ?? this.labelSecondary,
      labelTertiary: labelTertiary ?? this.labelTertiary,
      separator: separator ?? this.separator,
      tint: tint ?? this.tint,
      tintSoft: tintSoft ?? this.tintSoft,
      onTint: onTint ?? this.onTint,
      destructive: destructive ?? this.destructive,
      onDestructive: onDestructive ?? this.onDestructive,
      priorityUrgent: priorityUrgent ?? this.priorityUrgent,
      priorityHigh: priorityHigh ?? this.priorityHigh,
      priorityMedium: priorityMedium ?? this.priorityMedium,
      priorityLow: priorityLow ?? this.priorityLow,
    );
  }

  @override
  KairoColors lerp(KairoColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return KairoColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      fill: l(fill, other.fill),
      label: l(label, other.label),
      labelSecondary: l(labelSecondary, other.labelSecondary),
      labelTertiary: l(labelTertiary, other.labelTertiary),
      separator: l(separator, other.separator),
      tint: l(tint, other.tint),
      tintSoft: l(tintSoft, other.tintSoft),
      onTint: l(onTint, other.onTint),
      destructive: l(destructive, other.destructive),
      onDestructive: l(onDestructive, other.onDestructive),
      priorityUrgent: l(priorityUrgent, other.priorityUrgent),
      priorityHigh: l(priorityHigh, other.priorityHigh),
      priorityMedium: l(priorityMedium, other.priorityMedium),
      priorityLow: l(priorityLow, other.priorityLow),
    );
  }
}
