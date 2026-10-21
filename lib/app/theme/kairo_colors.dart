import 'package:flutter/material.dart';

/// Kairo 2.0 color tokens, "Calma viva" palette (docs/design.md § Color).
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
    required this.ink,
    required this.onInk,
    required this.onInkSecondary,
    required this.lime,
    required this.onLime,
    required this.apricot,
  });

  static const light = KairoColors(
    background: Color(0xFFF1F2EF),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    fill: Color(0xFFE6E9E5),
    label: Color(0xFF121417),
    labelSecondary: Color(0xFF59616B),
    labelTertiary: Color(0x4D121417),
    separator: Color(0xFFE1E4E0),
    tint: Color(0xFF1E5B45),
    tintSoft: Color(0xFFE3EEE8),
    onTint: Color(0xFFFFFFFF),
    destructive: Color(0xFFC8323F),
    onDestructive: Color(0xFFFFFFFF),
    priorityUrgent: Color(0xFFC8323F),
    priorityHigh: Color(0xFFA9550E),
    priorityMedium: Color(0xFF3F6FA8),
    priorityLow: Color(0xFF646C75),
    ink: Color(0xFF121417),
    onInk: Color(0xFFF3F5F2),
    onInkSecondary: Color(0xFFA7AFB7),
    lime: Color(0xFFC6E96F),
    onLime: Color(0xFF121417),
    apricot: Color(0xFFE58A52),
  );

  static const dark = KairoColors(
    background: Color(0xFF0E1012),
    surface: Color(0xFF181B1E),
    surfaceRaised: Color(0xFF22262A),
    fill: Color(0xFF2A2E33),
    label: Color(0xFFF3F5F2),
    labelSecondary: Color(0xFFA7AFB7),
    labelTertiary: Color(0x4DF3F5F2),
    separator: Color(0xFF2E3237),
    tint: Color(0xFF86CFA0),
    tintSoft: Color(0x2E86CFA0),
    onTint: Color(0xFF0E1012),
    destructive: Color(0xFFFF7A7A),
    onDestructive: Color(0xFF0E1012),
    priorityUrgent: Color(0xFFFF7A7A),
    priorityHigh: Color(0xFFF2A65A),
    priorityMedium: Color(0xFF86AEE3),
    priorityLow: Color(0xFFA7AFB7),
    ink: Color(0xFF262A30),
    onInk: Color(0xFFF3F5F2),
    onInkSecondary: Color(0xFFA7AFB7),
    lime: Color(0xFFC6E96F),
    onLime: Color(0xFF121417),
    apricot: Color(0xFFF0A070),
  );

  /// Niebla: the screen background.
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

  /// The one dark accent surface per screen: tab bar, "Ahora" card,
  /// primary buttons.
  final Color ink;

  /// Text and icons on [ink].
  final Color onInk;

  /// Secondary text and idle icons on [ink].
  final Color onInkSecondary;

  /// Accent on [ink] only (active tab, Enfocar, focus ring).
  final Color lime;

  /// Text and icons on [lime] buttons (dark in both themes).
  final Color onLime;

  /// Streak and celebration. Icons and decoration only, never text.
  final Color apricot;

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
    Color? ink,
    Color? onInk,
    Color? onInkSecondary,
    Color? lime,
    Color? onLime,
    Color? apricot,
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
      ink: ink ?? this.ink,
      onInk: onInk ?? this.onInk,
      onInkSecondary: onInkSecondary ?? this.onInkSecondary,
      lime: lime ?? this.lime,
      onLime: onLime ?? this.onLime,
      apricot: apricot ?? this.apricot,
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
      ink: l(ink, other.ink),
      onInk: l(onInk, other.onInk),
      onInkSecondary: l(onInkSecondary, other.onInkSecondary),
      lime: l(lime, other.lime),
      onLime: l(onLime, other.onLime),
      apricot: l(apricot, other.apricot),
    );
  }
}
