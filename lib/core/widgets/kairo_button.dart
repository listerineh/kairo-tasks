import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';
import 'pressable.dart';

enum KairoButtonVariant {
  /// Solid tint: the one primary action on a screen.
  filled,

  /// Soft tint fill: secondary actions.
  tinted,

  /// Text only: tertiary actions and toolbars.
  plain,
}

/// Capsule button in the three iOS weights.
///
/// Height grows with the text scale (minimum 50, above the 44 pt target).
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
    final accent = destructive ? colors.destructive : colors.tint;
    final (background, foreground) = switch (variant) {
      KairoButtonVariant.filled => (
        accent,
        destructive ? colors.onDestructive : colors.onTint,
      ),
      KairoButtonVariant.tinted => (accent.withValues(alpha: 0.12), accent),
      KairoButtonVariant.plain => (Colors.transparent, accent),
    };
    final enabled = onPressed != null && !loading;
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
        opacity: onPressed == null ? 0.4 : 1,
        child: Pressable(
          onPressed: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 50,
              minWidth: expand ? double.infinity : 0,
            ),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: background,
                shape: const StadiumBorder(),
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
