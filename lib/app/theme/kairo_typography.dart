import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kairo 2.0 type scale (docs/redesign-plan.md §2.2): Apple's Dynamic Type
/// "Large" sizes and leading.
///
/// iOS uses the system font (SF Pro Text below 20 pt, Display above), which
/// is never bundled because its license only covers Apple platforms. Every
/// other platform uses Inter from `assets/fonts/`, which also keeps golden
/// tests deterministic.
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

  factory KairoTypography.forPlatform(TargetPlatform platform) {
    final apple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    TextStyle style(
      double size,
      double lineHeight,
      FontWeight weight, {
      double? height,
    }) {
      return TextStyle(
        fontFamily: apple ? (size >= 20 ? _sfDisplay : _sfText) : _inter,
        fontSize: size,
        height: height ?? lineHeight / size,
        fontWeight: weight,
        letterSpacing: apple ? _sfTracking(size) : interTracking(size),
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    return KairoTypography(
      largeTitle: style(34, 41, FontWeight.w700),
      title1: style(28, 34, FontWeight.w700),
      title2: style(22, 28, FontWeight.w700),
      title3: style(20, 25, FontWeight.w600),
      headline: style(17, 22, FontWeight.w600),
      body: style(17, 22, FontWeight.w400),
      bodyMultiline: style(17, 22, FontWeight.w400, height: 1.35),
      callout: style(16, 21, FontWeight.w400),
      subheadline: style(15, 20, FontWeight.w400),
      footnote: style(13, 18, FontWeight.w400),
      caption1: style(12, 16, FontWeight.w400),
      timer: style(
        76,
        76,
        FontWeight.w300,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }

  static const _inter = 'Inter';

  // Engine aliases that resolve to SF Pro Text / Display on Apple platforms.
  static const _sfText = 'CupertinoSystemText';
  static const _sfDisplay = 'CupertinoSystemDisplay';

  /// UIKit's default kerning (pt) for each Dynamic Type size.
  static double _sfTracking(double size) => switch (size) {
    34 => 0.37,
    28 => 0.36,
    22 => 0.35,
    20 => 0.38,
    17 => -0.41,
    16 => -0.32,
    15 => -0.24,
    13 => -0.08,
    _ => 0,
  };

  /// Inter's dynamic metrics (rsms.me/inter/dynmetrics): slightly open at
  /// caption sizes, tighter as size grows. Returns tracking in logical px.
  @visibleForTesting
  static double interTracking(double size) {
    final em = -0.0223 + 0.185 * math.exp(-0.1745 * size);
    return em * size;
  }

  /// Tab root titles (collapsing).
  final TextStyle largeTitle;

  /// Sheet hero, focus timer label.
  final TextStyle title1;

  /// Dashboard section headers.
  final TextStyle title2;

  /// Card titles.
  final TextStyle title3;

  /// Task and row titles.
  final TextStyle headline;

  /// Single-line body text.
  final TextStyle body;

  /// Descriptions and any wrapping body copy (line height >= 1.35).
  final TextStyle bodyMultiline;

  /// Secondary rows.
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
