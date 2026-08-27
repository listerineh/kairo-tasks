import 'dart:math' as math;

import 'package:flutter/material.dart';

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
      duration: const Duration(seconds: 2, milliseconds: 500),
      vsync: this,
    )
      ..addStatusListener(_onStatus)
      ..forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onClose?.call();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black54,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(180, 180),
                      painter: MascotPainter(
                        state: MascotState.happy,
                        animation: _controller,
                        color: context.appColors.accent,
                        detailColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '+1 streak day!',
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${widget.streak} consecutive days',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(20, (i) {
                final start = (i * 0.03).clamp(0.0, 0.6);
                final end = (start + 0.25 + (i % 4) * 0.05)
                    .clamp(start + 0.05, 1.0);
                final animation = Tween<double>(
                  begin: -0.1,
                  end: 1.2,
                )
                    .chain(
                      CurveTween(
                        curve: Interval(
                          start,
                          end,
                          curve: Curves.linear,
                        ),
                      ),
                    )
                    .animate(_controller);
                final color = colors[i % colors.length].withAlpha(150);
                final left = ((i * 0.13 + (i % 5) * 0.07) % 1.0) * size.width;

                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final top = animation.value * size.height;
                    return Positioned(
                      top: top,
                      left: left + math.sin(animation.value * math.pi * 3) * 20,
                      child: child!,
                    );
                  },
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

void showStreakCelebration(BuildContext context, int streak) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) => StreakCelebration(
      streak: streak,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}
