import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../dashboard/domain/mascot/mascot_mood.dart';
import '../../../dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import '../../../dashboard/presentation/widgets/mascot/mascot_behavior.dart';

/// Four slides, each with Kairo in a different mood; Saltar on top, pill
/// dots and one `ink` button that turns into "Empezar" on the last slide.
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

  void _next() {
    if (_page == _count - 1) {
      unawaited(_finish());
      return;
    }
    final motion = context.motion;
    unawaited(
      _pages.nextPage(
        duration: motion.duration(KairoSpring.smooth),
        curve: motion.curve(KairoSpring.smooth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final motion = context.motion;
    final slides = [
      (MascotMood.idle, null, l10n.onboardingTitle1, l10n.onboardingBody1),
      (MascotMood.happy, null, l10n.onboardingTitle2, l10n.onboardingBody2),
      (
        MascotMood.idle,
        MascotBehavior.look,
        l10n.onboardingTitle3,
        l10n.onboardingBody3,
      ),
      (MascotMood.focused, null, l10n.onboardingTitle4, l10n.onboardingBody4),
    ];
    final last = _page == _count - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: DefaultTextStyle.merge(
        // Kairo styles carry no color; the legacy default is secondary gray.
        style: TextStyle(color: colors.label),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                  child: AnimatedOpacity(
                    opacity: last ? 0 : 1,
                    duration: motion.duration(KairoSpring.smooth),
                    child: KairoButton(
                      label: l10n.skip,
                      variant: KairoButtonVariant.plain,
                      onPressed: last ? null : _finish,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _count,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final (mood, cue, title, body) = slides[i];
                    return _Slide(
                      mood: mood,
                      cue: cue,
                      active: i == _page,
                      title: title,
                      body: body,
                    );
                  },
                ),
              ),
              Semantics(
                label: '${_page + 1} / $_count',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _count; i++)
                      AnimatedContainer(
                        duration: motion.duration(KairoSpring.snappy),
                        curve: motion.curve(KairoSpring.snappy),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _page ? colors.label : colors.fill,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.spacing24,
                  AppSpacing.screenMargin,
                  AppSpacing.spacing16,
                ),
                child: KairoButton(
                  label: last ? l10n.getStarted : l10n.next,
                  expand: true,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.mood,
    required this.active,
    required this.title,
    required this.body,
    this.cue,
  });

  final MascotMood mood;
  final MascotBehavior? cue;
  final bool active;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing32),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.spacing24),
          // A cat thing plays each time the slide comes into view.
          KairoMascot(
            mood: mood,
            cue: cue,
            cueTrigger: active ? 1 : 0,
            size: 200,
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.typography.title1,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.typography.bodyMultiline.copyWith(
              color: colors.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
