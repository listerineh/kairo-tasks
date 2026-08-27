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
    final center = size.center(Offset.zero);
    final baseY = center.dy + 10;
    final headCenter = Offset(center.dx, baseY - 16);
    const headRadius = 34.0;

    final colorFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final colorStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinColorStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final detailFill = Paint()
      ..color = detailColor
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = color.withAlpha(40)
      ..style = PaintingStyle.fill;

    final tailPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    _applyBodySway(canvas, center, baseY);

    _drawTail(canvas, size, baseY, colorFill, tailPaint);
    _drawBody(canvas, center, baseY, detailFill, colorStroke);
    _drawPaws(canvas, center, baseY, detailFill, colorStroke);
    _drawEars(canvas, headCenter, colorFill, detailFill);
    _drawHead(canvas, headCenter, headRadius, detailFill, colorStroke);
    _drawBlush(canvas, headCenter, blushPaint);
    _drawFace(
      canvas,
      headCenter,
      colorFill,
      thinColorStroke,
      detailFill,
    );

    if (state == MascotState.sleeping) {
      _drawSnotBubble(canvas, headCenter, detailFill, thinColorStroke);
    }

    if (state == MascotState.sad) {
      _drawTears(canvas, headCenter, colorFill);
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
    Paint fill,
    Paint paint,
  ) {
    final anchor = Offset(size.width * 0.78, baseY + 10);
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
      math.cos(-0.45 + angle) * 12,
      math.sin(-0.45 + angle) * 12,
    );
    final mid = anchor + Offset(
      math.cos(-1.1 + angle) * 26,
      math.sin(-1.1 + angle) * 26,
    );
    final cp2 = mid + Offset(
      math.cos(-1.7 + angle) * 10,
      math.sin(-1.7 + angle) * 10,
    );
    final end = mid + Offset(
      math.cos(-2.4 + angle) * 14,
      math.sin(-2.4 + angle) * 14,
    );

    final path = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..quadraticBezierTo(cp1.dx, cp1.dy, mid.dx, mid.dy)
      ..quadraticBezierTo(cp2.dx, cp2.dy, end.dx, end.dy);

    canvas
      ..drawPath(path, paint)
      ..drawCircle(end, 3.5, fill);
  }

  void _drawBody(
    Canvas canvas,
    Offset center,
    double baseY,
    Paint fill,
    Paint stroke,
  ) {
    final rect = Rect.fromCenter(
      center: Offset(center.dx, baseY + 14),
      width: 54,
      height: 34,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));

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
    final leftPaw = Offset(center.dx - 16, baseY + 24);
    final rightPaw = Offset(center.dx + 16, baseY + 24);

    canvas
      ..drawCircle(leftPaw, 6, fill)
      ..drawCircle(leftPaw, 6, stroke)
      ..drawCircle(rightPaw, 6, fill)
      ..drawCircle(rightPaw, 6, stroke);
  }

  void _drawEars(
    Canvas canvas,
    Offset headCenter,
    Paint colorFill,
    Paint detailFill,
  ) {
    final droop = state == MascotState.sad;
    final earY = headCenter.dy - (droop ? 18 : 32);

    final leftOuter = Offset(headCenter.dx - 24, earY);
    final rightOuter = Offset(headCenter.dx + 24, earY);
    final leftInner = leftOuter + const Offset(0, 3);
    final rightInner = rightOuter + const Offset(0, 3);

    canvas
      ..drawOval(
        Rect.fromCenter(center: leftOuter, width: 28, height: 24),
        colorFill,
      )
      ..drawOval(
        Rect.fromCenter(center: rightOuter, width: 28, height: 24),
        colorFill,
      )
      ..drawOval(
        Rect.fromCenter(center: leftInner, width: 15, height: 13),
        detailFill,
      )
      ..drawOval(
        Rect.fromCenter(center: rightInner, width: 15, height: 13),
        detailFill,
      );
  }

  void _drawHead(
    Canvas canvas,
    Offset headCenter,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    canvas
      ..drawCircle(headCenter, radius, fill)
      ..drawCircle(headCenter, radius, stroke);
  }

  void _drawBlush(Canvas canvas, Offset headCenter, Paint paint) {
    final left = Offset(headCenter.dx - 20, headCenter.dy + 6);
    final right = Offset(headCenter.dx + 20, headCenter.dy + 6);

    canvas
      ..drawCircle(left, 7, paint)
      ..drawCircle(right, 7, paint);
  }

  void _drawFace(
    Canvas canvas,
    Offset headCenter,
    Paint colorFill,
    Paint thinStroke,
    Paint detailFill,
  ) {
    final eyeY = headCenter.dy - 4;
    final leftEye = Offset(headCenter.dx - 13, eyeY);
    final rightEye = Offset(headCenter.dx + 13, eyeY);

    switch (state) {
      case MascotState.sleeping:
        _drawClosedEye(canvas, leftEye, thinStroke);
        _drawClosedEye(canvas, rightEye, thinStroke);
      case MascotState.happy:
        _drawHappyEye(canvas, leftEye, thinStroke);
        _drawHappyEye(canvas, rightEye, thinStroke);
      case MascotState.normal:
      case MascotState.sad:
        final blink = _isBlinking;
        if (blink) {
          _drawClosedEye(canvas, leftEye, thinStroke);
          _drawClosedEye(canvas, rightEye, thinStroke);
        } else {
          _drawOpenEye(canvas, leftEye, colorFill, detailFill);
          _drawOpenEye(canvas, rightEye, colorFill, detailFill);
        }
    }

    _drawNose(canvas, headCenter, colorFill);
    _drawMouth(canvas, headCenter, thinStroke, colorFill);
    _drawWhiskers(canvas, headCenter, thinStroke);
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
      ..drawCircle(c, 4.5, fill)
      ..drawCircle(c + const Offset(1.5, -1.5), 1.2, highlight);
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
      0,
      math.pi,
      false,
      paint,
    );
  }

  void _drawNose(Canvas canvas, Offset headCenter, Paint paint) {
    final nose = Path()
      ..moveTo(headCenter.dx, headCenter.dy + 5)
      ..lineTo(headCenter.dx - 4, headCenter.dy + 10)
      ..lineTo(headCenter.dx + 4, headCenter.dy + 10)
      ..close();
    canvas.drawPath(nose, paint);
  }

  void _drawMouth(
    Canvas canvas,
    Offset headCenter,
    Paint stroke,
    Paint fill,
  ) {
    final center = Offset(headCenter.dx, headCenter.dy + 16);

    switch (state) {
      case MascotState.happy:
        final rect = Rect.fromCenter(center: center, width: 12, height: 9);
        canvas.drawArc(rect, math.pi, math.pi, false, stroke);
      case MascotState.sad:
        final rect = Rect.fromCenter(center: center, width: 10, height: 7);
        canvas.drawArc(rect, 0, math.pi, false, stroke);
      case MascotState.normal:
      case MascotState.sleeping:
        canvas.drawCircle(center, 2.2, fill);
    }
  }

  void _drawWhiskers(Canvas canvas, Offset headCenter, Paint paint) {
    final leftOrigin = Offset(headCenter.dx - 22, headCenter.dy + 6);
    final rightOrigin = Offset(headCenter.dx + 22, headCenter.dy + 6);
    final angles = [-0.08, 0.08, 0.24];

    for (final a in angles) {
      canvas
        ..drawLine(
          leftOrigin,
          leftOrigin + Offset(-math.cos(a) * 12, math.sin(a) * 5),
          paint,
        )
        ..drawLine(
          rightOrigin,
          rightOrigin + Offset(math.cos(a) * 12, math.sin(a) * 5),
          paint,
        );
    }
  }

  void _drawSnotBubble(
    Canvas canvas,
    Offset headCenter,
    Paint fill,
    Paint outline,
  ) {
    final t = animation.value;
    final scale = 1.0 + math.sin(t * math.pi * 2) * 0.28;
    final position = Offset(headCenter.dx + 12, headCenter.dy + 4);
    final radius = 4.5 * scale;

    canvas
      ..drawCircle(position, radius, fill)
      ..drawCircle(position, radius, outline);
  }

  void _drawTears(Canvas canvas, Offset headCenter, Paint paint) {
    final drop = animation.value;
    final eyeY = headCenter.dy - 4;
    final leftTear = Offset(headCenter.dx - 13, eyeY + 10 + drop * 12);
    final rightTear = Offset(
      headCenter.dx + 13,
      eyeY + 10 + ((drop + 0.5) % 1.0) * 12,
    );

    canvas
      ..drawOval(
        Rect.fromCenter(center: leftTear, width: 3.5, height: 5),
        paint,
      )
      ..drawOval(
        Rect.fromCenter(center: rightTear, width: 3.5, height: 5),
        paint,
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
