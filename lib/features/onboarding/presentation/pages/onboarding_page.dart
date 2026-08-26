import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    _saveAndNavigate();
  }

  Future<void> _saveAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previous() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final slides = [
      _Slide(
        assetIcon: 'assets/icons/app_icon.svg',
        title: context.l10n.onboardingTitle1,
        body: context.l10n.onboardingBody1,
      ),
      _Slide(
        icon: Icons.check_circle,
        title: context.l10n.onboardingTitle2,
        body: context.l10n.onboardingBody2,
      ),
      _Slide(
        icon: Icons.people,
        title: context.l10n.onboardingTitle3,
        body: context.l10n.onboardingBody3,
      ),
      _Slide(
        icon: Icons.calendar_today,
        title: context.l10n.onboardingTitle4,
        body: context.l10n.onboardingBody4,
      ),
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing32,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.spacing64),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: slides.length,
                      itemBuilder: (context, index) => slides[index],
                    ),
                  ),
                  _buildDots(colors),
                  const SizedBox(height: AppSpacing.spacing24),
                  _buildBottomNav(),
                  const SizedBox(height: AppSpacing.spacing24),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                  ),
                  child: Text(context.l10n.skip),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots(AppColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
          ),
          width: isActive ? 10 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? colors.accent
                : colors.textMuted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        );
      }),
    );
  }

  Widget _buildBottomNav() {
    final colors = context.appColors;
    final isLast = _currentPage == 3;

    if (isLast) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _finish,
          style: FilledButton.styleFrom(
            minimumSize: const Size(
              double.infinity,
              AppSpacing.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            textStyle: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(context.l10n.getStarted),
        ),
      );
    }

    return Row(
      children: [
        TextButton(
          onPressed: _currentPage == 0 ? null : _previous,
          style: TextButton.styleFrom(
            foregroundColor: colors.textSecondary,
            textStyle: context.textTheme.bodyLarge,
          ),
          child: Text(context.l10n.back),
        ),
        const Spacer(),
        TextButton(
          onPressed: _next,
          style: TextButton.styleFrom(
            foregroundColor: colors.accent,
            textStyle: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(context.l10n.next),
        ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.title,
    required this.body,
    this.assetIcon,
    this.icon,
  });

  final String? assetIcon;
  final IconData? icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (assetIcon != null)
            SvgPicture.asset(
              assetIcon!,
              height: 72,
              fit: BoxFit.contain,
            )
          else
            Icon(icon, size: 80, color: colors.accent),
          const SizedBox(height: AppSpacing.spacing48),
          Text(
            title,
            style: context.textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            body,
            style: context.textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
