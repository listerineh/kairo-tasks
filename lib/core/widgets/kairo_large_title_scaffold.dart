import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';

/// Root-tab scaffold with an iOS large title that collapses into a
/// translucent inline bar as content scrolls under it.
///
/// Works on both platforms (it is a sliver header, not a Cupertino nav bar).
/// The collapse follows the scroll position directly, so it is the user's own
/// motion and stays on under reduced motion.
class KairoLargeTitleScaffold extends StatelessWidget {
  const KairoLargeTitleScaffold({
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.controller,
    super.key,
  });

  final String title;
  final List<Widget> slivers;

  /// Trailing bar buttons (icon buttons with tooltips).
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: context.appColors.background,
      extendBody: true,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: CustomScrollView(
        controller: controller,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _LargeTitleHeader(
              title: title,
              actions: actions,
              topPadding: media.padding.top,
              textScaler: media.textScaler,
            ),
          ),
          ...slivers,
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: media.padding.bottom + AppSpacing.spacing32,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeTitleHeader extends SliverPersistentHeaderDelegate {
  _LargeTitleHeader({
    required this.title,
    required this.actions,
    required this.topPadding,
    required this.textScaler,
  });

  final String title;
  final List<Widget> actions;
  final double topPadding;
  final TextScaler textScaler;

  static const double _barHeight = 44;

  double get _largeTitleHeight => textScaler.scale(41) + AppSpacing.spacing8;

  @override
  double get minExtent => topPadding + _barHeight;

  @override
  double get maxExtent => minExtent + _largeTitleHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final colors = context.appColors;
    final type = context.typography;
    final collapse = (shrinkOffset / _largeTitleHeight).clamp(0.0, 1.0);
    // The bar turns opaque only once content actually slides under it.
    final material = ((collapse - 0.85) / 0.15).clamp(0.0, 1.0);
    final inlineTitle = ((collapse - 0.7) / 0.3).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: material,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(
                      color: colors.separator,
                      width: AppSpacing.hairline,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          height: _barHeight,
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.spacing8),
              // Pushed screens (e.g. Tasks over Hoy) get a back button.
              if (Navigator.canPop(context))
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: Icon(CupertinoIcons.chevron_back, color: colors.tint),
                  onPressed: () => Navigator.maybePop(context),
                ),
              Expanded(
                child: Opacity(
                  opacity: inlineTitle,
                  // The large title already announces it.
                  child: ExcludeSemantics(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.headline.copyWith(color: colors.label),
                    ),
                  ),
                ),
              ),
              IconTheme.merge(
                data: IconThemeData(color: colors.tint),
                child: Row(mainAxisSize: MainAxisSize.min, children: actions),
              ),
              const SizedBox(width: AppSpacing.spacing8),
            ],
          ),
        ),
        Positioned(
          left: AppSpacing.screenMargin,
          right: AppSpacing.screenMargin,
          bottom:
              AppSpacing.spacing8 - shrinkOffset.clamp(0, _largeTitleHeight),
          child: Opacity(
            opacity: 1 - collapse,
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.largeTitle.copyWith(color: colors.label),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(_LargeTitleHeader oldDelegate) =>
      title != oldDelegate.title ||
      actions != oldDelegate.actions ||
      topPadding != oldDelegate.topPadding ||
      textScaler != oldDelegate.textScaler;
}
