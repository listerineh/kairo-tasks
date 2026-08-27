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
    final detailColor = context.appColors.surface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(120, 120),
          painter: MascotPainter(
            state: widget.state,
            animation: _controller,
            color: color,
            detailColor: detailColor,
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
    required this.detailColor,
  }) : super(repaint: animation);

  final MascotState state;
  final Animation<double> animation;
  final Color color;
  final Color detailColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final detailPaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = color.withAlpha(40)
      ..style = PaintingStyle.fill;

    final tailPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = size.center(Offset.zero);
    final baseY = center.dy + 10;

    canvas.save();
    _applyBodySway(canvas, center, baseY);

    _drawTail(canvas, size, tailPaint);
    _drawBody(canvas, center, baseY, fillPaint);
    _drawPaws(canvas, center, baseY, fillPaint);
    _drawHead(canvas, center, baseY, fillPaint);
    _drawEars(canvas, center, baseY, fillPaint, detailPaint);
    _drawFace(canvas, center, baseY, outlinePaint, detailPaint, blushPaint);

    if (state == MascotState.happy) {
      _drawSparkle(canvas, center, baseY, detailPaint);
    }

    canvas.restore();

    if (state == MascotState.sleeping) {
      _drawZzz(canvas, size, outlinePaint);
    }

    if (state == MascotState.sad) {
      _drawTears(canvas, center, baseY, fillPaint);
    }
  }

  void _applyBodySway(Canvas canvas, Offset center, double baseY) {
    switch (state) {
      case MascotState.normal:
      case MascotState.sad:
        final x = math.sin(animation.value * math.pi * 2) * 1.5;
        canvas.translate(x, 0);
      case MascotState.happy:
        final y = math.sin(animation.value * math.pi * 4).abs() * 4;
        canvas.translate(0, -y);
      case MascotState.sleeping:
        final s = 1.0 + math.sin(animation.value * math.pi * 2) * 0.015;
        canvas
          ..translate(center.dx, baseY)
          ..scale(s)
          ..translate(-center.dx, -baseY);
    }
  }

  void _drawTail(Canvas canvas, Size size, Paint tailPaint) {
    final anchor = Offset(size.width * 0.72, size.height * 0.76);
    final frequency = switch (state) {
      MascotState.normal => 1.0,
      MascotState.happy => 2.5,
      MascotState.sad => 0.5,
      MascotState.sleeping => 0.0,
    };
    final amplitude = switch (state) {
      MascotState.normal => 0.2,
      MascotState.happy => 0.4,
      MascotState.sad => 0.08,
      MascotState.sleeping => 0.0,
    };
    final angle = math.sin(animation.value * math.pi * 2 * frequency) * amplitude;

    final cp1 = anchor + Offset(
      math.cos(-0.35 + angle) * 14,
      math.sin(-0.35 + angle) * 14,
    );
    final mid = anchor + Offset(
      math.cos(-1.0 + angle) * 30,
      math.sin(-1.0 + angle) * 30,
    );
    final cp2 = mid + Offset(
      math.cos(-1.6 + angle) * 12,
      math.sin(-1.6 + angle) * 12,
    );
    final end = mid + Offset(
      math.cos(-2.2 + angle) * 18,
      math.sin(-2.2 + angle) * 18,
    );

    final path = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..quadraticBezierTo(cp1.dx, cp1.dy, mid.dx, mid.dy)
      ..quadraticBezierTo(cp2.dx, cp2.dy, end.dx, end.dy);

    canvas.drawPath(path, tailPaint);

    final tipPaint = Paint()
      ..color = tailPaint.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, 4.5, tipPaint);
  }

  void _drawBody(Canvas canvas, Offset center, double baseY, Paint paint) {
    final rect = Rect.fromCenter(
      center: Offset(center.dx, baseY + 16),
      width: 48,
      height: 52,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      paint,
    );
  }

  void _drawPaws(Canvas canvas, Offset center, double baseY, Paint paint) {
    final leftPaw = Rect.fromCenter(
      center: Offset(center.dx - 14, baseY + 40),
      width: 16,
      height: 12,
    );
    final rightPaw = Rect.fromCenter(
      center: Offset(center.dx + 14, baseY + 40),
      width: 16,
      height: 12,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(leftPaw, const Radius.circular(6)),
        paint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(rightPaw, const Radius.circular(6)),
        paint,
      );
  }

  void _drawHead(Canvas canvas, Offset center, double baseY, Paint paint) {
    canvas.drawCircle(
      Offset(center.dx, baseY - 28),
      34,
      paint,
    );
  }

  void _drawEars(
    Canvas canvas,
    Offset center,
    double baseY,
    Paint paint,
    Paint detailPaint,
  ) {
    final leftBase = Offset(center.dx - 22, baseY - 54);
    final rightBase = Offset(center.dx + 22, baseY - 54);

    if (state == MascotState.sad) {
      _drawDroopyEar(canvas, leftBase, -1, paint, detailPaint);
      _drawDroopyEar(canvas, rightBase, 1, paint, detailPaint);
    } else {
      _drawEar(canvas, leftBase, -1, paint, detailPaint);
      _drawEar(canvas, rightBase, 1, paint, detailPaint);
    }
  }

  void _drawEar(
    Canvas canvas,
    Offset base,
    double direction,
    Paint paint,
    Paint detailPaint,
  ) {
    final tip = base + Offset(direction * 14, -20);
    final left = base + Offset(-10 * direction, 2);
    final right = base + Offset(8 * direction, 0);

    final outer = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(right.dx, right.dy, base.dx, base.dy)
      ..close();
    canvas.drawPath(outer, paint);

    final innerTip = base + Offset(direction * 9, -12);
    final innerLeft = base + Offset(-5 * direction, -2);
    final innerRight = base + Offset(4 * direction, -3);

    final inner = Path()
      ..moveTo(base.dx, base.dy - 3)
      ..quadraticBezierTo(innerLeft.dx, innerLeft.dy, innerTip.dx, innerTip.dy)
      ..quadraticBezierTo(innerRight.dx, innerRight.dy, base.dx, base.dy - 3)
      ..close();
    canvas.drawPath(inner, detailPaint);
  }

  void _drawDroopyEar(
    Canvas canvas,
    Offset base,
    double direction,
    Paint paint,
    Paint detailPaint,
  ) {
    final tip = base + Offset(direction * 16, 14);
    final left = base + Offset(-9 * direction, 1);
    final right = base + Offset(7 * direction, 1);

    final outer = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(right.dx, right.dy, base.dx, base.dy)
      ..close();
    canvas.drawPath(outer, paint);

    final innerTip = base + Offset(direction * 10, 8);
    final innerLeft = base + Offset(-4 * direction, 2);
    final innerRight = base + Offset(3 * direction, 2);

    final inner = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(innerLeft.dx, innerLeft.dy, innerTip.dx, innerTip.dy)
      ..quadraticBezierTo(innerRight.dx, innerRight.dy, base.dx, base.dy)
      ..close();
    canvas.drawPath(inner, detailPaint);
  }

  void _drawFace(
    Canvas canvas,
    Offset center,
    double baseY,
    Paint outline,
    Paint detail,
    Paint blush,
  ) {
    final eyeY = baseY - 40;
    final leftEye = Offset(center.dx - 14, eyeY);
    final rightEye = Offset(center.dx + 14, eyeY);

    _drawBlush(canvas, leftEye, rightEye, blush);

    switch (state) {
      case MascotState.sleeping:
        _drawClosedEye(canvas, leftEye, outline);
        _drawClosedEye(canvas, rightEye, outline);
      case MascotState.happy:
        _drawHappyEye(canvas, leftEye, outline);
        _drawHappyEye(canvas, rightEye, outline);
      case MascotState.normal:
      case MascotState.sad:
        final blink = _isBlinking;
        if (blink) {
          _drawClosedEye(canvas, leftEye, outline);
          _drawClosedEye(canvas, rightEye, outline);
        } else {
          _drawOpenEye(canvas, leftEye, detail, outline);
          _drawOpenEye(canvas, rightEye, detail, outline);
        }
    }

    _drawNose(canvas, center, baseY, outline);
    _drawMouth(canvas, center, baseY, outline);
    _drawWhiskers(canvas, center, baseY, outline);
  }

  void _drawBlush(Canvas canvas, Offset leftEye, Offset rightEye, Paint paint) {
    final left = leftEye + const Offset(-6, 10);
    final right = rightEye + const Offset(6, 10);
    canvas
      ..drawCircle(left, 7, paint)
      ..drawCircle(right, 7, paint);
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

  void _drawOpenEye(Canvas canvas, Offset c, Paint detail, Paint pupil) {
    canvas
      ..drawCircle(c, 8, detail)
      ..drawCircle(c + const Offset(0, 2), 3.5, pupil);
  }

  void _drawClosedEye(Canvas canvas, Offset c, Paint paint) {
    canvas.drawLine(
      c + const Offset(-5, 0),
      c + const Offset(5, 0),
      paint,
    );
  }

  void _drawHappyEye(Canvas canvas, Offset c, Paint paint) {
    final rect = Rect.fromCenter(center: c, width: 14, height: 10);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  void _drawNose(Canvas canvas, Offset center, double baseY, Paint paint) {
    final nose = Path()
      ..moveTo(center.dx, baseY - 36)
      ..lineTo(center.dx - 4, baseY - 31)
      ..lineTo(center.dx + 4, baseY - 31)
      ..close();
    canvas.drawPath(nose, paint..style = PaintingStyle.fill);
  }

  void _drawMouth(Canvas canvas, Offset center, double baseY, Paint paint) {
    final path = Path();
    if (state == MascotState.sad) {
      path
        ..moveTo(center.dx - 5, baseY - 28)
        ..quadraticBezierTo(center.dx, baseY - 23, center.dx + 5, baseY - 28);
    } else {
      path
        ..moveTo(center.dx - 5, baseY - 28)
        ..quadraticBezierTo(center.dx - 3, baseY - 25, center.dx, baseY - 27)
        ..quadraticBezierTo(center.dx + 3, baseY - 25, center.dx + 5, baseY - 28);
    }
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawWhiskers(Canvas canvas, Offset center, double baseY, Paint paint) {
    final leftOrigin = Offset(center.dx - 18, baseY - 30);
    final rightOrigin = Offset(center.dx + 18, baseY - 30);
    final angles = [-0.05, 0.1, 0.25];
    final whiskerPaint = Paint()
      ..color = paint.color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final a in angles) {
      canvas
        ..drawLine(
          leftOrigin,
          leftOrigin + Offset(-math.cos(a) * 14, math.sin(a) * 6),
          whiskerPaint,
        )
        ..drawLine(
          rightOrigin,
          rightOrigin + Offset(math.cos(a) * 14, math.sin(a) * 6),
          whiskerPaint,
        );
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double baseY, Paint paint) {
    final position = Offset(center.dx + 28, baseY - 54);
    final t = (animation.value * math.pi * 4).abs();
    final scale = 0.8 + math.sin(t) * 0.2;
    canvas
      ..save()
      ..translate(position.dx, position.dy)
      ..scale(scale);
    final path = Path()
      ..moveTo(0, -6)
      ..lineTo(1.5, -1.5)
      ..lineTo(6, 0)
      ..lineTo(1.5, 1.5)
      ..lineTo(0, 6)
      ..lineTo(-1.5, 1.5)
      ..lineTo(-6, 0)
      ..lineTo(-1.5, -1.5)
      ..close();
    canvas
      ..drawPath(path, paint)
      ..restore();
  }

  void _drawTears(Canvas canvas, Offset center, double baseY, Paint paint) {
    final drop = animation.value;
    final tearY = baseY - 30;
    final leftTear = center + Offset(-12, tearY + (drop * 10));
    final rightTear = center + Offset(12, tearY + ((drop + 0.4) % 1.0 * 10));

    canvas
      ..drawCircle(leftTear, 2.5, paint)
      ..drawCircle(rightTear, 2.5, paint);
  }

  void _drawZzz(Canvas canvas, Size size, Paint paint) {
    for (var i = 0; i < 3; i++) {
      final offset = (animation.value + i * 0.25) % 1.0;
      final alpha = (offset < 0.2 ? offset / 0.2 : 1.0 - (offset - 0.2) / 0.8)
          .clamp(0.0, 1.0);
      final x = size.width * (0.55 + i * 0.08) + math.sin(offset * math.pi * 4) * 3;
      final y = size.height * 0.42 - offset * 28;

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
        oldDelegate.detailColor != detailColor ||
        oldDelegate.animation.value != animation.value;
  }
}
