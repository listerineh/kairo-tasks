import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/core/errors/failures.dart';
import 'package:kairotasks/features/calendar/domain/calendar_range.dart';
import 'package:kairotasks/features/calendar/domain/entities/calendar_palette.dart';
import 'package:kairotasks/features/calendar/domain/entities/friend_calendar.dart';
import 'package:kairotasks/features/calendar/domain/usecases/load_friend_calendar.dart';
import 'package:kairotasks/features/calendar/domain/usecases/watch_calendar_changes.dart';
import 'package:kairotasks/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockLoad extends Mock implements LoadFriendCalendar {}

class MockWatch extends Mock implements WatchCalendarChanges {}

void main() {
  final now = DateTime(2026, 10, 20, 15);
  const calendar = FriendCalendar(
    palette: CalendarPalette(ownColor: '#123456'),
  );
  late MockLoad load;
  late MockWatch watch;
  late StreamController<void> changes;

  CalendarCubit build() => CalendarCubit(
    load,
    watch,
    clock: () => now,
    debounce: const Duration(milliseconds: 20),
  );

  setUp(() {
    load = MockLoad();
    watch = MockWatch();
    changes = StreamController<void>.broadcast();
    when(() => watch()).thenAnswer((_) => changes.stream);
    when(() => load()).thenAnswer((_) async => const Right(calendar));
  });

  tearDown(() => unawaited(changes.close()));

  test('starts on this week', () {
    final cubit = build();
    expect(cubit.state.selectedDate, now);
    expect(cubit.state.viewType, CalendarViewType.week);
    unawaited(cubit.close());
  });

  blocTest<CalendarCubit, CalendarState>(
    'start loads the friends overlay',
    build: build,
    act: (c) => c.start(),
    expect: () => [
      CalendarState(selectedDate: now, status: CalendarStatus.loading),
      CalendarState(
        selectedDate: now,
        status: CalendarStatus.loaded,
        friendCalendar: calendar,
      ),
    ],
  );

  blocTest<CalendarCubit, CalendarState>(
    'a burst of changes reloads once',
    build: build,
    act: (c) async {
      await c.start();
      changes
        ..add(null)
        ..add(null)
        ..add(null);
    },
    wait: const Duration(milliseconds: 80),
    verify: (_) => verify(() => load()).called(2),
  );

  blocTest<CalendarCubit, CalendarState>(
    'a failed reload keeps the last overlay',
    build: build,
    seed: () => CalendarState(
      selectedDate: now,
      friendCalendar: calendar,
      status: CalendarStatus.loaded,
    ),
    setUp: () => when(() => load())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'offline'))),
    act: (c) => c.reload(),
    skip: 1,
    expect: () => [
      CalendarState(
        selectedDate: now,
        friendCalendar: calendar,
        status: CalendarStatus.error,
      ),
    ],
  );

  blocTest<CalendarCubit, CalendarState>(
    'navigates by the current view and opens days',
    build: build,
    act: (c) => c
      ..next()
      ..setView(CalendarViewType.month)
      ..previous()
      ..showDay(DateTime(2026, 9, 3))
      ..today(),
    expect: () => [
      CalendarState(selectedDate: DateTime(2026, 10, 27)),
      CalendarState(
        selectedDate: DateTime(2026, 10, 27),
        viewType: CalendarViewType.month,
      ),
      CalendarState(
        selectedDate: DateTime(2026, 9),
        viewType: CalendarViewType.month,
      ),
      CalendarState(
        selectedDate: DateTime(2026, 9, 3),
        viewType: CalendarViewType.day,
      ),
      CalendarState(selectedDate: now, viewType: CalendarViewType.day),
    ],
  );
}
