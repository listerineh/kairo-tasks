import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/friend_calendar.dart';
import '../repositories/calendar_repository.dart';

class LoadFriendCalendar {
  const LoadFriendCalendar(this._repository);

  final CalendarRepository _repository;

  Future<Either<Failure, FriendCalendar>> call() =>
      _repository.loadFriendCalendar();
}
