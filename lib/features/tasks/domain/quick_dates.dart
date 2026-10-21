/// Date shortcuts offered when planning a task (docs/redesign-plan.md §3).
enum QuickDate { today, tomorrow, weekend }

/// The day a [QuickDate] stands for, at midnight (a date without a time).
///
/// "This weekend" is the coming Saturday; on a Saturday or Sunday it is
/// that same day, since the weekend has already started.
DateTime quickDate(QuickDate q, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return switch (q) {
    QuickDate.today => today,
    QuickDate.tomorrow => DateTime(now.year, now.month, now.day + 1),
    QuickDate.weekend => switch (now.weekday) {
      DateTime.saturday || DateTime.sunday => today,
      final weekday => DateTime(
        now.year,
        now.month,
        now.day + DateTime.saturday - weekday,
      ),
    },
  };
}

/// Which shortcut, if any, [date] falls on. Today wins over the weekend.
QuickDate? matchingQuickDate(DateTime? date, DateTime now) {
  if (date == null) return null;
  final day = DateTime(date.year, date.month, date.day);
  for (final q in QuickDate.values) {
    if (quickDate(q, now) == day) return q;
  }
  return null;
}

/// [day] with the time of [time] (or no time when [time] is null).
DateTime withTime(DateTime day, ({int hour, int minute})? time) =>
    DateTime(day.year, day.month, day.day, time?.hour ?? 0, time?.minute ?? 0);

/// Whether [d] carries a time of day (midnight means "date only").
bool hasTimeOfDay(DateTime d) => d.hour != 0 || d.minute != 0;
