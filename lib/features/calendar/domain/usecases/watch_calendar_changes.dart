import '../repositories/calendar_repository.dart';

class WatchCalendarChanges {
  const WatchCalendarChanges(this._repository);

  final CalendarRepository _repository;

  Stream<void> call() => _repository.changes();
}
