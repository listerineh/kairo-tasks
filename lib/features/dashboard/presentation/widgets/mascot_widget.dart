import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

enum MascotState { normal, happy, sleeping, sad }

class MascotWidget extends StatefulWidget {
  const MascotWidget({
    required this.state,
    required this.streak,
    super.key,
  });

  final MascotState state;
  final int streak;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(120, 120),
          painter: MascotPainter(
            state: widget.state,
            animation: _controller,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        _StreakChip(streak: widget.streak),
      ],
    );
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

class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.state,
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  final MascotState state;
  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final baseY = center.dy + 16;

    canvas.save();
    _applyBodySway(canvas, center, baseY);

    _drawTail(canvas, size, paint);
    _drawBody(canvas, center, baseY, paint);
    _drawHead(canvas, center, baseY, paint);
    _drawEars(canvas, center, baseY, paint);
    _drawFace(canvas, center, baseY, outline);

    canvas.restore();

    if (state == MascotState.sleeping) {
      _drawZzz(canvas, size, outline);
    }

    if (state == MascotState.sad) {
      _drawTears(canvas, center, baseY, outline);
    }
  }

  void _applyBodySway(Canvas canvas, Offset center, double baseY) {
    switch (state) {
      case MascotState.normal:
      case MascotState.sad:
        final x = math.sin(animation.value * math.pi * 2) * 1.5;
        canvas.translate(x, 0);
      case MascotState.happy:
        final y = math.sin(animation.value * math.pi * 4).abs() * 2;
        canvas.translate(0, -y);
      case MascotState.sleeping:
        final s = 1.0 + math.sin(animation.value * math.pi * 2) * 0.015;
        canvas
          ..translate(center.dx, baseY)
          ..scale(s)
          ..translate(-center.dx, -baseY);
    }
  }

  void _drawTail(Canvas canvas, Size size, Paint paint) {
    final anchor = Offset(size.width * 0.75, size.height * 0.72);
    final tailLen = size.width * 0.32;
    final frequency = switch (state) {
      MascotState.normal => 1.0,
      MascotState.happy => 2.5,
      MascotState.sad => 0.5,
      MascotState.sleeping => 0.0,
    };
    final amplitude = switch (state) {
      MascotState.normal => 0.18,
      MascotState.happy => 0.35,
      MascotState.sad => 0.08,
      MascotState.sleeping => 0.0,
    };
    final angle = math.sin(animation.value * math.pi * 2 * frequency) * amplitude;

    final cp1 = anchor + Offset(math.cos(-0.4 + angle) * tailLen * 0.5,
        math.sin(-0.4 + angle) * tailLen * 0.5);
    final end = anchor + Offset(math.cos(-0.8 + angle) * tailLen,
        math.sin(-0.8 + angle) * tailLen);

    final path = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..quadraticBezierTo(cp1.dx, cp1.dy, end.dx, end.dy);

    final tailPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, tailPaint);
  }

  void _drawBody(Canvas canvas, Offset center, double baseY, Paint paint) {
    final rect = Rect.fromCenter(
      center: Offset(center.dx, baseY + 6),
      width: 56,
      height: 62,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      paint,
    );
  }

  void _drawHead(Canvas canvas, Offset center, double baseY, Paint paint) {
    canvas.drawCircle(
      Offset(center.dx, baseY - 32),
      32,
      paint,
    );
  }

  void _drawEars(Canvas canvas, Offset center, double baseY, Paint paint) {
    final leftBase = Offset(center.dx - 20, baseY - 52);
    final rightBase = Offset(center.dx + 20, baseY - 52);

    if (state == MascotState.sad) {
      _drawDroopyEar(canvas, leftBase, -0.6, paint);
      _drawDroopyEar(canvas, rightBase, 0.6, paint);
    } else {
      _drawEar(canvas, leftBase, -0.3, paint);
      _drawEar(canvas, rightBase, 0.3, paint);
    }
  }

  void _drawEar(Canvas canvas, Offset base, double direction, Paint paint) {
    final tip = base + Offset(math.sin(-0.5 + direction) * 20,
        -math.cos(-0.5 + direction) * 20);
    final left = base + const Offset(-10, 6);
    final right = base + const Offset(10, 6);

    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawDroopyEar(Canvas canvas, Offset base, double direction, Paint paint) {
    final tip = base + Offset(math.sin(direction) * 18, math.cos(direction) * 12);
    final left = base + const Offset(-10, -4);
    final right = base + const Offset(10, -4);

    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawFace(Canvas canvas, Offset center, double baseY, Paint outline) {
    final eyeY = baseY - 38;
    final leftEye = Offset(center.dx - 10, eyeY);
    final rightEye = Offset(center.dx + 10, eyeY);
    final eyePaint = Paint()
      ..color = outline.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    switch (state) {
      case MascotState.sleeping:
        _drawClosedEye(canvas, leftEye, eyePaint);
        _drawClosedEye(canvas, rightEye, eyePaint);
      case MascotState.happy:
        _drawHappyEye(canvas, leftEye, eyePaint);
        _drawHappyEye(canvas, rightEye, eyePaint);
      case MascotState.normal:
      case MascotState.sad:
        final blink = _isBlinking;
        if (blink) {
          _drawClosedEye(canvas, leftEye, eyePaint);
          _drawClosedEye(canvas, rightEye, eyePaint);
        } else {
          _drawOpenEye(canvas, leftEye, eyePaint);
          _drawOpenEye(canvas, rightEye, eyePaint);
        }
    }
  }

  bool get _isBlinking {
    if (state == MascotState.sleeping) return true;
    final phase = animation.value;
    if (state == MascotState.normal) {
      return phase > 0.82 && phase < 0.87;
    }
    if (state == MascotState.sad) {
      return phase > 0.6 && phase < 0.65;
    }
    return false;
  }

  void _drawOpenEye(Canvas canvas, Offset center, Paint paint) {
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.2, fillPaint);
  }

  void _drawClosedEye(Canvas canvas, Offset center, Paint paint) {
    canvas.drawLine(
      center + const Offset(-4, 0),
      center + const Offset(4, 0),
      paint,
    );
  }

  void _drawHappyEye(Canvas canvas, Offset center, Paint paint) {
    final rect = Rect.fromCenter(center: center, width: 12, height: 8);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  void _drawTears(Canvas canvas, Offset center, double baseY, Paint paint) {
    final tearY = baseY - 28;
    final drop = animation.value;
    final leftTear = center + Offset(-10 + math.sin(drop * math.pi * 2) * 1, tearY + drop * 4);
    final tearPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(leftTear, 2.5, tearPaint);
  }

  void _drawZzz(Canvas canvas, Size size, Paint paint) {
    for (var i = 0; i < 3; i++) {
      final offset = (animation.value + i * 0.25) % 1.0;
      final alpha = (offset < 0.2 ? offset / 0.2 : 1.0 - (offset - 0.2) / 0.8)
          .clamp(0.0, 1.0);
      final x = size.width * (0.55 + i * 0.08) + math.sin(offset * math.pi * 4) * 3;
      final y = size.height * 0.45 - offset * 28;

      final zColor = paint.color.withAlpha((alpha * 170).toInt());
      final zPaint = Paint()
        ..color = zColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      _drawZ(canvas, Offset(x, y), 10 + i * 2, zPaint);
    }
  }

  void _drawZ(Canvas canvas, Offset center, double size, Paint paint) {
    final half = size / 2;
    final path = Path()
      ..moveTo(center.dx - half, center.dy - half)
      ..lineTo(center.dx + half, center.dy - half)
      ..lineTo(center.dx - half, center.dy + half)
      ..lineTo(center.dx + half, center.dy + half);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.color != color ||
        oldDelegate.animation.value != animation.value;
  }
}
