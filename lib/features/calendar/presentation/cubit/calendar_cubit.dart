import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/logger_service.dart';
import '../../domain/calendar_range.dart';
import '../../domain/entities/friend_calendar.dart';
import '../../domain/usecases/load_friend_calendar.dart';
import '../../domain/usecases/watch_calendar_changes.dart';

enum CalendarStatus { initial, loading, loaded, error }

class CalendarState extends Equatable {
  const CalendarState({
    required this.selectedDate,
    this.viewType = CalendarViewType.week,
    this.friendCalendar = const FriendCalendar(),
    this.status = CalendarStatus.initial,
  });

  final DateTime selectedDate;
  final CalendarViewType viewType;

  /// Colors and friends' tasks. On a failed reload the last good one stays,
  /// since the overlay is optional and my own tasks still show.
  final FriendCalendar friendCalendar;
  final CalendarStatus status;

  CalendarState copyWith({
    DateTime? selectedDate,
    CalendarViewType? viewType,
    FriendCalendar? friendCalendar,
    CalendarStatus? status,
  }) => CalendarState(
    selectedDate: selectedDate ?? this.selectedDate,
    viewType: viewType ?? this.viewType,
    friendCalendar: friendCalendar ?? this.friendCalendar,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [selectedDate, viewType, friendCalendar, status];
}

/// Calendar navigation plus the friends overlay. Reloads when my profile
/// or friendships change, coalescing bursts of realtime events.
@injectable
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(
    this._load,
    this._watch, {
    @ignoreParam DateTime Function()? clock,
    @ignoreParam Duration debounce = const Duration(milliseconds: 500),
  }) : _now = clock ?? DateTime.now,
       _debounceFor = debounce,
       super(CalendarState(selectedDate: (clock ?? DateTime.now)()));

  final LoadFriendCalendar _load;
  final WatchCalendarChanges _watch;
  final DateTime Function() _now;
  final Duration _debounceFor;

  StreamSubscription<void>? _changes;
  Timer? _debounce;

  /// Loads the overlay once and keeps it fresh. Safe to call again.
  Future<void> start() async {
    await _changes?.cancel();
    _changes = _watch().listen(
      (_) => _scheduleReload(),
      onError: (Object e) => LoggerService.instance.error(
        'Calendar changes stream failed',
        data: {'operation': 'calendar.watch', 'error': e.toString()},
      ),
    );
    await reload();
  }

  Future<void> reload() async {
    emit(state.copyWith(status: CalendarStatus.loading));
    final result = await _load();
    if (isClosed) return;
    result.fold(
      (failure) {
        LoggerService.instance.error(
          'Failed to load friend calendar',
          data: {'operation': 'calendar.load', 'error': failure.message},
        );
        emit(state.copyWith(status: CalendarStatus.error));
      },
      (calendar) => emit(
        state.copyWith(friendCalendar: calendar, status: CalendarStatus.loaded),
      ),
    );
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(_debounceFor, reload);
  }

  void setView(CalendarViewType view) => emit(state.copyWith(viewType: view));

  void selectDate(DateTime date) => emit(state.copyWith(selectedDate: date));

  /// Opens [date] in the day view (from a week or month cell).
  void showDay(DateTime date) =>
      emit(state.copyWith(selectedDate: date, viewType: CalendarViewType.day));

  void next() => _step(forward: true);

  void previous() => _step(forward: false);

  void today() => emit(state.copyWith(selectedDate: _now()));

  void _step({required bool forward}) => emit(
    state.copyWith(
      selectedDate: stepDate(
        state.selectedDate,
        state.viewType,
        forward: forward,
      ),
    ),
  );

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _changes?.cancel();
    return super.close();
  }
}
