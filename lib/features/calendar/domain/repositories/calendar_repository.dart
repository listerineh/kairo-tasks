import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/friend_calendar.dart';

abstract class CalendarRepository {
  /// My color, my friends' colors and their visible tasks.
  Future<Either<Failure, FriendCalendar>> loadFriendCalendar();

  /// Fires when my profile or friendships change (colors, new friends).
  Stream<void> changes();
}
