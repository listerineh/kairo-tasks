import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mascot_pose.dart';

/// Paints Kairo, the fluffy calico, for one [MascotPose]. No state, timers
/// or rules live here; the controller decides the pose.
///
/// White fur with orange and black patches, a scalloped chest ruff, cheek
/// and ear tufts, green-yellow eyes and a thick orange tail with a black tip
/// (docs/design.md § Kairo, the cat). A thin white line along the tail shows
/// the day's [progress]. Drawn in a 160 x 160 box scaled to the canvas; the
/// shapes match the prototype's `Cat` component.
class MascotPainter extends CustomPainter {
  MascotPainter({required this.pose, this.progress = 0, super.repaint});

  final MascotPose pose;

  /// 0..1 of the day done; lights the tail from its base.
  final double progress;

  static const fur = Color(0xFFFBF8F3);
  static const ruff = Color(0xFFFFFFFF);
  static const orange = Color(0xFFE0893F);
  static const black = Color(0xFF24272B);
  static const outline = Color(0xFFD9CFC2);
  static const iris = Color(0xFFA9C95B);
  static const feature = Color(0xFF1B1D20);
  static const pink = Color(0xFFE58F86);
  static const innerEar = Color(0xFFE9AFA3);
  static const blushColor = Color(0xFFEE9C8F);
  static const whisker = Color(0xFF9A9186);
  static const mouthInside = Color(0xFF5B2F2C);

  static const _box = 160.0;
  static const _deg = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / _box;
    final stand = pose.stand.clamp(0.0, 1.1);
    final rise = 15 * stand;
    final lean = -9 * pose.lean;

    canvas
      ..save()
      ..scale(unit);

    _shadow(canvas, rise);

    canvas
      ..save()
      ..translate(0, -pose.lift * _box);

    _tail(canvas);
    if (stand > 0.05) _legs(canvas, rise);

    // Body: rises when standing, leans when stretching, squashes from the
    // ground line when breathing or landing.
    final squash = pose.bodySquash;
    canvas
      ..save()
      ..translate(0, -rise)
      ..translate(80, 150)
      ..rotate(lean * _deg)
      ..scale(1 + squash * 0.45, 1 - squash)
      ..translate(-80, -150);
    _body(canvas);
    canvas
      ..restore()
      ..save()
      ..translate(0, -rise + pose.headY * _box + lean * 0.6)
      ..translate(80, 84)
      ..rotate(pose.headTilt + (pose.earDroop * 3 + lean * 0.5) * _deg)
      ..translate(-80, -84);
    _head(canvas);
    canvas.restore();

    _paws(canvas, rise);
    canvas.restore();

