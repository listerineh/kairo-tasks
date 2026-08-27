import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    final colorFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final colorStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final detailFill = Paint()
      ..color = detailColor
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = color.withAlpha(50)
      ..style = PaintingStyle.fill;

    final tailPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = size.center(Offset.zero);
    final baseY = center.dy + 12;

    canvas.save();
    _applyBodySway(canvas, center, baseY);

    _drawTail(canvas, size, baseY, tailPaint);
    _drawBody(canvas, center, baseY, detailFill, colorStroke);
    _drawPaws(canvas, center, baseY, detailFill, colorStroke);
    _drawEars(canvas, center, baseY, colorFill, detailFill);
    _drawFace(canvas, center, baseY, colorFill, colorStroke, detailFill, blushPaint);

    if (state == MascotState.sleeping) {
      _drawSnotBubble(canvas, center, baseY, detailFill, colorStroke);
    }

    if (state == MascotState.sad) {
      _drawTears(canvas, center, baseY, colorFill);
    }

    canvas.restore();
  }

  void _applyBodySway(Canvas canvas, Offset center, double baseY) {
    final t = animation.value;

    switch (state) {
      case MascotState.normal:
        final s = 1.0 + math.sin(t * math.pi * 2) * 0.015;
        final y = math.sin(t * math.pi * 2) * 1.0;
        canvas
          ..translate(center.dx, baseY)
          ..scale(s)
          ..translate(-center.dx, -baseY)
          ..translate(0, y);
      case MascotState.sad:
        final x = math.sin(t * math.pi * 2) * 2.0;
        canvas.translate(x, 0);
      case MascotState.happy:
        final y = math.sin(t * math.pi * 4).abs() * 6.0;
        canvas.translate(0, -y);
      case MascotState.sleeping:
        final s = 1.0 + math.sin(t * math.pi * 2) * 0.015;
        canvas
          ..translate(center.dx, baseY)
          ..scale(s)
          ..translate(-center.dx, -baseY);
    }
  }

  void _drawTail(
    Canvas canvas,
    Size size,
    double baseY,
    Paint tailPaint,
  ) {
    final anchor = Offset(size.width * 0.72, baseY + 24);
    final frequency = switch (state) {
      MascotState.normal => 1.0,
      MascotState.happy => 2.5,
      MascotState.sad => 0.6,
      MascotState.sleeping => 0.0,
    };
    final amplitude = switch (state) {
      MascotState.normal => 0.25,
      MascotState.happy => 0.45,
      MascotState.sad => 0.1,
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

  void _drawBody(
    Canvas canvas,
    Offset center,
    double baseY,
    Paint fill,
    Paint stroke,
  ) {
    final rect = Rect.fromCenter(
      center: Offset(center.dx, baseY + 4),
      width: 74,
      height: 86,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(37));

    canvas
      ..drawRRect(rrect, fill)
      ..drawRRect(rrect, stroke);
  }

  void _drawPaws(
    Canvas canvas,
    Offset center,
    double baseY,
    Paint fill,
    Paint stroke,
  ) {
    final leftPaw = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - 20, baseY + 36),
        width: 22,
        height: 16,
      ),
      const Radius.circular(8),
    );
    final rightPaw = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + 20, baseY + 36),
        width: 22,
        height: 16,
      ),
      const Radius.circular(8),
    );

    canvas
      ..drawRRect(leftPaw, fill)
      ..drawRRect(leftPaw, stroke)
      ..drawRRect(rightPaw, fill)
      ..drawRRect(rightPaw, stroke);
  }

  void _drawEars(
    Canvas canvas,
    Offset center,
    double baseY,
    Paint colorPaint,
    Paint detailPaint,
  ) {
    final leftBase = Offset(center.dx - 24, baseY - 32);
    final rightBase = Offset(center.dx + 24, baseY - 32);

    if (state == MascotState.sad) {
      _drawDroopyEar(canvas, leftBase, -1, colorPaint, detailPaint);
      _drawDroopyEar(canvas, rightBase, 1, colorPaint, detailPaint);
    } else {
      _drawEar(canvas, leftBase, -1, colorPaint, detailPaint);
      _drawEar(canvas, rightBase, 1, colorPaint, detailPaint);
    }
  }

  void _drawEar(
    Canvas canvas,
    Offset base,
    double direction,
    Paint paint,
    Paint detailPaint,
  ) {
    final tip = base + Offset(direction * 12, -20);
    final left = base + Offset(-10 * direction, 0);
    final right = base + Offset(8 * direction, 0);

    final outer = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(right.dx, right.dy, base.dx, base.dy)
      ..close();
    canvas.drawPath(outer, paint);

    final innerTip = base + Offset(direction * 8, -12);
    final innerLeft = base + Offset(-5 * direction, -2);
    final innerRight = base + Offset(4 * direction, -2);

    final inner = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(innerLeft.dx, innerLeft.dy, innerTip.dx, innerTip.dy)
      ..quadraticBezierTo(innerRight.dx, innerRight.dy, base.dx, base.dy)
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
    final tip = base + Offset(direction * 14, 16);
    final left = base + Offset(-9 * direction, 2);
    final right = base + Offset(7 * direction, 2);

    final outer = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(right.dx, right.dy, base.dx, base.dy)
      ..close();
    canvas.drawPath(outer, paint);

    final innerTip = base + Offset(direction * 9, 10);
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
    Paint colorFill,
    Paint colorStroke,
    Paint detailFill,
    Paint blush,
  ) {
    final eyeY = baseY - 20;
    final leftEye = Offset(center.dx - 16, eyeY);
    final rightEye = Offset(center.dx + 16, eyeY);

    _drawBlush(canvas, leftEye, rightEye, blush);

    switch (state) {
      case MascotState.sleeping:
        _drawClosedEye(canvas, leftEye, colorStroke);
        _drawClosedEye(canvas, rightEye, colorStroke);
      case MascotState.happy:
        _drawHappyEye(canvas, leftEye, colorStroke);
        _drawHappyEye(canvas, rightEye, colorStroke);
      case MascotState.normal:
      case MascotState.sad:
        final blink = _isBlinking;
        if (blink) {
          _drawClosedEye(canvas, leftEye, colorStroke);
          _drawClosedEye(canvas, rightEye, colorStroke);
        } else {
          _drawOpenEye(canvas, leftEye, colorFill, detailFill);
          _drawOpenEye(canvas, rightEye, colorFill, detailFill);
        }
    }

    _drawNose(canvas, center, baseY, colorFill);
    _drawMouth(canvas, center, baseY, colorStroke);
    _drawWhiskers(canvas, center, baseY, colorStroke);
  }

  void _drawBlush(Canvas canvas, Offset leftEye, Offset rightEye, Paint paint) {
    final left = leftEye + const Offset(-8, 8);
    final right = rightEye + const Offset(8, 8);
    canvas
      ..drawCircle(left, 6, paint)
      ..drawCircle(right, 6, paint);
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

  void _drawOpenEye(Canvas canvas, Offset c, Paint fill, Paint highlight) {
    canvas
      ..drawCircle(c, 7, fill)
      ..drawCircle(c + const Offset(2, -2), 2.2, highlight);
  }

  void _drawClosedEye(Canvas canvas, Offset c, Paint paint) {
    canvas.drawLine(
      c + const Offset(-5, 0),
      c + const Offset(5, 0),
      paint,
    );
  }

  void _drawHappyEye(Canvas canvas, Offset c, Paint paint) {
    final rect = Rect.fromCenter(center: c, width: 16, height: 12);
    canvas.drawArc(
      rect,
      0,
      math.pi,
      false,
      paint,
    );
  }

  void _drawNose(Canvas canvas, Offset center, double baseY, Paint paint) {
    final nose = Path()
      ..moveTo(center.dx, baseY - 18)
      ..lineTo(center.dx - 5, baseY - 13)
      ..lineTo(center.dx + 5, baseY - 13)
      ..close();
    canvas.drawPath(nose, paint);
  }

  void _drawMouth(Canvas canvas, Offset center, double baseY, Paint paint) {
    if (state == MascotState.happy) {
      final rect = Rect.fromCenter(
        center: Offset(center.dx, baseY - 10),
        width: 18,
        height: 12,
      );
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
      return;
    }

    final path = Path();
    if (state == MascotState.sad) {
      path
        ..moveTo(center.dx - 6, baseY - 7)
        ..quadraticBezierTo(center.dx, baseY - 12, center.dx + 6, baseY - 7);
    } else {
      path
        ..moveTo(center.dx - 5, baseY - 9)
        ..quadraticBezierTo(
          center.dx - 2,
          baseY - 6,
          center.dx,
          baseY - 8,
        )
        ..quadraticBezierTo(
          center.dx + 2,
          baseY - 6,
          center.dx + 5,
          baseY - 9,
        );
    }
    canvas.drawPath(path, paint);
  }

  void _drawWhiskers(Canvas canvas, Offset center, double baseY, Paint paint) {
    final leftOrigin = Offset(center.dx - 26, baseY - 14);
    final rightOrigin = Offset(center.dx + 26, baseY - 14);
    final angles = [-0.05, 0.1, 0.25];
    final whiskerPaint = Paint()
      ..color = paint.color
      ..strokeWidth = 1.2
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

  void _drawSnotBubble(
    Canvas canvas,
    Offset center,
    double baseY,
    Paint fill,
    Paint outline,
  ) {
    final t = animation.value;
    final scale = 1.0 + math.sin(t * math.pi * 2) * 0.25;
    final position = Offset(center.dx + 12, baseY - 18);
    final radius = 5.5 * scale;

    canvas
      ..drawCircle(position, radius, fill)
      ..drawCircle(
        position,
        radius,
        Paint()
          ..color = outline.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }

  void _drawTears(Canvas canvas, Offset center, double baseY, Paint paint) {
    final drop = animation.value;
    final leftTear = Offset(center.dx - 16, baseY - 12 + drop * 16);
    final rightTear =
        Offset(center.dx + 16, baseY - 12 + ((drop + 0.5) % 1.0) * 16);

    final tearPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas
      ..drawOval(
        Rect.fromCenter(center: leftTear, width: 4, height: 6),
        tearPaint,
      )
      ..drawOval(
        Rect.fromCenter(center: rightTear, width: 4, height: 6),
        tearPaint,
      );
  }

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.color != color ||
        oldDelegate.detailColor != detailColor ||
        oldDelegate.animation.value != animation.value;
  }
}
