import 'package:equatable/equatable.dart';

import '../../../tasks/domain/entities/task_entity.dart';
import 'calendar_palette.dart';

/// A friend's task as the calendar may show it.
class FriendCalendarTask extends Equatable {
  const FriendCalendarTask({required this.task, required this.isPrivate});

  final TaskEntity task;

  /// The friend's calendar is private and the task is not shared with me:
  /// show only that the time is busy, never the title or notes.
  final bool isPrivate;

  @override
  List<Object?> get props => [task, isPrivate];
}

/// Everything the calendar needs besides my own tasks.
class FriendCalendar extends Equatable {
  const FriendCalendar({
    this.palette = const CalendarPalette(),
    this.friendTasks = const [],
  });

  final CalendarPalette palette;
  final List<FriendCalendarTask> friendTasks;

  @override
  List<Object?> get props => [palette, friendTasks];
}
