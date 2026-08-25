import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/task_entity.dart';

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
    this.dueDate,
  });

  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueDate;

  @override
  List<Object?> get props => [title, description, priority, dueDate];
}

class TaskStatusToggled extends TasksEvent {
  const TaskStatusToggled(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class TaskEditRequested extends TasksEvent {
  const TaskEditRequested({
    required this.taskId,
    required this.title,
    this.description,
    this.priority,
    this.dueDate,
  });

  final String taskId;
  final String title;
  final String? description;
  final TaskPriority? priority;
  final DateTime? dueDate;

  @override
  List<Object?> get props => [taskId, title, description, priority, dueDate];
}

class TaskDeleted extends TasksEvent {
  const TaskDeleted(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class _TasksUpdatedFromStream extends TasksEvent {
  const _TasksUpdatedFromStream(this.tasks);
  final List<TaskEntity> tasks;

  @override
  List<Object?> get props => [tasks];
}

// Filter
enum TasksFilter { all, urgent, high, medium, low, completed }

// State
class TasksState extends Equatable {
  const TasksState({
    this.tasks = const [],
    this.status = TasksStatus.initial,
    this.filter = TasksFilter.all,
    this.errorMessage,
  });

  final List<TaskEntity> tasks;
  final TasksStatus status;
  final TasksFilter filter;
  final String? errorMessage;

  static const _priorityOrder = {
    TaskPriority.urgent: 0,
    TaskPriority.high: 1,
    TaskPriority.medium: 2,
    TaskPriority.low: 3,
  };

  /// Active (non-completed) tasks for the current filter, sorted by priority.
  List<TaskEntity> get activeTasks {
    List<TaskEntity> result;
    switch (filter) {
      case TasksFilter.all:
        result =
            tasks.where((t) => t.status != TaskStatus.completed).toList();
      case TasksFilter.urgent:
        result = tasks
            .where(
              (t) =>
                  t.priority == TaskPriority.urgent &&
                  t.status != TaskStatus.completed,
            )
            .toList();
      case TasksFilter.high:
        result = tasks
            .where(
              (t) =>
                  t.priority == TaskPriority.high &&
                  t.status != TaskStatus.completed,
            )
            .toList();
      case TasksFilter.medium:
        result = tasks
            .where(
              (t) =>
                  t.priority == TaskPriority.medium &&
                  t.status != TaskStatus.completed,
            )
            .toList();
      case TasksFilter.low:
        result = tasks
            .where(
              (t) =>
                  t.priority == TaskPriority.low &&
                  t.status != TaskStatus.completed,
            )
            .toList();
      case TasksFilter.completed:
        return [];
    }
    result.sort(
      (a, b) => (_priorityOrder[a.priority] ?? 2)
          .compareTo(_priorityOrder[b.priority] ?? 2),
    );
    return result;
  }

  /// Completed tasks, sorted by most recently completed first (updatedAt desc).
  List<TaskEntity> get completedTasks {
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).toList()
          ..sort((a, b) {
            final aDate = a.updatedAt ?? a.createdAt;
            final bDate = b.updatedAt ?? b.createdAt;
            return bDate.compareTo(aDate);
          });
    return completed;
  }

  /// Legacy getter for backward compat - returns active tasks only.
  List<TaskEntity> get filteredTasks => activeTasks;

  TasksState copyWith({
    List<TaskEntity>? tasks,
    TasksStatus? status,
    TasksFilter? filter,
    String? errorMessage,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      status: status ?? this.status,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [tasks, status, filter, errorMessage];
}

enum TasksStatus { initial, loading, loaded, error }

// BLoC
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc() : super(const TasksState()) {
    on<TasksLoadRequested>(_onLoadRequested);
    on<TasksFilterChanged>(_onFilterChanged);
    on<TaskCreateRequested>(_onCreateRequested);
    on<TaskEditRequested>(_onEditRequested);
    on<TaskStatusToggled>(_onStatusToggled);
    on<TaskDeleted>(_onDeleted);
    on<_TasksUpdatedFromStream>(_onStreamUpdate);
  }

  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  Future<void> _onLoadRequested(
    TasksLoadRequested event,
    Emitter<TasksState> emit,
  ) async {
    emit(state.copyWith(status: TasksStatus.loading));

    try {
      // Fetch initial tasks
      final response = await _client
          .from('tasks')
          .select()
          .eq('owner_id', _userId)
          .order('created_at', ascending: false);

      final tasks = (response as List)
          .map((json) => _taskFromJson(json as Map<String, dynamic>))
          .toList();

      emit(state.copyWith(status: TasksStatus.loaded, tasks: tasks));

      // Subscribe to realtime changes
      await _subscription?.cancel();
      _subscription = _client
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('owner_id', _userId)
          .order('created_at', ascending: false)
          .listen((data) {
            final updatedTasks =
                data.map(_taskFromJson).toList();
            add(_TasksUpdatedFromStream(updatedTasks));
          });
    } catch (e) {
      emit(
        state.copyWith(
          status: TasksStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onStreamUpdate(
    _TasksUpdatedFromStream event,
    Emitter<TasksState> emit,
  ) {
    emit(state.copyWith(tasks: event.tasks, status: TasksStatus.loaded));
  }

  void _onFilterChanged(
    TasksFilterChanged event,
    Emitter<TasksState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _onCreateRequested(
    TaskCreateRequested event,
    Emitter<TasksState> emit,
  ) async {
    try {
      await _client.from('tasks').insert({
        'owner_id': _userId,
        'title': event.title,
        if (event.description != null) 'description': event.description,
        'priority': event.priority.name,
        'status': 'pending',
        if (event.dueDate != null)
          'due_date': event.dueDate!.toUtc().toIso8601String(),
      });
      // Realtime stream will update the list automatically
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to create task: $e'));
    }
  }

  Future<void> _onEditRequested(
    TaskEditRequested event,
    Emitter<TasksState> emit,
  ) async {
    try {
      await _client.from('tasks').update({
        'title': event.title,
        'description': event.description,
        if (event.priority != null) 'priority': event.priority!.name,
        if (event.dueDate != null)
          'due_date': event.dueDate!.toUtc().toIso8601String(),
      }).eq('id', event.taskId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to edit task: $e'));
    }
  }

  Future<void> _onStatusToggled(
    TaskStatusToggled event,
    Emitter<TasksState> emit,
  ) async {
    final task = state.tasks.firstWhere((t) => t.id == event.taskId);
    final newStatus =
        task.status == TaskStatus.completed ? 'pending' : 'completed';

    try {
      await _client
          .from('tasks')
          .update({'status': newStatus})
          .eq('id', event.taskId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update task: $e'));
    }
  }

  Future<void> _onDeleted(
    TaskDeleted event,
    Emitter<TasksState> emit,
  ) async {
    try {
      await _client.from('tasks').delete().eq('id', event.taskId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete task: $e'));
    }
  }

  TaskEntity _taskFromJson(Map<String, dynamic> json) {
    return TaskEntity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: _parsePriority(json['priority'] as String? ?? 'medium'),
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  TaskPriority _parsePriority(String value) {
    switch (value) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  TaskStatus _parseStatus(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
