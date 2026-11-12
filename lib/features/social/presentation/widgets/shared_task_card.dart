import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/widgets/task_row.dart';
import '../../domain/shared_tasks.dart';
import 'person_avatar.dart';

/// A task shared with friends: a progress ring, when it is and with whom,
/// the people's avatars, and two actions: nudge them, or focus on it.
class SharedTaskCard extends StatelessWidget {
  const SharedTaskCard({
    required this.task,
    required this.now,
    required this.nudged,
    required this.onNudge,
    required this.onFocus,
    required this.onOpen,
    super.key,
  });

  final TaskEntity task;
  final DateTime now;
  final bool nudged;
  final VoidCallback onNudge;
  final VoidCallback onFocus;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final people = task.sharedWith;
    final names = [
      for (final p in people)
        if ((p['display_name'] as String?)?.trim().isNotEmpty ?? false)
          (p['display_name'] as String).trim().split(RegExp(r'\s+')).first
        else
          '@${p['username'] ?? ''}',
    ];
    final when = TaskRow.whenLabel(context, task, now);
    final meta = [
      if (when != null) when,
      l10n.withNames(names.join(', ')),
    ].join(' · ');
    final progress = sharedProgress(task);
    final tone = toneFor(
      people.isEmpty ? task.id : (people.first['id'] as String? ?? task.id),
    );
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final nudge = KairoButton(
      label: nudged ? l10n.nudgeSentLabel : l10n.nudge,
      icon: nudged ? CupertinoIcons.checkmark_alt : CupertinoIcons.hand_raised,
      variant: nudged ? KairoButtonVariant.tinted : KairoButtonVariant.outline,
      onPressed: nudged ? null : onNudge,
    );
    final focus = KairoButton(
      label: l10n.focusTogether,
      variant: KairoButtonVariant.filled,
      onPressed: onFocus,
    );

    return KairoCard(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                _ProgressRing(
                  progress: progress,
                  color: tone.dot,
                  track: colors.fill,
                  label: l10n.progressSteps((progress * 100).round()),
                ),
                const SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: context.typography.headline),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        style: context.typography.footnote.copyWith(
                          color: colors.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing8),
                ExcludeSemantics(child: _Faces(people: people)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (stacked)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [nudge, const SizedBox(height: 8), focus],
            )
          else
            Row(
              children: [
                Expanded(child: nudge),
                const SizedBox(width: 8),
                Expanded(child: focus),
              ],
            ),
        ],
      ),
    );
  }
}

/// Up to three overlapping faces.
class _Faces extends StatelessWidget {
  const _Faces({required this.people});

  final List<Map<String, dynamic>> people;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(3).toList();
    const size = 30.0;
    const overlap = 8.0;
    final ring = context.appColors.surface;
    return SizedBox(
      width: size + (shown.length - 1) * (size - overlap),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: 2),
                ),
                child: PersonAvatar(
                  id: shown[i]['id'] as String? ?? '$i',
                  name:
                      (shown[i]['display_name'] as String?) ??
                      (shown[i]['username'] as String?) ??
                      '?',
                  imageUrl: shown[i]['avatar_url'] as String?,
                  size: size - 4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A 44 pt ring that fills to [progress], sliding with the `smooth` spring.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.track,
    required this.label,
  });

  final double progress;
  final Color color;
  final Color track;
  final String label;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return Semantics(
      label: label,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration: motion.duration(KairoSpring.smooth),
        curve: motion.curve(KairoSpring.smooth),
        builder: (context, value, _) => CustomPaint(
          size: const Size.square(44),
          painter: _RingPainter(value, color, track),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color, this.track);

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
