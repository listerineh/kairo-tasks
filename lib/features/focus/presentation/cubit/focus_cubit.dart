import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import 'focus_state.dart';

class FocusCubit extends Cubit<FocusState> {
  FocusCubit() : super(const FocusState());

  Timer? _timer;

  void selectTask(TaskEntity task) {
    emit(
      state.copyWith(
        selectedTask: task,
        mode: FocusMode.focus,
        remaining: const Duration(minutes: 25),
      ),
    );
  }

  void start({Duration? duration}) {
    _timer?.cancel();
    final remaining = duration ?? state.remaining;
    emit(state.copyWith(remaining: remaining, isRunning: true));
    _scheduleNotification();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) return;
      final next = state.remaining - const Duration(seconds: 1);
      if (next.inSeconds <= 0) {
        _onFinished();
      } else {
        emit(state.copyWith(remaining: next));
      }
    });
  }

  void pause() {
    _timer?.cancel();
    emit(state.copyWith(isRunning: false));
    NotificationService.instance.cancelFocusSessionEnd();
  }

  void reset() {
    _timer?.cancel();
    final newDuration = state.mode == FocusMode.focus
        ? const Duration(minutes: 25)
        : const Duration(minutes: 5);
    emit(
      state.copyWith(
        remaining: newDuration,
        isRunning: false,
        mode: FocusMode.focus,
        clearTask: true,
      ),
    );
    NotificationService.instance.cancelFocusSessionEnd();
  }

  void startBreak() {
    _timer?.cancel();
    emit(
      state.copyWith(
        mode: FocusMode.break_,
        remaining: const Duration(minutes: 5),
        isRunning: false,
      ),
    );
  }

  void _onFinished() {
    _timer?.cancel();
    emit(state.copyWith(isRunning: false, remaining: Duration.zero));
  }

  void _scheduleNotification() {
    final taskTitle =
        state.mode == FocusMode.focus ? state.selectedTask?.title : null;
    NotificationService.instance.scheduleFocusSessionEnd(
      taskTitle: taskTitle,
      duration: state.remaining,
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    NotificationService.instance.cancelFocusSessionEnd();
    return super.close();
  }
}
