import 'package:flutter/material.dart';

/// Kairo 2.0 type scale (docs/design.md § Typography).
///
/// Manrope on every platform, bundled as a variable font so iOS, Android and
/// golden tests render the same glyphs. Each style sets the `wght` axis to
/// match its [FontWeight].
///
/// Styles carry no color, so they inherit from the surrounding
/// `DefaultTextStyle`. Font sizes go through `MediaQuery.textScaler`, so
/// never hardcode them.
@immutable
class KairoTypography extends ThemeExtension<KairoTypography> {
  const KairoTypography({
    required this.largeTitle,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.headline,
    required this.body,
    required this.bodyMultiline,
    required this.callout,
    required this.subheadline,
    required this.footnote,
    required this.caption1,
    required this.timer,
  });

  factory KairoTypography.standard() {
    return KairoTypography(
      largeTitle: manrope(30, 36, FontWeight.w800, tracking: -0.8),
      title1: manrope(26, 32, FontWeight.w800, tracking: -0.6),
      title2: manrope(20, 26, FontWeight.w800, tracking: -0.4),
      title3: manrope(18, 24, FontWeight.w700, tracking: -0.3),
      headline: manrope(16, 22, FontWeight.w700, tracking: -0.1),
      body: manrope(16, 22, FontWeight.w600),
      bodyMultiline: manrope(16, 22, FontWeight.w600, height: 1.38),
      callout: manrope(15, 20, FontWeight.w600),
      subheadline: manrope(14, 19, FontWeight.w600),
      footnote: manrope(13, 18, FontWeight.w600),
      caption1: manrope(12, 16, FontWeight.w600),
      timer: manrope(
        58,
        58,
        FontWeight.w600,
        tracking: -2,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }

  static const family = 'Manrope';

  /// A Manrope style at [size] with [lineHeight] in logical px (or an
  /// explicit [height] multiplier).
  static TextStyle manrope(
    double size,
    double lineHeight,
    FontWeight weight, {
    double tracking = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height ?? lineHeight / size,
      fontWeight: weight,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      letterSpacing: tracking,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// Tab titles ("Buenos días", "Planear").
  final TextStyle largeTitle;

  /// Sheet titles and the Kairo page.
  final TextStyle title1;

  /// Section headers ("Pendientes").
  final TextStyle title2;

  /// Card titles.
  final TextStyle title3;

  /// Row titles and buttons.
  final TextStyle headline;

  /// Single-line body text.
  final TextStyle body;

  /// Suggestions, descriptions and any wrapping copy (line height >= 1.35).
  final TextStyle bodyMultiline;

  /// Chips and secondary rows.
  final TextStyle callout;

  /// Metadata.
  final TextStyle subheadline;

  /// Section footers and hints.
  final TextStyle footnote;

  /// Calendar labels; the smallest size allowed for text.
  final TextStyle caption1;

  /// Focus countdown only (tabular figures).
  final TextStyle timer;

  @override
  KairoTypography copyWith({
    TextStyle? largeTitle,
    TextStyle? title1,
    TextStyle? title2,
    TextStyle? title3,
    TextStyle? headline,
    TextStyle? body,
    TextStyle? bodyMultiline,
    TextStyle? callout,
    TextStyle? subheadline,
    TextStyle? footnote,
    TextStyle? caption1,
    TextStyle? timer,
  }) {
    return KairoTypography(
      largeTitle: largeTitle ?? this.largeTitle,
      title1: title1 ?? this.title1,
      title2: title2 ?? this.title2,
      title3: title3 ?? this.title3,
      headline: headline ?? this.headline,
      body: body ?? this.body,
      bodyMultiline: bodyMultiline ?? this.bodyMultiline,
      callout: callout ?? this.callout,
      subheadline: subheadline ?? this.subheadline,
      footnote: footnote ?? this.footnote,
      caption1: caption1 ?? this.caption1,
      timer: timer ?? this.timer,
    );
  }

  @override
  KairoTypography lerp(KairoTypography? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return KairoTypography(
      largeTitle: l(largeTitle, other.largeTitle),
      title1: l(title1, other.title1),
      title2: l(title2, other.title2),
      title3: l(title3, other.title3),
      headline: l(headline, other.headline),
      body: l(body, other.body),
      bodyMultiline: l(bodyMultiline, other.bodyMultiline),
      callout: l(callout, other.callout),
      subheadline: l(subheadline, other.subheadline),
      footnote: l(footnote, other.footnote),
      caption1: l(caption1, other.caption1),
      timer: l(timer, other.timer),
    );
  }
}
