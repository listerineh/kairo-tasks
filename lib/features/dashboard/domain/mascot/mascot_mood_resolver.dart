import 'mascot_mood.dart';

/// Pure rules from docs/redesign-plan.md §2.6, checked in priority order:
///
/// 1. A running focus session wins: the cat watches the timer.
/// 2. Night (00:00-06:00): sleeping.
/// 3. Something done today and nothing left: happy.
/// 4. From 20:00, nothing done today while tasks or a live streak wait:
///    sad (streak at risk).
/// 5. Nothing planned and nothing done today: rest day, sleeping.
/// 6. Otherwise: idle.
class MascotMoodResolver {
  const MascotMoodResolver();

  static const nightEndsHour = 6;
  static const streakRiskHour = 20;

  MascotMood resolve(MascotSituation s) {
    if (s.focusRunning) return MascotMood.focused;
    if (s.now.hour < nightEndsHour) return MascotMood.sleeping;

    final doneSomething = s.completedToday > 0;
    if (doneSomething && s.pendingToday == 0) return MascotMood.happy;

    if (!doneSomething && s.now.hour >= streakRiskHour) {
      if (s.pendingToday > 0 || _streakAlive(s)) return MascotMood.sad;
    }

    if (!doneSomething && s.pendingToday == 0) return MascotMood.sleeping;
    return MascotMood.idle;
  }

  /// The streak survives today only if the last completion was yesterday.
  bool _streakAlive(MascotSituation s) {
    final last = s.lastCompletionDay;
    if (last == null) return false;
    final today = DateTime(s.now.year, s.now.month, s.now.day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final lastDay = DateTime(last.year, last.month, last.day);
    return lastDay == yesterday;
  }
}
