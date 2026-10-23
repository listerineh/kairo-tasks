import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/haptics_service.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/focus_session.dart';
import 'focus_state.dart';

/// Runs the focus session. A lazy singleton, so leaving the Focus screen
/// keeps the session; the countdown comes from the session's end time, and
/// the 1 s ticker only refreshes the display.
@lazySingleton
class FocusCubit extends Cubit<FocusState> {
  FocusCubit(
    this._alarm, {
    @ignoreParam DateTime Function()? clock,
    @ignoreParam Duration tickEvery = const Duration(seconds: 1),
  }) : _now = clock ?? DateTime.now,
       _tick = tickEvery,
       super(FocusState(now: (clock ?? DateTime.now)()));

  final FocusAlarm _alarm;
  final DateTime Function() _now;
  final Duration _tick;
  Timer? _timer;

  /// Starts a focus round on [task] (null: just focus).
  void choose(TaskEntity? task) {
    final now = _now();
    emit(
      FocusState(
        now: now,
        task: task,
        chosen: true,
        session: const FocusSession().start(now),
      ),
    );
    _onRunningChanged();
  }

  /// Back to the task picker; the session is dropped.
  void changeTask() {
    _stop();
    emit(FocusState(now: _now()));
  }

  void toggle() {
    final now = _now();
    final session = state.running
        ? state.session.pause(now)
        : state.session.start(now);
    emit(state.copyWith(now: now, session: session));
    _onRunningChanged();
  }

  void reset() {
    emit(state.copyWith(now: _now(), session: state.session.reset()));
    _onRunningChanged();
  }

  void addExtra() {
    final now = _now();
    emit(state.copyWith(now: now, session: state.session.addExtra(now)));
    _onRunningChanged();
  }

  /// After a phase ends: start the rest, or the next focus round.
  void next() {
    final now = _now();
    emit(state.copyWith(now: now, session: state.session.next().start(now)));
    _onRunningChanged();
  }

  void _onRunningChanged() {
    _timer?.cancel();
    unawaited(_alarm.cancel());
    if (!state.running) return;
    final focus = state.session.phase == FocusPhase.focus;
    unawaited(
      _alarm.schedule(
        after: state.remaining,
        taskTitle: focus ? (state.task?.title ?? '') : null,
      ),
    );
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    if (isClosed) return;
    final wasFinished = state.finished;
    emit(state.copyWith(now: _now()));
    if (!wasFinished && state.finished) {
      _timer?.cancel();
      final haptics = registeredHaptics;
      if (haptics != null) unawaited(haptics.celebrated());
    }
  }

  void _stop() {
    _timer?.cancel();
    unawaited(_alarm.cancel());
  }

  @override
  Future<void> close() {
    _stop();
    return super.close();
  }
}
