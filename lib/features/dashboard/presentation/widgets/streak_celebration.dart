import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'mascot_widget.dart';

class StreakCelebration extends StatefulWidget {
  const StreakCelebration({
    required this.streak,
    this.onClose,
    super.key,
  });

  final int streak;
  final VoidCallback? onClose;

  @override
  State<StreakCelebration> createState() => _StreakCelebrationState();
}

class _StreakCelebrationState extends State<StreakCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
        side: BorderSide(color: colors.border, width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
          child: Stack(
            children: [
              Positioned.fill(
                child: _ConfettiField(
                  animation: _controller,
                  palette: [
                    colors.accent,
                    colors.high,
                    colors.surfaceSubtle,
                    colors.textMuted,
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.spacing24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: MascotWidget(
                        state: MascotState.happy,
                        streak: widget.streak,
                        showStreak: false,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing24),
                    Text(
                      context.l10n.notificationStreakEarnedTitle,
                      style: context.textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.spacing8),
                    Text(
                      context.l10n.notificationStreakEarnedBody(
                        widget.streak,
                      ),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.spacing20),
                    _StreakBadge(streak: widget.streak),
                    const SizedBox(height: AppSpacing.spacing24),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textMuted,
                      ),
                      tooltip: context.l10n.close,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceSubtle,
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

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 18,
            color: colors.accent,
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Text(
            context.l10n.streakDays(streak),
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiField extends StatelessWidget {
  const _ConfettiField({
    required this.animation,
    required this.palette,
  });

  final Animation<double> animation;
  final List<Color> palette;

  static const int _count = 18;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: List.generate(_count, (i) {
            final start = (i * 0.055).clamp(0.0, 0.5);
            final end = (start + 0.3 + (i % 5) * 0.04)
                .clamp(start + 0.1, 1.0);
            final particleAnimation = Tween<double>(
              begin: -0.1,
              end: 1.2,
            )
                .chain(
                  CurveTween(
                    curve: Interval(
                      start,
                      end,
                      curve: Curves.easeIn,
                    ),
                  ),
                )
                .animate(animation);
            final baseLeft = (i * 37.0) % width;
            final color = palette[i % palette.length];
            final size = 6.0 + (i % 3) * 2.0;

            return _ConfettiParticle(
              animation: particleAnimation,
              baseLeft: baseLeft,
              color: color,
              size: size,
              phase: i * 0.7,
              maxHeight: height,
            );
          }),
        );
      },
    );
  }
}

class _ConfettiParticle extends StatelessWidget {
  const _ConfettiParticle({
    required this.animation,
    required this.baseLeft,
    required this.color,
    required this.size,
    required this.phase,
    required this.maxHeight,
  });

  final Animation<double> animation;
  final double baseLeft;
  final Color color;
  final double size;
  final double phase;
  final double maxHeight;

  double _opacity(double progress) {
    if (progress < 0.05) return progress / 0.05;
    if (progress > 0.95) return (1 - progress) / 0.05;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value.clamp(0.0, 1.0);
        final top = progress * maxHeight;
        final left = baseLeft + math.sin(progress * math.pi * 3 + phase) * 12;
        final opacity = _opacity(progress);
        final angle = progress * math.pi * 2 + phase;

        return Positioned(
          top: top,
          left: left,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: angle,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(size / 4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

void showStreakCelebration(BuildContext context, int streak) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (dialogContext) => StreakCelebration(
      streak: streak,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}
