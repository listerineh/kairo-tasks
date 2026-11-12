import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../dashboard/domain/mascot/mascot_mood.dart';
import '../../../dashboard/domain/mascot/mascot_mood_resolver.dart';

/// What Kairo says in each mood (Yo and his page). He sleeps at night and
/// on a rest day, so the sleeping line depends on the hour of [now].
String kairoLine(BuildContext context, MascotMood mood, {DateTime? now}) {
  final l10n = context.l10n;
  final isNight =
      (now ?? DateTime.now()).hour < MascotMoodResolver.nightEndsHour;
  return switch (mood) {
    MascotMood.idle => l10n.kairoLineIdle,
    MascotMood.focused => l10n.kairoLineFocused,
    MascotMood.happy => l10n.kairoLineHappy,
    MascotMood.sad => l10n.kairoLineSad,
    MascotMood.sleeping =>
      isNight ? l10n.kairoLineSleeping : l10n.kairoLineResting,
  };
}
