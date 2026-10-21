import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';
import 'kairo_sheet.dart';

/// Inset grouped section (iOS Settings style): optional sentence-case
/// header and footer around a rounded group of rows with inset hairlines.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    required this.children,
    this.header,
    this.footer,
    this.separatorInset,
    super.key,
  });

  final List<Widget> children;

  /// Sentence case, never all caps.
  final String? header;
  final String? footer;

  /// Where hairlines start for children that are not [GroupedRow]s (which
  /// know their own inset). Defaults to 16, the row text start.
  final double? separatorInset;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final footnote = context.typography.footnote.copyWith(
      color: colors.labelSecondary,
    );
    // Header and footer text lines up with the row text inside the group.
    const textInset = EdgeInsets.symmetric(horizontal: AppSpacing.spacing16);

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      rows.add(child);
      if (i < children.length - 1) {
        final inset = child is GroupedRow
            ? child.separatorInset
            : separatorInset ?? 16.0;
        rows.add(
          Padding(
            padding: EdgeInsetsDirectional.only(start: inset),
            child: Container(
              height: AppSpacing.hairline,
              color: colors.separator,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: textInset.copyWith(bottom: 6),
              child: Semantics(
                header: true,
                child: Text(header!, style: footnote),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
            child: ColoredBox(
              color: KairoSheetScope.isInSheet(context)
                  ? colors.surfaceRaised
                  : colors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: textInset.copyWith(top: 6),
              child: Text(footer!, style: footnote),
            ),
        ],
      ),
    );
  }
}

/// One row inside a [GroupedSection]: optional leading symbol, title,
/// subtitle, trailing value and disclosure chevron. At least 44 pt tall.
class GroupedRow extends StatefulWidget {
  const GroupedRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Usually an icon; laid out in a fixed slot so titles align.
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool destructive;

  static const double _leadingSlot = 28;
  static const double _gap = 12;

  /// Where the hairline under this row starts: at the title.
  double get separatorInset =>
      AppSpacing.spacing16 + (leading == null ? 0 : _leadingSlot + _gap);

  @override
  State<GroupedRow> createState() => _GroupedRowState();
}

class _GroupedRowState extends State<GroupedRow> {
  bool _highlighted = false;

  void _setHighlighted(bool value) {
    if (_highlighted != value) setState(() => _highlighted = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final type = context.typography;
    final interactive = widget.onTap != null;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing16,
          vertical: 11,
        ),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              SizedBox(
                width: GroupedRow._leadingSlot,
                child: IconTheme.merge(
                  data: IconThemeData(color: colors.tint, size: 22),
                  child: Center(child: widget.leading),
                ),
              ),
              const SizedBox(width: GroupedRow._gap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: type.body.copyWith(
                      color: widget.destructive
                          ? colors.destructive
                          : colors.label,
                    ),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: type.subheadline.copyWith(
                        color: colors.labelSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: AppSpacing.spacing8),
              DefaultTextStyle.merge(
                style: type.body.copyWith(color: colors.labelSecondary),
                child: widget.trailing!,
              ),
            ],
            if (widget.showChevron) ...[
              const SizedBox(width: AppSpacing.spacing8),
              ExcludeSemantics(
                child: Icon(
                  CupertinoIcons.chevron_forward,
                  size: 16,
                  color: colors.labelTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!interactive) return row;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setHighlighted(true),
        onTapUp: (_) => _setHighlighted(false),
        onTapCancel: () => _setHighlighted(false),
        // Highlight is instant like iOS; it is feedback, not motion.
        child: ColoredBox(
          color: _highlighted ? colors.fill : Colors.transparent,
          child: row,
        ),
      ),
    );
  }
}
