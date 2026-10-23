import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';
import 'pressable.dart';

enum KairoButtonVariant {
  /// Solid `ink`: the one primary action on a screen.
  filled,

  /// Lime with dark text. Only on `ink` surfaces ("Enfocar").
  accent,

  /// Soft tint fill: secondary actions.
  tinted,

  /// White with a hairline outline: secondary actions next to a primary.
  outline,

  /// Text only: tertiary actions and toolbars.
  plain,
}

/// Capsule button (docs/design.md § Buttons).
///
/// Height grows with the text scale (minimum 52, above the 44 pt target).
/// A disabled filled button turns into a quiet `fill` capsule instead of a
/// faded one, so its label stays readable.
class KairoButton extends StatelessWidget {
  const KairoButton({
    required this.label,
    required this.onPressed,
    this.variant = KairoButtonVariant.filled,
    this.icon,
    this.destructive = false,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final KairoButtonVariant variant;
  final IconData? icon;
  final bool destructive;

  /// Shows a spinner in place of the content and ignores taps.
  final bool loading;

  /// Fills the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null && !loading;
    final tint = destructive ? colors.destructive : colors.tint;
    final (background, foreground, outline) = switch (variant) {
      _ when onPressed == null && variant != KairoButtonVariant.plain => (
        colors.fill,
        colors.labelSecondary,
        null,
      ),
      KairoButtonVariant.filled => (
        destructive ? colors.destructive : colors.ink,
        destructive ? colors.onDestructive : colors.onInk,
        null,
      ),
      KairoButtonVariant.accent => (colors.lime, colors.onLime, null),
      KairoButtonVariant.tinted => (
        destructive ? tint.withValues(alpha: 0.12) : colors.tintSoft,
        tint,
        null,
      ),
      KairoButtonVariant.outline => (
        colors.surface,
        destructive ? colors.destructive : colors.label,
        colors.separator,
      ),
      KairoButtonVariant.plain => (Colors.transparent, tint, null),
    };
    final textStyle = context.typography.headline.copyWith(color: foreground);

    final content = loading
        ? CupertinoActivityIndicator(color: foreground)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: foreground,
                  size: MediaQuery.textScalerOf(context).scale(20),
                ),
                const SizedBox(width: AppSpacing.spacing8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? label : null,
      excludeSemantics: loading,
      child: Opacity(
        opacity: onPressed == null && variant == KairoButtonVariant.plain
            ? 0.4
            : 1,
        child: Pressable(
          onPressed: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 52,
              minWidth: expand ? double.infinity : 0,
            ),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: background,
                shape: StadiumBorder(
                  side: outline == null
                      ? BorderSide.none
                      : BorderSide(color: outline),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing20,
                  vertical: AppSpacing.spacing12,
                ),
                child: Center(
                  widthFactor: expand ? null : 1,
                  heightFactor: 1,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
