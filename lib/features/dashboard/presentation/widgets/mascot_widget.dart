import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

enum MascotState { normal, happy, sleeping, sad }

class MascotWidget extends StatefulWidget {
  const MascotWidget({
    required this.state,
    required this.streak,
    this.showStreak = true,
    super.key,
  });

  final MascotState state;
  final int streak;
  final bool showStreak;

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _meowController;
  late final math.Random _random;
  Timer? _meowTimer;
  String? _meowText;

  @override
  void initState() {
    super.initState();
    _random = math.Random();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _meowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _meowText = null);
        }
      });
    _scheduleMeow();
  }

  @override
  void dispose() {
    _meowTimer?.cancel();
    _meowController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleMeow() {
    _meowTimer?.cancel();
    if (widget.state != MascotState.normal &&
        widget.state != MascotState.happy &&
        widget.state != MascotState.sad &&
        widget.state != MascotState.sleeping) {
      _meowText = null;
      return;
    }
    final delay = Duration(seconds: 5 + _random.nextInt(26));
    _meowTimer = Timer(delay, () {
      if (!mounted) return;
      final aCount = 1 + _random.nextInt(5);
      setState(() => _meowText = 'M${'A' * aCount}U');
      _meowController.forward(from: 0);
      _scheduleMeow();
    });
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
          child: Stack(
            children: [
              CustomPaint(
                painter: MascotPainter(
                  state: widget.state,
                  animation: _controller,
                  color: color,
                  meowAnimation: _meowController,
                  isMeowing: _meowText != null,
                ),
                size: const Size(120, 120),
              ),
              if (_meowText != null)
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, 0.1),
                    child: _MeowParticle(
                      text: _meowText!,
                      animation: _meowController,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.showStreak) ...[
          const SizedBox(height: AppSpacing.spacing8),
          _StreakChip(streak: widget.streak),
        ],
      ],
    );
  }
}

class _MeowParticle extends StatelessWidget {
  const _MeowParticle({
    required this.text,
    required this.animation,
  });