    if (pose.eyeCurve > 0.6) _sparkles(canvas, (pose.eyeCurve - 0.6) / 0.4);
    canvas.restore();
  }

  void _shadow(Canvas canvas, double rise) {
    final rx = 42 - pose.lift * _box * 0.12 - rise * 0.2;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(80, 152), width: rx * 2, height: 8),
      Paint()
        ..color = feature.withValues(
          alpha: (0.1 - pose.lift * 0.1).clamp(0.03, 0.1),
        ),
    );
  }

  void _tail(Canvas canvas) {
    const anchor = Offset(118, 138);
    const radius = 34.0;
    final a = 0.35 + pose.tailAngle * 1.2;
    final tip = anchor + Offset(math.cos(a), -math.sin(a)) * radius;
    final c2 =
        anchor + Offset(math.cos(a - 0.5), -math.sin(a - 0.5)) * radius * 0.9;
    final path = Path()
      ..moveTo(106, 142)
      ..cubicTo(136, 150, c2.dx, c2.dy, tip.dx, tip.dy);

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawPath(path, stroke(outline, 17))
      ..drawPath(path, stroke(orange, 14));
    final metric = path.computeMetrics().first;
    final length = metric.length;
    canvas.drawPath(
      metric.extractPath(length * 0.74, length),
      stroke(black, 14),
    );
    final lit = progress.clamp(0.0, 1.0);
    if (lit > 0) {
      canvas.drawPath(
        metric.extractPath(0, length * lit),
        stroke(Colors.white.withValues(alpha: 0.95), 2.6),
      );
    }
  }

  void _legs(Canvas canvas, double rise) {
    final top = 150 - rise - 8;
    for (final (x, color) in const [
      (50.0, orange),
      (64.0, fur),
      (83.0, fur),
      (97.0, fur),
    ]) {
      final leg = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, 13, rise + 8),
        const Radius.circular(6),
      );
      canvas
        ..drawRRect(leg, Paint()..color = color)
        ..drawRRect(leg, _outline(1.2));
    }
  }

  void _body(Canvas canvas) {
    final body = _bodyPath();
    canvas
      ..drawPath(body, Paint()..color = fur)
      ..save()
      ..clipPath(body)
      ..drawPath(
        Path()
          ..moveTo(38, 96)
          ..cubicTo(52, 92, 60, 104, 58, 118)
          ..cubicTo(57, 130, 50, 140, 38, 142)
          ..close(),
        Paint()..color = orange,
      )
      ..drawPath(
        Path()
          ..moveTo(100, 116)
          ..cubicTo(110, 110, 124, 114, 124, 128)
          ..cubicTo(124, 140, 112, 148, 100, 144)
          ..cubicTo(94, 136, 94, 122, 100, 116)
          ..close(),
        Paint()..color = black,
      )
      ..drawPath(
        Path()
          ..moveTo(98, 84)
          ..cubicTo(106, 80, 116, 86, 116, 94)
          ..cubicTo(112, 100, 102, 100, 98, 94)
          ..close(),
        Paint()..color = orange,
      )
      ..drawPath(
        Path()
          ..moveTo(60, 136)
          ..cubicTo(64, 132, 72, 134, 72, 140)
          ..cubicTo(70, 146, 62, 146, 60, 136)
          ..close(),
        Paint()..color = black,
      )
      ..restore()
      ..drawPath(body, _outline(1.4))
      // Scalloped chest ruff and a few fur strokes.
      ..drawPath(
        Path()
          ..moveTo(62, 82)
          ..quadraticBezierTo(60, 96, 66, 104)
          ..quadraticBezierTo(64, 110, 71, 112)
          ..quadraticBezierTo(72, 118, 80, 120)
          ..quadraticBezierTo(88, 118, 89, 112)
          ..quadraticBezierTo(96, 110, 94, 104)
          ..quadraticBezierTo(100, 96, 98, 82)
          ..close(),
        Paint()..color = ruff,
      );
    final strokes = _outline(1.1);
    for (final (from, to) in const [
      (Offset(66, 100), Offset(63, 105)),
      (Offset(74, 110), Offset(72, 115)),
      (Offset(86, 110), Offset(88, 115)),
      (Offset(94, 100), Offset(97, 105)),
    ]) {
      canvas.drawLine(from, to, strokes);
    }

    final paw = Rect.fromCenter(
      center: const Offset(92, 147),
      width: 17,
      height: 11,
    );
    canvas
      ..drawOval(paw, Paint()..color = fur)
      ..drawOval(paw, _outline(1.2));
  }

  void _head(Canvas canvas) {
    final earDeg = pose.earAngle / _deg;
    _ear(
      canvas,
      pivot: const Offset(62, 46),
      angle: (-earDeg * 0.9 - pose.earDroop * 16) * _deg,
      color: black,
      outer: const [Offset(50, 56), Offset(55, 22), Offset(76, 41)],
      inner: const [Offset(56, 46), Offset(58, 31), Offset(68, 41)],
      tufts: const [
        (Offset(58, 44), Offset(56, 37)),
        (Offset(62, 45), Offset(62, 38)),
      ],
    );
    _ear(
      canvas,
      pivot: const Offset(98, 46),
      angle: (earDeg * 0.9 + pose.earDroop * 16) * _deg,
      color: orange,
      outer: const [Offset(110, 56), Offset(105, 22), Offset(84, 41)],
      inner: const [Offset(104, 46), Offset(102, 31), Offset(92, 41)],
      tufts: const [
        (Offset(102, 44), Offset(104, 37)),
        (Offset(98, 45), Offset(98, 38)),
      ],
    );

    final head = _headPath();
    canvas
      ..drawPath(head, Paint()..color = fur)
      ..save()
      ..clipPath(head)
      ..drawPath(
        Path()
          ..moveTo(40, 30)
          ..cubicTo(58, 28, 72, 38, 72, 52)
          ..cubicTo(70, 62, 58, 66, 44, 64)
          ..close(),
        Paint()..color = black,
      )
      ..drawPath(
        Path()
          ..moveTo(120, 30)
          ..cubicTo(102, 28, 88, 38, 88, 52)
          ..cubicTo(90, 62, 102, 66, 116, 64)
          ..close(),
        Paint()..color = orange,
      )
      ..drawPath(
        Path()
          ..moveTo(108, 70)
          ..cubicTo(114, 68, 120, 72, 118, 80)
          ..cubicTo(112, 82, 106, 78, 108, 70)
          ..close(),
        Paint()..color = orange,
      )
      ..restore()
      ..drawPath(head, _outline(1.4));

    _eyes(canvas);

    if (pose.blush > 0.01) {
      final blush = Paint()
        ..color = blushColor.withValues(alpha: pose.blush.clamp(0, 1) * 0.6);
      canvas
        ..drawOval(
          Rect.fromCenter(center: const Offset(58, 76), width: 11, height: 5),
          blush,
        )
        ..drawOval(
          Rect.fromCenter(center: const Offset(102, 76), width: 11, height: 5),
          blush,
        );
    }

    canvas.drawPath(
      Path()
        ..moveTo(76.5, 71)
        ..lineTo(83.5, 71)
        ..lineTo(80, 75)
        ..close(),
      Paint()
        ..color = pink
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.4
        ..style = PaintingStyle.fill,
    );
    _mouth(canvas);

    final whiskers = Paint()
      ..color = whisker.withValues(alpha: 0.8)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (final (from, to) in const [
      (Offset(58, 74), Offset(34, 70)),
      (Offset(58, 77), Offset(33, 78)),
      (Offset(102, 74), Offset(126, 70)),
      (Offset(102, 77), Offset(127, 78)),
    ]) {
      canvas.drawLine(from, to, whiskers);
    }
  }

  void _ear(
    Canvas canvas, {
    required Offset pivot,
    required double angle,
    required Color color,
    required List<Offset> outer,
    required List<Offset> inner,
    required List<(Offset, Offset)> tufts,
  }) {
    Path triangle(List<Offset> p) => Path()
      ..moveTo(p[0].dx, p[0].dy)
      ..lineTo(p[1].dx, p[1].dy)
      ..lineTo(p[2].dx, p[2].dy)
      ..close();

    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy)
      ..rotate(angle)
      ..translate(-pivot.dx, -pivot.dy)
      ..drawPath(
        triangle(outer),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(triangle(outer), Paint()..color = color)
      ..drawPath(
        triangle(inner),
        Paint()
          ..color = innerEar
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(triangle(inner), Paint()..color = innerEar);
    final tuft = Paint()
      ..color = ruff
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final (from, to) in tufts) {
      canvas.drawLine(from, to, tuft);
    }
    canvas.restore();
  }

  void _eyes(Canvas canvas) {
    final open = pose.eyeOpen.clamp(0.0, 1.0);
    final line = Paint()
      ..color = feature
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (final (cx, tilt) in const [(66.0, -8.0), (94.0, 8.0)]) {
      const cy = 62.0;
      canvas
        ..save()
        ..translate(cx, cy)
        ..rotate(tilt * _deg)
        ..translate(-cx, -cy);

      if (pose.eyeCurve >= 0.5) {
        // ^^: happy arcs.
        final lift = 7 * pose.eyeCurve;
        canvas.drawPath(
          Path()
            ..moveTo(cx - 7, cy + 2)
            ..quadraticBezierTo(cx, cy + 2 - lift, cx + 7, cy + 2),
          line,
        );
      } else if (open <= 0.12) {
        canvas.drawPath(
          Path()
            ..moveTo(cx - 8, cy)
            ..quadraticBezierTo(cx, cy + 5, cx + 8, cy),
          line..strokeWidth = 2.2,
        );
      } else {
        final h = 6.6 * open;
        final almond = Path()
          ..moveTo(cx - 8, cy)
          ..quadraticBezierTo(cx, cy - h, cx + 8, cy)
          ..quadraticBezierTo(cx, cy + h, cx - 8, cy)
          ..close();
        canvas
          ..drawPath(almond, Paint()..color = iris)
          ..save()
          ..clipPath(almond);
        final pupilWidth = 3.2 + 1.6 * (1 - pose.pupilX.abs().clamp(0, 1));
        canvas
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                cx - pupilWidth / 2 + pose.pupilX * 3,
                cy - 5 * open + pose.pupilY * 1.8,
                pupilWidth,
                10 * open,
              ),
              const Radius.circular(1.6),
            ),
            Paint()..color = const Color(0xFF0E0F11),
          )
          ..restore()
          ..drawPath(
            almond,
            Paint()
              ..color = feature
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4,
          );
        if (open > 0.5) {
          canvas.drawCircle(
            Offset(cx + 2.5 + pose.pupilX * 2.5, cy - 2 * open),
            1.4,
            Paint()..color = Colors.white,
          );
        }
      }
      canvas.restore();
    }
  }

  void _mouth(Canvas canvas) {
    final yawn = pose.yawn;
    if (yawn > 0.08) {
      canvas
        ..drawOval(
          Rect.fromCenter(
            center: Offset(80, 80 + 2 * yawn),
            width: (3 + 3 * yawn) * 2,
            height: (2 + 6 * yawn) * 2,
          ),
          Paint()..color = mouthInside,
        )
        ..drawOval(
          Rect.fromCenter(
            center: Offset(80, 83 + 4 * yawn),
            width: (2 + 2 * yawn) * 2,
            height: 4,
          ),
          Paint()..color = pink,
        );
      return;
    }
    final mouth = Path();
    if (pose.mouthCurve > 0.5) {
      mouth
        ..moveTo(75, 78)
        ..quadraticBezierTo(80, 83, 85, 78);
    } else if (pose.mouthCurve < -0.3) {
      mouth
        ..moveTo(76, 81)
        ..quadraticBezierTo(80, 78, 84, 81);
    } else {
      mouth
        ..moveTo(75.5, 78)
        ..quadraticBezierTo(77.8, 80.4, 80, 78)
        ..quadraticBezierTo(82.2, 80.4, 84.5, 78);
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..color = feature
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// The front paw: resting on the ground, or raised to the mouth while
  /// grooming.
  void _paws(Canvas canvas, double rise) {
    final paw = pose.paw.clamp(0.0, 1.0);
    if (paw <= 0.08) {
      final rest = Rect.fromCenter(
        center: Offset(68, 147 - rise * 0.15),
        width: 17,
        height: 11,
      );
      canvas
        ..drawOval(rest, Paint()..color = fur)
        ..drawOval(rest, _outline(1.2));
      return;
    }
    final pawAt = Offset(68 + 6 * paw, 147 - 61 * paw);
    final arm = Path()
      ..moveTo(66, 122)
      ..quadraticBezierTo(62, 132 - 10 * paw, pawAt.dx, pawAt.dy);
    final pad = Rect.fromCenter(center: pawAt, width: 14, height: 12);
    canvas
      ..drawPath(
        arm,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 13
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        arm,
        Paint()
          ..color = fur
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round,
      )
      ..drawOval(pad, Paint()..color = fur)
      ..drawOval(pad, _outline(1.2))
      ..drawOval(
        Rect.fromCenter(
          center: pawAt + const Offset(1, 0),
          width: 4.8,
          height: 3.6,
        ),
        Paint()..color = innerEar,
      );
  }

  void _sparkles(Canvas canvas, double amount) {
    final star = Path()
      ..moveTo(0, -5)
      ..lineTo(1.3, -1.3)
      ..lineTo(5, 0)
      ..lineTo(1.3, 1.3)
      ..lineTo(0, 5)
      ..lineTo(-1.3, 1.3)
      ..lineTo(-5, 0)
      ..lineTo(-1.3, -1.3)
      ..close();
    for (final (at, color, scale) in const [
      (Offset(30, 34), iris, 1.0),
      (Offset(130, 24), orange, 0.8),
      (Offset(142, 62), iris, 0.7),
      (Offset(20, 82), orange, 0.6),
    ]) {
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..scale(scale * amount.clamp(0, 1))
        ..drawPath(star, Paint()..color = color)
        ..restore();
    }
  }

  Paint _outline(double width) => Paint()
    ..color = outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  static Path _bodyPath() => Path()
    ..moveTo(80, 60)
    ..cubicTo(62, 60, 50, 72, 47, 88)
    ..quadraticBezierTo(41, 92, 45, 98)
    ..cubicTo(40, 110, 41, 124, 46, 134)
    ..quadraticBezierTo(42, 140, 49, 142)
    ..cubicTo(54, 148, 66, 150, 80, 150)
    ..cubicTo(94, 150, 106, 148, 111, 142)
    ..quadraticBezierTo(118, 140, 114, 134)
    ..cubicTo(119, 124, 120, 110, 115, 98)
    ..quadraticBezierTo(119, 92, 113, 88)
    ..cubicTo(110, 72, 98, 60, 80, 60)
    ..close();

  static Path _headPath() => Path()
    ..moveTo(46, 66)
    ..cubicTo(46, 46, 62, 36, 80, 36)
    ..cubicTo(98, 36, 114, 46, 114, 66)
    ..quadraticBezierTo(121, 70, 115, 74)
    ..quadraticBezierTo(118, 80, 110, 81)
    ..cubicTo(104, 90, 92, 94, 80, 94)
    ..cubicTo(68, 94, 56, 90, 50, 81)
    ..quadraticBezierTo(42, 80, 45, 74)
    ..quadraticBezierTo(39, 70, 46, 66)
    ..close();

  @override
  bool shouldRepaint(MascotPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.progress != progress;
}
