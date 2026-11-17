import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../widgets/tour_vignettes.dart';

/// The first-run tour (docs/design.md § Login and onboarding).
///
/// Four steps, each a small live piece of the app that plays once as it
/// comes into view: Kairo says hello, a task under "Now" gets done, the
/// focus ring draws itself, a shared task fills up and a friend nudges you.
/// Story-style bars on top, Skip until the last step, a back button and one
/// `ink` button. Swiping works too.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _page = 0;

  static const _count = 4;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) context.go('/login');
  }

  void _goTo(int page) {
    final motion = context.motion;
    unawaited(
      _pages.animateToPage(
        page,
        duration: motion.duration(KairoSpring.smooth),
        curve: motion.curve(KairoSpring.smooth),
      ),
    );
  }

  void _next() {
    if (_page == _count - 1) {
      unawaited(_finish());
    } else {
      _goTo(_page + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final motion = context.motion;
    final steps = [
      (l10n.tourTitle1, l10n.tourBody1),
      (l10n.tourTitle2, l10n.tourBody2),
      (l10n.tourTitle3, l10n.tourBody3),
      (l10n.tourTitle4, l10n.tourBody4),
    ];
    final first = _page == 0;
    final last = _page == _count - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: DefaultTextStyle.merge(
        // Kairo styles carry no color; the legacy default is secondary gray.
        style: TextStyle(color: colors.label),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spacing24,
                  AppSpacing.spacing8,
                  AppSpacing.spacing12,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Progress(page: _page, count: _count),
                    ),
                    AnimatedOpacity(
                      opacity: last ? 0 : 1,
                      duration: motion.duration(KairoSpring.smooth),
                      child: KairoButton(
                        label: l10n.skip,
                        variant: KairoButtonVariant.plain,
                        onPressed: last ? null : () => _goTo(_count - 1),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _count,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final (title, body) = steps[i];
                    return _Step(
                      vignette: TourVignette(step: i, active: i == _page),
                      title: title,
                      body: body,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spacing24,
                  AppSpacing.spacing16,
                  AppSpacing.spacing24,
                  AppSpacing.spacing16,
                ),
                child: Row(
                  children: [
                    // The back button makes room for itself and grows in
                    // from behind the main button.
                    AnimatedContainer(
                      duration: motion.duration(KairoSpring.smooth),
                      curve: motion.curve(KairoSpring.smooth),
                      width: first ? 0 : 52 + AppSpacing.spacing12,
                      height: 52,
                      alignment: Alignment.centerLeft,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        maxWidth: 52,
                        child: IgnorePointer(
                          ignoring: first,
                          child: AnimatedOpacity(
                            opacity: first ? 0 : 1,
                            duration: motion.duration(KairoSpring.smooth),
                            child: AnimatedScale(
                              scale: first ? 0.6 : 1,
                              duration: motion.duration(KairoSpring.snappy),
                              curve: motion.curve(KairoSpring.snappy),
                              child: _BackButton(onTap: () => _goTo(_page - 1)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: KairoButton(
                        label: last ? l10n.getStarted : l10n.next,
                        expand: true,
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One bar per step, filled up to the current one.
class _Progress extends StatelessWidget {
  const _Progress({required this.page, required this.count});

  final int page;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    return Semantics(
      label: context.l10n.tourStep(page + 1, count),
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  height: 4,
                  color: colors.fill,
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: motion.duration(KairoSpring.smooth),
                    curve: motion.curve(KairoSpring.smooth),
                    widthFactor: i <= page ? 1 : 0,
                    heightFactor: 1,
                    child: ColoredBox(color: colors.label),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.vignette,
    required this.title,
    required this.body,
  });

  final Widget vignette;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: vignette),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          // Same room for every step, so the copy doesn't jump.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 132),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.typography.largeTitle),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                Text(
                  body,
                  style: context.typography.bodyMultiline.copyWith(
                    color: colors.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: context.l10n.back,
      child: Material(
        color: colors.surface,
        shape: CircleBorder(side: BorderSide(color: colors.separator)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 52,
            child: Icon(
              CupertinoIcons.chevron_back,
              size: 20,
              color: colors.label,
            ),
          ),
        ),
      ),
    );
  }
}
