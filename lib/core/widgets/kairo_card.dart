import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';

/// Which surface a [KairoCard] uses (docs/design.md § Components).
enum KairoCardStyle {
  /// Flat white tile on the background (radius 22).
  tile,

  /// The screen's hero: white, radius 28, soft elevation.
  hero,

  /// The one dark accent surface (radius 28), for "Ahora"-style cards.
  ink,
}

/// A card in the Kairo 2.0 radius hierarchy. Content is clipped to the
/// shape, so rows inside it need no corners of their own.
class KairoCard extends StatelessWidget {
  const KairoCard({
    required this.child,
    this.style = KairoCardStyle.tile,
    this.padding = const EdgeInsets.all(AppSpacing.spacing16),
    super.key,
  });

  final Widget child;
  final KairoCardStyle style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(
      style == KairoCardStyle.tile
          ? AppSpacing.radiusTile
          : AppSpacing.radiusHero,
    );
    final ink = style == KairoCardStyle.ink;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink ? colors.ink : colors.surface,
        borderRadius: radius,
        boxShadow: style == KairoCardStyle.hero ? heroShadow : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: ink ? colors.onInk : colors.label),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }

  /// The only card elevation: a contact shadow plus a wide, faint one.
  static const heroShadow = [
    BoxShadow(color: Color(0x0A121417), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F121417), blurRadius: 32, offset: Offset(0, 12)),
  ];
}
