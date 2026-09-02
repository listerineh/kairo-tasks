import 'package:equatable/equatable.dart';

import '../../../tasks/domain/entities/task_entity.dart';

enum FocusMode { focus, break_ }

class FocusState extends Equatable {
  const FocusState({
    this.selectedTask,
    this.remaining = const Duration(minutes: 25),
    this.isRunning = false,
    this.mode = FocusMode.focus,
  });

  final TaskEntity? selectedTask;
  final Duration remaining;
  final bool isRunning;
  final FocusMode mode;

  FocusState copyWith({
    TaskEntity? selectedTask,
    Duration? remaining,
    bool? isRunning,
    FocusMode? mode,
    bool clearTask = false,
  }) =>
      FocusState(
        selectedTask: clearTask ? null : (selectedTask ?? this.selectedTask),
        remaining: remaining ?? this.remaining,
        isRunning: isRunning ?? this.isRunning,
        mode: mode ?? this.mode,
      );

  @override
  List<Object?> get props => [selectedTask, remaining, isRunning, mode];
}
