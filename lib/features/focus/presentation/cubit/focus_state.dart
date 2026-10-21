import 'package:equatable/equatable.dart';

import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/focus_session.dart';

class FocusState extends Equatable {
  const FocusState({
    required this.now,
    this.session = const FocusSession(),
    this.task,
    this.chosen = false,
  });

  /// The clock at the last tick; the UI derives the countdown from it.
  final DateTime now;
  final FocusSession session;

  /// What the session is about; null for "just focus".
  final TaskEntity? task;

  /// Whether the person picked a task (or chose to just focus).
  final bool chosen;

  Duration get remaining => session.remaining(now);
  double get progress => session.progress(now);
  bool get running => session.running && !finished;
  bool get finished => session.finished(now);

  FocusState copyWith({
    DateTime? now,
    FocusSession? session,
    TaskEntity? task,
    bool clearTask = false,
    bool? chosen,
  }) => FocusState(
    now: now ?? this.now,
    session: session ?? this.session,
    task: clearTask ? null : (task ?? this.task),
    chosen: chosen ?? this.chosen,
  );

  @override
  List<Object?> get props => [now, session, task, chosen];
}
