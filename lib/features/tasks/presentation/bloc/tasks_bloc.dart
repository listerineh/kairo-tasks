import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/session/current_user.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/services/task_reminders.dart';
import '../../domain/streak.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/set_task_completed.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/watch_tasks.dart';

// Events
abstract class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

class TasksLoadRequested extends TasksEvent {
  const TasksLoadRequested();
}

class TasksFilterChanged extends TasksEvent {
  const TasksFilterChanged(this.filter);
  final TasksFilter filter;

  @override
  List<Object?> get props => [filter];
}

class TaskCreateRequested extends TasksEvent {
  const TaskCreateRequested({
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.startDate,
    this.dueDate,
    this.sharedWith,
  });

  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? startDate;
  final DateTime? dueDate;
  final List<String>? sharedWith;

  @override
  List<Object?> get props => [
    title,
    description,
    priority,
    startDate,
    dueDate,
    sharedWith,
  ];
}

class TaskStatusToggled extends TasksEvent {
  const TaskStatusToggled(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Null [priority], [startDate] or [dueDate] keep the task's current value;
/// null [sharedWith] leaves its shares untouched.
class TaskEditRequested extends TasksEvent {
  const TaskEditRequested({
    required this.taskId,
    required this.title,
    this.description,
    this.priority,
    this.startDate,
    this.dueDate,
    this.sharedWith,
  });

  final String taskId;
  final String title;
  final String? description;
  final TaskPriority? priority;
  final DateTime? startDate;
  final DateTime? dueDate;
  final List<String>? sharedWith;

  @override
  List<Object?> get props => [
    taskId,
    title,
    description,
    priority,
    startDate,
    dueDate,
    sharedWith,
  ];
}

/// Hides the task right away; it is deleted once the undo window passes.
class TaskDeleted extends TasksEvent {
  const TaskDeleted(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Brings back the task from the last [TaskDeleted] within its undo window.
class TaskDeleteUndone extends TasksEvent {
  const TaskDeleteUndone();
}

class TasksClearStreakCelebration extends TasksEvent {
  const TasksClearStreakCelebration();
}

class _TaskDeletionCommitted extends TasksEvent {
  const _TaskDeletionCommitted(this.task);
  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

// Filter
enum TasksFilter { all, urgent, high, medium, low, completed }

// State
class _Undefined {
  const _Undefined();
}

class TasksState extends Equatable {
  const TasksState({
    this.tasks = const [],
    this.status = TasksStatus.initial,
    this.filter = TasksFilter.all,
    this.errorMessage,
    this.streakToCelebrate,
    this.pendingDeletion,
  });

  final List<TaskEntity> tasks;
  final TasksStatus status;
  final TasksFilter filter;
  final String? errorMessage;
  final int? streakToCelebrate;

  /// Deleted but still undoable; already hidden from [tasks].
  final TaskEntity? pendingDeletion;

  static const Object _undefined = _Undefined();

  static const _priorityOrder = {
    TaskPriority.urgent: 0,
    TaskPriority.high: 1,
    TaskPriority.medium: 2,
    TaskPriority.low: 3,
  };

  /// Active (non-completed) tasks for the current filter, sorted by priority.
  List<TaskEntity> get activeTasks {
    final wanted = switch (filter) {
      TasksFilter.all => null,
      TasksFilter.urgent => TaskPriority.urgent,
      TasksFilter.high => TaskPriority.high,
      TasksFilter.medium => TaskPriority.medium,
      TasksFilter.low => TaskPriority.low,
      TasksFilter.completed => null,
    };
    if (filter == TasksFilter.completed) return [];
    return tasks
        .where(
          (t) =>
              t.status != TaskStatus.completed &&
              (wanted == null || t.priority == wanted),
        )
        .toList()
      ..sort(
        (a, b) => (_priorityOrder[a.priority] ?? 2).compareTo(
          _priorityOrder[b.priority] ?? 2,
        ),
      );
  }

  /// Completed tasks, most recently completed first.
  List<TaskEntity> get completedTasks =>
      tasks.where((t) => t.status == TaskStatus.completed).toList()
        ..sort((a, b) {
          final aDate = a.completedAt ?? a.updatedAt ?? a.createdAt;
          final bDate = b.completedAt ?? b.updatedAt ?? b.createdAt;
          return bDate.compareTo(aDate);
        });

  /// Legacy getter for backward compat - returns active tasks only.
  List<TaskEntity> get filteredTasks => activeTasks;

  TasksState copyWith({
    List<TaskEntity>? tasks,
    TasksStatus? status,
    TasksFilter? filter,
    String? errorMessage,
    Object? streakToCelebrate = _undefined,
    Object? pendingDeletion = _undefined,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      status: status ?? this.status,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
      streakToCelebrate: identical(streakToCelebrate, _undefined)
          ? this.streakToCelebrate
          : streakToCelebrate as int?,
      pendingDeletion: identical(pendingDeletion, _undefined)
          ? this.pendingDeletion
          : pendingDeletion as TaskEntity?,
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    status,
    filter,
    errorMessage,
    streakToCelebrate,
    pendingDeletion,
  ];
}

enum TasksStatus { initial, loading, loaded, error }

// BLoC
@injectable
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc(
    this._watchTasks,
    this._createTask,
    this._updateTask,
    this._setCompleted,
    this._deleteTask,
    this._reminders,
    this._user, {
    @ignoreParam Duration undoWindow = const Duration(seconds: 4),
    @ignoreParam DateTime Function()? clock,
  }) : _undoAfter = undoWindow,
       _now = clock ?? DateTime.now,
       super(const TasksState()) {
    on<TasksLoadRequested>(_onLoadRequested, transformer: _restartable());
    on<TasksFilterChanged>(_onFilterChanged);
    on<TaskCreateRequested>(_onCreateRequested);
    on<TaskEditRequested>(_onEditRequested);
    on<TaskStatusToggled>(_onStatusToggled);
    on<TaskDeleted>(_onDeleted);
    on<TaskDeleteUndone>(_onDeleteUndone);
    on<_TaskDeletionCommitted>(_onDeletionCommitted);
    on<TasksClearStreakCelebration>(_onClearStreakCelebration);
  }

  final WatchTasks _watchTasks;
  final CreateTask _createTask;
  final UpdateTask _updateTask;
  final SetTaskCompleted _setCompleted;
  final DeleteTask _deleteTask;
  final TaskReminders _reminders;
  final CurrentUser _user;
  final Duration _undoAfter;
  final DateTime Function() _now;

  Timer? _undoTimer;

  /// Ids whose status changed locally and is not confirmed by the server
  /// yet; incoming snapshots keep the local status for them.
  final Map<String, TaskStatus> _optimisticStatus = {};

  /// Like switchMap: a new load cancels the previous subscription.
  static EventTransformer<E> _restartable<E>() => (events, mapper) {
    StreamSubscription<E>? inner;
    late final StreamController<E> out;
    out = StreamController<E>(
      onListen: () {
        final outer = events.listen(
          (event) {
            unawaited(inner?.cancel());
            inner = mapper(event).listen(out.add, onError: out.addError);
          },
          onError: out.addError,
          onDone: () async {
            await inner?.cancel();
            await out.close();
          },
        );
        out.onCancel = () async {
          await inner?.cancel();
          await outer.cancel();
        };
      },
    );
    return out.stream;
  };

  Future<void> _onLoadRequested(
    TasksLoadRequested event,
    Emitter<TasksState> emit,
  ) async {
    LoggerService.instance.info(
      'Loading tasks',
      data: {'operation': 'tasks.loadTasks'},
    );
    emit(state.copyWith(status: TasksStatus.loading));
    var first = true;

    await emit.onEach<List<TaskEntity>>(
      _watchTasks(),
      onData: (tasks) {
        final visible = _applyLocalChanges(tasks);
        emit(state.copyWith(status: TasksStatus.loaded, tasks: visible));
        if (first) {
          first = false;
          unawaited(_notifyLoaded(visible));
        }
      },
      onError: (error, _) {
        LoggerService.instance.error(
          'Failed to load tasks',
          data: {'operation': 'tasks.loadTasks', 'error': error.toString()},
        );
        emit(
          state.copyWith(
            status: TasksStatus.error,
            errorMessage: _message(error),
          ),
        );
      },
    );
  }

  /// Hides a pending deletion and keeps unconfirmed status changes.
  List<TaskEntity> _applyLocalChanges(List<TaskEntity> tasks) {
    final hidden = state.pendingDeletion?.id;
    return [
      for (final t in tasks)
        if (t.id != hidden)
          if (_optimisticStatus[t.id] case final status?)
            t.copyWith(status: status)
          else
            t,
    ];
  }

  Future<void> _notifyLoaded(List<TaskEntity> tasks) async {
    final userId = _user.id;
    if (userId == null) return;
    final now = _now();
    await _reminders.tasksLoaded(
      tasks,
      streak: Streak.forTasks(tasks, userId, now),
      completedToday: Streak.completedToday(tasks, userId, now),
    );
  }

  void _onFilterChanged(TasksFilterChanged event, Emitter<TasksState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _onCreateRequested(
    TaskCreateRequested event,
    Emitter<TasksState> emit,
  ) async {
    final draft = TaskDraft(
      title: event.title,
      description: event.description,
      priority: event.priority,
      startDate: event.startDate,
      dueDate: event.dueDate,
      sharedWithIds: event.sharedWith,
    );
    final result = await _createTask(draft);
    // The realtime stream brings the new task into the list.
    await result.fold(
      (failure) async => _fail(emit, 'tasks.createTask', failure),
      (task) => _reminders.taskCreated(task, [...state.tasks, task]),
    );
  }

  Future<void> _onEditRequested(
    TaskEditRequested event,
    Emitter<TasksState> emit,
  ) async {
    final current = _find(event.taskId);
    final draft = TaskDraft(
      title: event.title,
      description: event.description,
      priority: event.priority ?? current?.priority ?? TaskPriority.medium,
      startDate: event.startDate ?? current?.startDate,
      dueDate: event.dueDate ?? current?.dueDate,
      sharedWithIds: event.sharedWith,
    );
    final result = await _updateTask(event.taskId, draft);
    result.fold((f) => _fail(emit, 'tasks.editTask', f), (_) {});
  }

  Future<void> _onStatusToggled(
    TaskStatusToggled event,
    Emitter<TasksState> emit,
  ) async {
    final task = _find(event.taskId);
    if (task == null) return;
    final completing = task.status != TaskStatus.completed;
    final userId = _user.id;
    final now = _now();
    final hadCompletedToday =
        userId != null && Streak.completedToday(state.tasks, userId, now);

    // Optimistic: the row flips now; the server confirms later.
    final updated = task.copyWith(
      status: completing ? TaskStatus.completed : TaskStatus.pending,
      completedAt: completing ? now : null,
    );
    _optimisticStatus[task.id] = updated.status;
    emit(state.copyWith(tasks: _replace(updated)));

    final result = await _setCompleted(task.id, completed: completing);
    _optimisticStatus.remove(task.id);

    if (result.isLeft()) {
      emit(state.copyWith(tasks: _replace(task)));
      return result.fold((f) => _fail(emit, 'tasks.toggleStatus', f), (_) {});
    }

    if (!completing) {
      emit(state.copyWith(streakToCelebrate: null));
      return;
    }
    await _reminders.taskCompleted(task.id);
    if (userId != null && !hadCompletedToday) {
      final streak = Streak.forTasks(state.tasks, userId, now);
      await _reminders.streakExtended(streak);
      emit(state.copyWith(streakToCelebrate: streak));
    }
  }

  void _onDeleted(TaskDeleted event, Emitter<TasksState> emit) {
    final task = _find(event.taskId);
    if (task == null) return;
    // Only one deletion is undoable at a time; commit the previous one.
    _commitPending();
    emit(
      state.copyWith(
        tasks: state.tasks.where((t) => t.id != task.id).toList(),
        pendingDeletion: task,
      ),
    );
    _undoTimer = Timer(_undoAfter, () => add(_TaskDeletionCommitted(task)));
  }

  void _onDeleteUndone(TaskDeleteUndone event, Emitter<TasksState> emit) {
    final task = state.pendingDeletion;
    if (task == null) return;
    _undoTimer?.cancel();
    emit(
      state.copyWith(
        tasks: _sorted([...state.tasks, task]),
        pendingDeletion: null,
      ),
    );
  }

  Future<void> _onDeletionCommitted(
    _TaskDeletionCommitted event,
    Emitter<TasksState> emit,
  ) async {
    final task = event.task;
    if (state.pendingDeletion?.id == task.id) {
      emit(state.copyWith(pendingDeletion: null));
    }
    final result = await _deleteTask(task.id);
    await result.fold((failure) async {
      // Put it back so nothing silently disappears.
      emit(state.copyWith(tasks: _sorted([...state.tasks, task])));
      _fail(emit, 'tasks.deleteTask', failure);
    }, (_) => _reminders.taskDeleted(task.id));
  }

  /// Commits the undoable deletion now (a new deletion, or closing).
  void _commitPending() {
    final pending = state.pendingDeletion;
    if (pending == null) return;
    _undoTimer?.cancel();
    add(_TaskDeletionCommitted(pending));
  }

  void _onClearStreakCelebration(
    TasksClearStreakCelebration event,
    Emitter<TasksState> emit,
  ) {
    emit(state.copyWith(streakToCelebrate: null));
  }

  TaskEntity? _find(String id) {
    for (final t in state.tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<TaskEntity> _replace(TaskEntity task) => [
    for (final t in state.tasks)
      if (t.id == task.id) task else t,
  ];

  /// Newest first, as the server returns them.
  static List<TaskEntity> _sorted(List<TaskEntity> tasks) =>
      tasks..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void _fail(Emitter<TasksState> emit, String operation, Failure failure) {
    LoggerService.instance.error(
      'Task operation failed',
      data: {'operation': operation, 'error': failure.message},
    );
    emit(state.copyWith(errorMessage: failure.message));
  }

  static String _message(Object error) =>
      error is Failure ? error.message : error.toString();

  @override
  Future<void> close() async {
    _undoTimer?.cancel();
    final pending = state.pendingDeletion;
    // Leaving the screen ends the undo window: delete for real.
    if (pending != null) unawaited(_deleteTask(pending.id).then((_) {}));
    return super.close();
  }
}
