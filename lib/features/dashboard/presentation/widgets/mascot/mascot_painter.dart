import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mascot_pose.dart';

/// Paints Kairo the cat for one [MascotPose]. No state, timers or rules
/// live here; the controller decides the pose.
///
/// A soft geometric loaf: superellipse body and head, rounded-triangle ears,
/// one tapered tail, capsule eyes. One tint fill plus one tonal shade, no
/// outlines (docs/redesign-plan.md §2.6). Drawn in a 100 x 100 box scaled to
/// the canvas.
class MascotPainter extends CustomPainter {
  MascotPainter({required this.pose, required this.tint, super.repaint});

  final MascotPose pose;
  final Color tint;

  /// Eyes, nose and mouth. A fixed near-black keeps them readable on both
  /// the light-mode and dark-mode tints.
  static const featureColor = Color(0xFF1C1C1E);
  static const _blushColor = Color(0xFFFF6B8A);

  Color get _shade {
    final hsl = HSLColor.fromColor(tint);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0, 1)).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 100;
    final fill = Paint()..color = tint;
    final shade = Paint()..color = _shade;

    canvas
      ..save()
      ..scale(unit)
      // Hop: the whole cat rises; squash scales from the ground line.
      ..translate(0, -pose.lift * 100)
      ..translate(50, 96)
      ..scale(1 + pose.bodySquash * 0.6, 1 - pose.bodySquash)
      ..translate(-50, -96);

    _tail(canvas, fill, shade);
    canvas.drawRSuperellipse(
      RSuperellipse.fromLTRBR(14, 52, 86, 96, const Radius.circular(24)),
      fill,
    );
    _paws(canvas, shade);

    // Head and face tilt together around the neck.
    canvas
      ..save()
      ..translate(50, 64)
      ..rotate(pose.headTilt)
      ..translate(-50, -64);
    _ears(canvas, fill, shade);
    canvas.drawRSuperellipse(
      RSuperellipse.fromLTRBR(20, 22, 80, 72, const Radius.circular(26)),
      fill,
    );
    _blush(canvas);
    _eyes(canvas);
    _noseAndMouth(canvas);
    canvas
      ..restore()
      ..restore();
  }

  void _tail(Canvas canvas, Paint fill, Paint shade) {
    canvas
      ..save()
      ..translate(80, 86)
      ..rotate(-pose.tailAngle)
      ..translate(-80, -86);
    final tail = Path()
      ..moveTo(78, 92)
      ..cubicTo(94, 92, 100, 80, 96, 66)
      ..cubicTo(95, 62, 90, 62, 90, 67)
      ..cubicTo(93, 78, 88, 84, 76, 82)
      ..close();
    canvas
      ..drawPath(tail, fill)
      ..drawCircle(const Offset(93, 65), 3.2, shade)
      ..restore();
  }

  void _paws(Canvas canvas, Paint shade) {
    for (final x in [36.0, 64.0]) {
      canvas.drawRSuperellipse(
        RSuperellipse.fromLTRBR(x - 7, 88, x + 7, 96, const Radius.circular(4)),
        shade,
      );
    }
  }

  void _ears(Canvas canvas, Paint fill, Paint shade) {
    for (final side in [-1.0, 1.0]) {
      final baseX = 50 + side * 18;
      canvas
        ..save()
        ..translate(baseX, 30 + pose.earDroop * 4)
        // Positive earAngle points ears forward; droop folds them outward.
        ..rotate(side * (pose.earDroop * 0.7 - pose.earAngle))
        ..translate(-baseX, -30);
      final outer = _roundedTriangle(
        Offset(baseX - side * 12, 32),
        Offset(baseX + side * 6, 4),
        Offset(baseX + side * 14, 30),
      );
      final inner = _roundedTriangle(
        Offset(baseX - side * 5, 29),
        Offset(baseX + side * 6, 12),
        Offset(baseX + side * 9, 28),
        radius: 2,
      );
      canvas
        ..drawPath(outer, fill)
        ..drawPath(inner, shade)
        ..restore();
    }
  }

  void _blush(Canvas canvas) {
    if (pose.blush <= 0.01) return;
    final paint = Paint()
      ..color = _blushColor.withValues(alpha: 0.45 * pose.blush.clamp(0, 1));
    for (final x in [31.0, 69.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 55), width: 9, height: 5),
        paint,
      );
    }
  }

  void _eyes(Canvas canvas) {
    final dark = Paint()..color = featureColor;
    final stroke = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final happy = pose.eyeCurve.clamp(0.0, 1.0);
    final sad = (-pose.eyeCurve).clamp(0.0, 1.0);
    final open = pose.eyeOpen.clamp(0.0, 1.0) * (1 - happy);

    for (final side in [-1.0, 1.0]) {
      final center = Offset(
        50 + side * 11 + pose.pupilX * 2.5,
        45 + pose.pupilY * 2.5,
      );
      final height = 12 * open;

      if (height > 1.6) {
        canvas
          ..save()
          ..translate(center.dx, center.dy)
          // Sad: inner corners rise.
          ..rotate(side * sad * 0.35)
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 7, height: height),
              const Radius.circular(3.5),
            ),
            dark,
          );
        if (height > 6) {
          canvas.drawCircle(
            const Offset(1.3, -2.2),
            1.3,
            Paint()..color = Colors.white.withValues(alpha: 0.9),
          );
        }
        canvas.restore();
      } else if (happy < 0.5) {
        // Closed: a soft downward curve.
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - 4, center.dy)
            ..quadraticBezierTo(
              center.dx,
              center.dy + 2.5,
              center.dx + 4,
              center.dy,
            ),
          stroke,
        );
      }

      if (happy > 0.01) {
        stroke.color = featureColor.withValues(alpha: happy);
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - 4.5, center.dy + 2)
            ..quadraticBezierTo(
              center.dx,
              center.dy - 4,
              center.dx + 4.5,
              center.dy + 2,
            ),
          stroke,
        );
        stroke.color = featureColor;
      }
    }
  }

  void _noseAndMouth(Canvas canvas) {
    canvas.drawPath(
      _roundedTriangle(
        const Offset(47.6, 52),
        const Offset(52.4, 52),
        const Offset(50, 55),
        radius: 0.9,
      ),
      Paint()..color = featureColor,
    );
    final curve = pose.mouthCurve.clamp(-1.0, 1.0);
    canvas.drawPath(
      Path()
        ..moveTo(45, 58 - curve)
        ..quadraticBezierTo(50, 58 + curve * 5, 55, 58 - curve),
      Paint()
        ..color = featureColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Triangle with each corner rounded by [radius].
  static Path _roundedTriangle(
    Offset a,
    Offset b,
    Offset c, {
    double radius = 4,
  }) {
    final points = [a, b, c];
    final path = Path();
    for (var i = 0; i < 3; i++) {
      final prev = points[(i + 2) % 3];
      final curr = points[i];
      final next = points[(i + 1) % 3];
      final toPrev = prev - curr;
      final toNext = next - curr;
      final r = math.min(
        radius,
        math.min(toPrev.distance, toNext.distance) / 2,
      );
      final start = curr + toPrev / toPrev.distance * r;
      final end = curr + toNext / toNext.distance * r;
      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, end.dx, end.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(MascotPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.tint != tint;
}
