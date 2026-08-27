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
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: MascotPainter(
              state: widget.state,
              animation: _controller,
              color: color,
            ),
            size: const Size(120, 120),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        _StreakChip(streak: widget.streak),
      ],
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
  static const double _viewBox = 400;
  static const Color _strokeColor = Color(0xFF141414);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final s = size.width / _viewBox;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = _strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final blackFill = Paint()
      ..color = _strokeColor
      ..style = PaintingStyle.fill;

    var bodyY = 0.0;
    var bodyX = 0.0;
    var bodyScale = 1.0;

    switch (state) {
      case MascotState.normal:
        bodyScale = 1.0 + math.sin(t * math.pi * 2) * 0.01;
      case MascotState.happy:
        bodyY = math.sin(t * math.pi * 4).abs() * 6.0;
      case MascotState.sleeping:
        bodyScale = 1.0 + math.sin(t * math.pi * 2) * 0.01;
      case MascotState.sad:
        bodyX = math.sin(t * math.pi * 2) * 2.0;
    }

    canvas
      ..save()
      ..translate(bodyX, -bodyY)
      ..scale(s * bodyScale);

    // Tail (drawn first so it appears behind the body).
    if (state == MascotState.normal) {
      final tailAngle = math.sin(t * math.pi * 2) * 0.15;
      canvas
        ..save()
        ..translate(-300, -310)
        ..rotate(tailAngle)
        ..translate(300, 310);
      _drawTail(canvas, fillPaint, strokePaint);
      canvas.restore();
    } else {
      _drawTail(canvas, fillPaint, strokePaint);
    }

    _drawBackLegs(canvas, fillPaint, strokePaint);
    _drawEars(canvas, fillPaint, strokePaint);
    _drawBody(canvas, fillPaint, strokePaint);
    _drawWhiskers(canvas, strokePaint);
    _drawFace(canvas, blackFill, strokePaint);
    _drawFrontPaws(canvas, fillPaint, strokePaint);

    canvas.restore();
  }

  void _drawTail(Canvas canvas, Paint fill, Paint stroke) {
    final tail = Path()
      ..moveTo(285, 310)
      ..cubicTo(315, 310, 345, 295, 340, 268)
      ..cubicTo(334, 250, 315, 260, 308, 278)
      ..cubicTo(300, 294, 290, 304, 278, 312)
      ..close();
    canvas..drawPath(tail, fill)..drawPath(tail, stroke);
  }

  void _drawBackLegs(Canvas canvas, Paint fill, Paint stroke) {
    final left = Path()
      ..moveTo(112, 312)
      ..cubicTo(72, 312, 68, 340, 116, 340)
      ..cubicTo(132, 340, 142, 334, 148, 324)
      ..close();
    final right = Path()
      ..moveTo(288, 312)
      ..cubicTo(328, 312, 332, 340, 284, 340)
      ..cubicTo(268, 340, 258, 334, 252, 324)
      ..close();
    canvas..drawPath(left, fill)..drawPath(left, stroke)..drawPath(right, fill)..drawPath(right, stroke);
  }

  void _drawEars(Canvas canvas, Paint fill, Paint stroke) {
    final left = Path()
      ..moveTo(102, 145)
      ..cubicTo(75, 75, 92, 48, 132, 45)
      ..cubicTo(165, 43, 172, 85, 176, 115)
      ..close();
    final right = Path()
      ..moveTo(298, 145)
      ..cubicTo(325, 75, 308, 48, 268, 45)
      ..cubicTo(235, 43, 228, 85, 224, 115)
      ..close();
    canvas..drawPath(left, fill)..drawPath(left, stroke)..drawPath(right, fill)..drawPath(right, stroke);
  }

  void _drawBody(Canvas canvas, Paint fill, Paint stroke) {
    final body = Path()
      ..moveTo(152, 86)
      ..cubicTo(170, 80, 186, 66, 187, 75)
      ..cubicTo(204, 62, 214, 64, 216, 72)
      ..cubicTo(224, 76, 238, 80, 248, 86)
      ..cubicTo(290, 102, 336, 128, 340, 182)
      ..cubicTo(345, 230, 318, 258, 296, 264)
      ..cubicTo(305, 280, 308, 310, 295, 338)
      ..cubicTo(285, 352, 260, 354, 245, 348)
      ..lineTo(155, 348)
      ..cubicTo(140, 354, 115, 352, 105, 338)
      ..cubicTo(92, 310, 95, 280, 104, 264)
      ..cubicTo(82, 258, 55, 230, 60, 182)
      ..cubicTo(64, 128, 110, 102, 152, 86)
      ..close();
    canvas..drawPath(body, fill)..drawPath(body, stroke);
  }

  void _drawWhiskers(Canvas canvas, Paint stroke) {
    final left = Path()
      ..moveTo(88, 244)
      ..cubicTo(98, 254, 110, 258, 122, 260);
    final right = Path()
      ..moveTo(312, 244)
      ..cubicTo(302, 254, 290, 258, 278, 260);
    canvas..drawPath(left, stroke)..drawPath(right, stroke);
  }

  void _drawFace(Canvas canvas, Paint blackFill, Paint stroke) {
    switch (state) {
      case MascotState.normal:
        _drawOpenEyes(canvas, blackFill);
        _drawNose(canvas, blackFill);
      case MascotState.happy:
        _drawOpenEyes(canvas, blackFill);
        _drawMouth(canvas, stroke, isSmile: true);
      case MascotState.sad:
        _drawOpenEyes(canvas, blackFill);
        _drawMouth(canvas, stroke, isSmile: false);
        _drawTear(canvas, blackFill);
      case MascotState.sleeping:
        _drawClosedEyes(canvas, stroke);
        _drawSnotBubble(canvas);
    }
  }

  void _drawOpenEyes(Canvas canvas, Paint blackFill) {
    canvas
      ..drawOval(
        Rect.fromCenter(center: const Offset(166, 180), width: 24, height: 28),
        blackFill,
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(234, 180), width: 24, height: 28),
        blackFill,
      );
  }

  void _drawNose(Canvas canvas, Paint blackFill) {
    final nose = Path()
      ..moveTo(200, 205)
      ..lineTo(195, 215)
      ..lineTo(205, 215)
      ..close();
    canvas.drawPath(nose, blackFill);
  }

  void _drawMouth(Canvas canvas, Paint stroke, {required bool isSmile}) {
    final mouth = Path()
      ..moveTo(190, 225)
      ..quadraticBezierTo(200, isSmile ? 215 : 235, 210, 225);
    canvas.drawPath(mouth, stroke);
  }

  void _drawTear(Canvas canvas, Paint blackFill) {
    final t = animation.value;
    final y = 200 + (t * 25) % 25;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(166, y), width: 6, height: 9),
      blackFill,
    );
  }

  void _drawClosedEyes(Canvas canvas, Paint stroke) {
    canvas
      ..drawLine(const Offset(154, 180), const Offset(178, 180), stroke)
      ..drawLine(const Offset(222, 180), const Offset(246, 180), stroke);
  }

  void _drawSnotBubble(Canvas canvas) {
    final t = animation.value;
    final radius = 6 + 2 * math.sin(t * math.pi * 2);
    final bubblePaint = Paint()
      ..color = _strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(235, 205), radius, bubblePaint);
  }

  void _drawFrontPaws(Canvas canvas, Paint fill, Paint stroke) {
    final left = Path()
      ..moveTo(148, 290)
      ..cubicTo(146, 322, 148, 354, 172, 354)
      ..cubicTo(188, 354, 192, 334, 192, 292)
      ..close();
    final right = Path()
      ..moveTo(252, 290)
      ..cubicTo(254, 322, 252, 354, 228, 354)
      ..cubicTo(212, 354, 208, 334, 208, 292)
      ..close();
    canvas..drawPath(left, fill)..drawPath(left, stroke)..drawPath(right, fill)..drawPath(right, stroke);
  }

  @override
  bool shouldRepaint(covariant MascotPainter old) => true;
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
