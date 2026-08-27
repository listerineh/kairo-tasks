import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

enum MascotState { normal, happy, sleeping, sad }

class MascotWidget extends StatefulWidget {
  const MascotWidget({
    required this.state,
    required this.streak,
    this.detailColor,
    super.key,
  });

  final MascotState state;
  final int streak;
  final Color? detailColor;

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.accent;
    final detailColor = widget.detailColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white);
    final assetPath = 'assets/mascot/mascot_${widget.state.name}.svg';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: FutureBuilder<String>(
            future: DefaultAssetBundle.of(context).loadString(assetPath),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(width: 120, height: 120);
              }

              final svgString = snapshot.data!.replaceAll(
                '#FFFFFF',
                '#${_hex(detailColor)}',
              );

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return _applyAnimation(child!, _controller.value);
                },
                child: SvgPicture.string(
                  svgString,
                  width: 120,
                  height: 120,
                  theme: SvgTheme(currentColor: color),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        _StreakChip(streak: widget.streak),
      ],
    );
  }

  Widget _applyAnimation(Widget child, double t) {
    switch (widget.state) {
      case MascotState.normal:
        final scale = 1.0 + math.sin(t * math.pi * 2) * 0.01;
        final y = math.sin(t * math.pi * 2) * 1.0;
        return Transform.translate(
          offset: Offset(0, y),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          ),
        );
      case MascotState.happy:
        final y = math.sin(t * math.pi * 4).abs() * 6.0;
        return Transform.translate(
          offset: Offset(0, -y),
          child: child,
        );
      case MascotState.sleeping:
        final scale = 1.0 + math.sin(t * math.pi * 2) * 0.01;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        );
      case MascotState.sad:
        final x = math.sin(t * math.pi * 2) * 2.0;
        return Transform.translate(
          offset: Offset(x, 0),
          child: child,
        );
    }
  }

  String _hex(Color c) {
    final value = c.toARGB32().toRadixString(16).padLeft(8, '0');
    return value.substring(2);
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing4,
      ),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 18,
            color: colors.accent,
          ),
          const SizedBox(width: AppSpacing.spacing4),
          Text(
            'Streak: $streak days',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
