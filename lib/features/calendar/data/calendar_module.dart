import 'package:injectable/injectable.dart';

import '../domain/repositories/calendar_repository.dart';
import '../domain/usecases/load_friend_calendar.dart';
import '../domain/usecases/watch_calendar_changes.dart';

/// Registers calendar use cases; the domain layer stays free of DI
/// annotations.
@module
abstract class CalendarModule {
  LoadFriendCalendar loadFriendCalendar(CalendarRepository r) =>
      LoadFriendCalendar(r);
  WatchCalendarChanges watchCalendarChanges(CalendarRepository r) =>
      WatchCalendarChanges(r);
}
