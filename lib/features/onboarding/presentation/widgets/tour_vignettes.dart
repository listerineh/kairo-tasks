import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../calendar/presentation/widgets/calendar_colors.dart';
import '../../../dashboard/domain/mascot/mascot_mood.dart';
import '../../../dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import '../../../dashboard/presentation/widgets/mascot/mascot_behavior.dart';

/// The picture for one tour step: a small live piece of the app that plays
/// once each time its step comes into view. With reduced motion it shows
/// its final frame.
class TourVignette extends StatefulWidget {
  const TourVignette({required this.step, required this.active, super.key});

  /// 0 hello, 1 today, 2 focus, 3 together.
  final int step;
  final bool active;

  static const duration = Duration(milliseconds: 2200);

  @override
  State<TourVignette> createState() => _TourVignetteState();
}

class _TourVignetteState extends State<TourVignette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(
    vsync: this,
    duration: TourVignette.duration,
  );
  int _plays = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.active && _plays == 0) _start();
  }

  @override
  void didUpdateWidget(TourVignette old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _start();
  }

  void _start() {
    _plays++;
    if (context.motion.reduced) {
      _play.value = 1;
    } else {
      _play.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _play,
      builder: (context, _) {
        final t = _play.value;
        return switch (widget.step) {
          0 => _Hello(cueTrigger: _plays),
          1 => _Today(t: t),
          2 => _Focus(t: t),
          _ => _Together(t: t),
        };
      },
    );
  }
}

/// Progress of [t] through the window [a, b], eased.
double _phase(
  double t,
  double a,
  double b, [
  Curve curve = Curves.easeOutCubic,
]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// Rises 14 px and fades in as [p] goes 0 → 1.
Widget _rise(double p, Widget child) => Opacity(
  opacity: p,
  child: Transform.translate(offset: Offset(0, 14 * (1 - p)), child: child),
);

const _cardShadow = [
  BoxShadow(color: Color(0x0A121417), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x0D121417), blurRadius: 22, offset: Offset(0, 8)),
];

class _Hello extends StatelessWidget {
  const _Hello({required this.cueTrigger});

  final int cueTrigger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A121417),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x14121417),
            blurRadius: 56,
            offset: Offset(0, 24),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: KairoMascot(
        mood: MascotMood.idle,
        cue: MascotBehavior.look,
        cueTrigger: cueTrigger,
        size: 210,
      ),
    );
  }
}

/// "Now" with Focus, and the task below it getting done and sliding away.
class _Today extends StatelessWidget {
  const _Today({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final type = context.typography;
    final check = _phase(t, 0.32, 0.5);
    final away = _phase(t, 0.56, 0.78, Curves.easeInCubic);
    // Once it's gone the row closes up, so the next task moves into place.
    final close = _phase(t, 0.78, 1, Curves.easeInOutCubic);

    Widget row({required Widget leading, required String label, Widget? end}) =>
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _cardShadow,
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: type.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?end,
            ],
          ),
        );

    return SizedBox(
      width: 316,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _rise(
            _phase(t, 0, 0.26),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: colors.ink,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tourNow,
                    style: type.footnote.copyWith(
                      color: colors.onInkSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tourSampleReport,
                    style: type.title3.copyWith(color: colors.onInk),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colors.lime,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.play_fill,
                          size: 14,
                          color: colors.onLime,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.focusAction,
                          style: type.subheadline.copyWith(
                            color: colors.onLime,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1 - close,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _rise(
                  _phase(t, 0.08, 0.34),
                  Opacity(
                    opacity: 1 - away,
                    child: Transform.translate(
                      offset: Offset(56 * away, 0),
                      child: row(
                        leading: CustomPaint(
                          size: const Size.square(26),
                          painter: _CheckPainter(
                            progress: check,
                            fill: colors.tint,
                            ring: colors.separator,
                            mark: colors.onTint,
                          ),
                        ),
                        label: l10n.tourSampleCall,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _rise(
            _phase(t, 0.14, 0.4),
            row(
              leading: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.separator, width: 2),
                ),
              ),
              label: l10n.tourSampleRun,
              end: Text(
                '18:30',
                style: type.subheadline.copyWith(color: colors.labelSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An empty ring that fills with [fill] and draws a check as [progress]
/// goes 0 → 1.
class _CheckPainter extends CustomPainter {
  const _CheckPainter({
    required this.progress,
    required this.fill,
    required this.ring,
    required this.mark,
  });

  final double progress;
  final Color fill;
  final Color ring;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final filled = _phase(progress, 0, 0.4);
    canvas
      ..drawCircle(
        center,
        radius - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Color.lerp(ring, fill, filled)!,
      )
      ..drawCircle(
        center,
        radius * filled,
        Paint()..color = fill.withValues(alpha: filled),
      );
    final draw = _phase(progress, 0.3, 1);
    if (draw == 0) return;
    final s = size.width / 26;
    final path = Path()
      ..moveTo(7.5 * s, 13.5 * s)
      ..lineTo(11.1 * s, 17.1 * s)
      ..lineTo(18.5 * s, 9.5 * s);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * draw),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = mark,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.fill != fill || old.mark != mark;
}

/// The dark focus screen in miniature: the lime ring draws itself.
class _Focus extends StatelessWidget {
  const _Focus({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final type = context.typography;
    return _rise(
      _phase(t, 0, 0.26),
      Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: colors.ink,
          borderRadius: BorderRadius.circular(40),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(200),
              painter: _RingPainter(
                progress: 0.73 * _phase(t, 0.14, 0.86),
                track: colors.onInk.withValues(alpha: 0.08),
                color: colors.lime,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '18:42',
                  style: type.title1.copyWith(
                    color: colors.onInk,
                    fontSize: 46,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.5,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tourRound,
                  style: type.footnote.copyWith(
                    color: colors.onInkSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// A shared task filling up, then a friend's nudge popping in.
class _Together extends StatelessWidget {
  const _Together({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final type = context.typography;
    final nudge = _phase(t, 0.62, 0.9, Curves.easeOutBack);

    return SizedBox(
      width: 316,
      child: Column(
        children: [
          _rise(
            _phase(t, 0, 0.26),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: _cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.tourSharedTask, style: type.headline),
                      ),
                      const _Avatar(initials: 'AN', tone: CalendarTone.sage),
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: const _Avatar(
                          initials: 'LU',
                          tone: CalendarTone.blue,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-16, 0),
                        child: _Avatar(
                          initials: l10n.tourYou,
                          tone: CalendarTone.clay,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 8,
                      color: colors.fill,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.66 * _phase(t, 0.2, 0.62),
                        heightFactor: 1,
                        child: ColoredBox(color: colors.tint),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.tourSharedProgress,
                    style: type.footnote.copyWith(color: colors.labelSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          Opacity(
            opacity: nudge.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - nudge)),
              child: Transform.scale(
                scale: 0.9 + 0.1 * nudge,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: colors.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Avatar(
                        initials: 'AN',
                        tone: CalendarTone.sage,
                        size: 28,
                        ring: false,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.tourNudge,
                        style: type.subheadline.copyWith(
                          color: colors.onInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        CupertinoIcons.arrow_right,
                        size: 16,
                        color: colors.lime,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.tone,
    this.size = 32,
    this.ring = true,
  });

  final String initials;
  final CalendarTone tone;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.fill,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: colors.surface, width: 2) : null,
      ),
      child: Text(
        initials,
        textScaler: TextScaler.noScaling,
        style: context.typography.caption1.copyWith(
          color: tone.ink,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