  final String text;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final opacity = 1.0 - t;
        final scale = 0.5 + 1.5 * t;
        final dx = 55.0 * t;
        final dy = -50.0 * t;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.state,
    required this.animation,
    required this.color,
    this.meowAnimation,
    this.isMeowing = false,
  }) : super(
          repaint: Listenable.merge(
            [animation, if (meowAnimation != null) meowAnimation],
          ),
        );

  final MascotState state;
  final Animation<double> animation;
  final Color color;
  final Animation<double>? meowAnimation;
  final bool isMeowing;
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
    if (state == MascotState.normal ||
        state == MascotState.happy ||
        state == MascotState.sad ||
        state == MascotState.sleeping) {
      final (tailSpeed, tailAmp) = switch (state) {
        MascotState.sad => (math.pi, 0.04),
        MascotState.sleeping => (math.pi, 0.0),
        _ => (math.pi * 2, 0.06),
      };
      final tailAngle = switch (state) {
        MascotState.sleeping => -0.08 + 0.06 * math.sin(t * math.pi),
        _ => math.sin(t * tailSpeed) * tailAmp,
      };
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

    final earShift = switch (state) {
      MascotState.happy => math.sin(t * math.pi * 3) * 6,
      MascotState.normal => math.sin(t * math.pi * 2) * 6,
      MascotState.sad => math.sin(t * math.pi) * 4,
      MascotState.sleeping => math.sin(t * math.pi) * 2,
    };
    canvas..save()..translate(-earShift, 0);
    _drawLeftEar(canvas, fillPaint, strokePaint);
    canvas..restore()..save()..translate(earShift, 0);
    _drawRightEar(canvas, fillPaint, strokePaint);
    canvas.restore();
    _drawBody(canvas, fillPaint, strokePaint);
    _drawWhiskers(canvas, strokePaint);
    _drawFace(canvas, blackFill, strokePaint);
    _drawFrontPaws(canvas, strokePaint);

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

  void _drawLeftEar(Canvas canvas, Paint fill, Paint stroke) {
    final left = Path()
      ..moveTo(102, 145)
      ..cubicTo(75, 75, 92, 48, 132, 45)
      ..cubicTo(165, 43, 172, 85, 176, 115)
      ..close();
    canvas..drawPath(left, fill)..drawPath(left, stroke);
  }

  void _drawRightEar(Canvas canvas, Paint fill, Paint stroke) {
    final right = Path()
      ..moveTo(298, 145)
      ..cubicTo(325, 75, 308, 48, 268, 45)
      ..cubicTo(235, 43, 228, 85, 224, 115)
      ..close();
    canvas..drawPath(right, fill)..drawPath(right, stroke);
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
    // Whiskers intentionally left empty for now.
  }

  void _drawFace(Canvas canvas, Paint blackFill, Paint stroke) {
    final meowProgress =
        isMeowing && meowAnimation != null ? meowAnimation!.value : 0.0;
    switch (state) {
      case MascotState.normal:
        _drawOpenEyes(canvas, blackFill, stroke);
        if (meowProgress > 0) {
          _drawMeowingMouth(canvas, blackFill, meowProgress);
        } else {
          _drawMouth(canvas, stroke, isSmile: true, isTiny: true);
        }
      case MascotState.happy:
        _drawOpenEyes(canvas, blackFill, stroke);
        if (meowProgress > 0) {
          _drawMeowingMouth(canvas, blackFill, meowProgress);
        } else {
          _drawHappyMouth(canvas, blackFill);
        }
      case MascotState.sad:
        _drawOpenEyes(canvas, blackFill, stroke);
        if (meowProgress > 0) {
          _drawMeowingMouth(canvas, blackFill, meowProgress);
        } else {
          _drawMouth(canvas, stroke, isSmile: false, isTiny: false);
        }
        _drawTear(canvas);
      case MascotState.sleeping:
        _drawClosedEyes(canvas, stroke);
        if (meowProgress > 0) {
          _drawMeowingMouth(canvas, blackFill, meowProgress);
        } else {
          _drawMouth(canvas, stroke, isSmile: false, isTiny: true);
        }
        _drawSnotBubble(canvas, meowProgress);
    }
  }

  void _drawOpenEyes(Canvas canvas, Paint blackFill, Paint stroke) {
    final t = animation.value;
    final isBlinking = switch (state) {
      MascotState.normal => (t > 0.92 && t < 0.96),
      MascotState.happy => (t > 0.90 && t < 0.96),
      MascotState.sad => (t > 0.70 && t < 0.95),
      _ => false,
    };
    if (isBlinking) {
      _drawClosedEyes(canvas, stroke);
      return;
    }
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

  void _drawMouth(
    Canvas canvas,
    Paint stroke, {
    required bool isSmile,
    bool isTiny = false,
  }) {
    final controlY = isSmile
        ? (isTiny ? 230.0 : 235.0)
        : 215.0;
    final width = isTiny ? 8.0 : 10.0;
    final mouth = Path()
      ..moveTo(200 - width, 225)
      ..quadraticBezierTo(200, controlY, 200 + width, 225);
    canvas.drawPath(mouth, stroke);
  }

  void _drawMeowingMouth(
    Canvas canvas,
    Paint blackFill,
    double meowProgress,
  ) {
    final open = math.sin(meowProgress * math.pi).clamp(0.0, 1.0);
    final h = 4.0 + 10.0 * open;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(200, 228), width: 14, height: h),
      blackFill,
    );
  }

  void _drawHappyMouth(Canvas canvas, Paint blackFill) {
    final t = animation.value;
    final open = (0.5 + 0.5 * math.sin(t * math.pi * 4)).clamp(0.0, 1.0);
    final w = 22.0 + 6.0 * open;
    final h = 16.0 + 10.0 * open;
    const top = 222.0;
    final bottom = top + h;
    final mouth = Path()
      ..moveTo(200 - w, top)
      ..cubicTo(200 - w, bottom, 200 + w, bottom, 200 + w, top)
      ..close();
    canvas.drawPath(mouth, blackFill);
  }

  void _drawTear(Canvas canvas) {
    final t = animation.value;
    final y = 200.0 + t * 35.0;
    final opacity = (1.0 - t).clamp(0.0, 1.0);
    final tearPaint = Paint()
      ..color = _strokeColor.withValues(alpha: opacity);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(166, y), width: 6, height: 9),
      tearPaint,
    );
  }

  void _drawClosedEyes(Canvas canvas, Paint stroke) {
    canvas
      ..drawLine(const Offset(154, 180), const Offset(178, 180), stroke)
      ..drawLine(const Offset(222, 180), const Offset(246, 180), stroke);
  }

  void _drawSnotBubble(Canvas canvas, double meowProgress) {
    final t = animation.value;
    final baseRadius = 6.0 + 4.0 * math.sin(t * math.pi);
    final radius =
        meowProgress > 0 ? baseRadius * (1.0 - meowProgress) : baseRadius;
    final bubblePaint = Paint()
      ..color = _strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(235, 205), radius, bubblePaint);
  }

  void _drawFrontPaws(Canvas canvas, Paint stroke) {
    final left = Path()
      ..moveTo(145, 310)
      ..cubicTo(145, 360, 185, 360, 185, 310);
    final right = Path()
      ..moveTo(215, 310)
      ..cubicTo(215, 360, 255, 360, 255, 310);
    canvas..drawPath(left, stroke)..drawPath(right, stroke);
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
            context.l10n.streakDays(streak),
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
