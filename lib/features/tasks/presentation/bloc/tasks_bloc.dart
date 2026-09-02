import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/logger_service.dart';
import '../../../../core/services/notification_service.dart';
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
  List<Object?> get props =>
      [title, description, priority, startDate, dueDate, sharedWith];
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
  List<Object?> get props =>
      [taskId, title, description, priority, startDate, dueDate, sharedWith];
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

class _TasksReloadFromStream extends TasksEvent {
  const _TasksReloadFromStream();
}

class TasksClearStreakCelebration extends TasksEvent {
  const TasksClearStreakCelebration();
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
  });

  final List<TaskEntity> tasks;
  final TasksStatus status;
  final TasksFilter filter;
  final String? errorMessage;
  final int? streakToCelebrate;

  static const Object _streakUndefined = _Undefined();

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
    Object? streakToCelebrate = _streakUndefined,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      status: status ?? this.status,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
      streakToCelebrate: identical(streakToCelebrate, _streakUndefined)
          ? this.streakToCelebrate
          : streakToCelebrate as int?,
    );
  }

  @override
  List<Object?> get props => [tasks, status, filter, errorMessage, streakToCelebrate];
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
    on<_TasksReloadFromStream>(_onReloadFromStream);
    on<TasksClearStreakCelebration>(_onClearStreakCelebration);
  }

  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  StreamSubscription<List<Map<String, dynamic>>>? _sharedSubscription;

  Future<List<TaskEntity>> _fetchTasks() async {
    final response = await _client
        .from('tasks')
        .select('''
          *,
          shared_tasks!task_id(
            task_id,
            shared_by_id,
            shared_with_id,
            shared_with:profiles!shared_with_id(id, username, display_name, avatar_url),
            shared_by:profiles!shared_by_id(id, username, display_name, avatar_url)
          )
        ''')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => _taskFromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _onLoadRequested(
    TasksLoadRequested event,
    Emitter<TasksState> emit,
  ) async {
    LoggerService.instance.info(
      'Loading tasks',
      data: {'operation': 'tasks.loadTasks'},
    );
    emit(state.copyWith(status: TasksStatus.loading));

    try {
      final tasks = await _fetchTasks();
      emit(state.copyWith(status: TasksStatus.loaded, tasks: tasks));
      LoggerService.instance.info(
        'Tasks loaded',
        data: {'operation': 'tasks.loadTasks', 'count': tasks.length},
      );
      await NotificationService.instance.rescheduleMorningSummary(tasks);

      final today = _dateOnly(DateTime.now());
      final streak = _streakFromDays(
        tasks
            .where(
              (t) =>
                  t.status == TaskStatus.completed &&
                  t.ownerId == _userId,
            )
            .map(
              (t) => _dateOnly(
                t.completedAt ?? t.updatedAt ?? t.createdAt,
              ),
            )
            .where((d) => !d.isAfter(today))
            .toList(),
        today,
      );
      final completedTodayCount = tasks.where((t) {
        if (t.status != TaskStatus.completed || t.ownerId != _userId) {
          return false;
        }
        return _isSameDay(t.completedAt ?? t.updatedAt ?? t.createdAt, today);
      }).length;
      await NotificationService.instance.rescheduleStreakReminders(
        streak: streak,
        hasCompletedToday: completedTodayCount > 0,
      );

      // Subscribe to realtime changes on tasks
      await _subscription?.cancel();
      _subscription = _client
          .from('tasks')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((data) {
            final updatedTasks = data.map(_taskFromJson).toList();
            add(_TasksUpdatedFromStream(updatedTasks));
          });

      // Subscribe to shared_tasks to catch new shares from friends
      await _sharedSubscription?.cancel();
      _sharedSubscription = _client
          .from('shared_tasks')
          .stream(primaryKey: ['id'])
          .eq('shared_with_id', _userId)
          .order('created_at', ascending: false)
          .listen((_) => add(const _TasksReloadFromStream()));
    } catch (e) {
      LoggerService.instance.error(
        'Failed to load tasks',
        data: {'operation': 'tasks.loadTasks', 'error': e.toString()},
      );
      emit(
        state.copyWith(
          status: TasksStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onReloadFromStream(
    _TasksReloadFromStream event,
    Emitter<TasksState> emit,
  ) async {
    try {
      final tasks = await _fetchTasks();
      emit(state.copyWith(tasks: tasks, status: TasksStatus.loaded));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to reload shared tasks: $e'));
    }
  }

  void _onStreamUpdate(
    _TasksUpdatedFromStream event,
    Emitter<TasksState> emit,
  ) {
    final previousMap = {for (final t in state.tasks) t.id: t};
    final mergedTasks = event.tasks.map((task) {
      if (task.sharedWith.isNotEmpty) return task;
      final previous = previousMap[task.id];
      if (previous != null && previous.sharedWith.isNotEmpty) {
        return task.copyWith(sharedWith: previous.sharedWith);
      }
      return task;
    }).toList();
    emit(state.copyWith(tasks: mergedTasks, status: TasksStatus.loaded));
  }

  void _onClearStreakCelebration(
    TasksClearStreakCelebration event,
    Emitter<TasksState> emit,
  ) {
    emit(state.copyWith(streakToCelebrate: null));
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
    LoggerService.instance.info(
      'Creating task',
      data: {
        'operation': 'tasks.createTask',
        'title': event.title,
        'priority': event.priority.name,
        'status': 'pending',
      },
    );

    try {
      final result = await _client
          .from('tasks')
          .insert({
            'owner_id': _userId,
            'title': event.title,
            if (event.description != null) 'description': event.description,
            'priority': event.priority.name,
            'status': 'pending',
            if (event.startDate != null)
              'start_date': event.startDate!.toUtc().toIso8601String(),
            if (event.dueDate != null)
              'due_date': event.dueDate!.toUtc().toIso8601String(),
          })
          .select('id')
          .single();

      final taskId = result['id'] as String;

      if (event.sharedWith != null && event.sharedWith!.isNotEmpty) {
        final records = event.sharedWith!
            .where((id) => id != _userId)
            .map((id) => {
                  'task_id': taskId,
                  'shared_by_id': _userId,
                  'shared_with_id': id,
                })
            .toList();
        if (records.isNotEmpty) {
          await _client.from('shared_tasks').insert(records);
        }
      }

      final createdTask = TaskEntity(
        id: taskId,
        ownerId: _userId,
        title: event.title,
        description: event.description,
        priority: event.priority,
        status: TaskStatus.pending,
        startDate: event.startDate,
        dueDate: event.dueDate,
        createdAt: DateTime.now(),
      );
      await NotificationService.instance.scheduleTaskReminder(createdTask);
      await NotificationService.instance.rescheduleInactivityNudge([
        ...state.tasks,
        createdTask,
      ]);

      if (createdTask.priority == TaskPriority.urgent) {
        await NotificationService.instance.showUrgentNotification(createdTask);
      }

      // Realtime stream will update the list automatically
    } catch (e) {
      LoggerService.instance.error(
        'Failed to create task',
        data: {
          'operation': 'tasks.createTask',
          'title': event.title,
          'priority': event.priority.name,
          'status': 'pending',
          'error': e.toString(),
        },
      );
      emit(state.copyWith(errorMessage: 'Failed to create task: $e'));
    }
  }

  Future<void> _onEditRequested(
    TaskEditRequested event,
    Emitter<TasksState> emit,
  ) async {
    LoggerService.instance.info(
      'Editing task',
      data: {'operation': 'tasks.editTask', 'task_id': event.taskId},
    );

    try {
      await _client.from('tasks').update({
        'title': event.title,
        'description': event.description,
        if (event.priority != null) 'priority': event.priority!.name,
        if (event.startDate != null)
          'start_date': event.startDate!.toUtc().toIso8601String(),
        if (event.dueDate != null)
          'due_date': event.dueDate!.toUtc().toIso8601String(),
      }).eq('id', event.taskId);

      if (event.sharedWith != null) {
        final current = await _client
            .from('shared_tasks')
            .select('shared_with_id')
            .eq('task_id', event.taskId)
            .eq('shared_by_id', _userId);
        final currentRows = (current as List).cast<Map<String, dynamic>>();
        final currentIds = currentRows
            .map((r) => r['shared_with_id'] as String)
            .toSet();
        final desiredIds = event.sharedWith!.toSet();
        final toAdd = desiredIds.difference(currentIds).toList();
        final toRemove = currentIds.difference(desiredIds).toList();

        if (toAdd.isNotEmpty) {
          final records = toAdd
              .where((id) => id != _userId)
              .map((id) => {
                    'task_id': event.taskId,
                    'shared_by_id': _userId,
                    'shared_with_id': id,
                  })
              .toList();
          if (records.isNotEmpty) {
            await _client.from('shared_tasks').insert(records);
          }
        }

        if (toRemove.isNotEmpty) {
          await _client
              .from('shared_tasks')
              .delete()
              .eq('task_id', event.taskId)
              .filter('shared_with_id', 'in', toRemove);
        }
      }

      final tasks = await _fetchTasks();
      emit(
        state.copyWith(
          status: TasksStatus.loaded,
          tasks: tasks,
          errorMessage: null,
        ),
      );
    } catch (e) {
      LoggerService.instance.error(
        'Failed to edit task',
        data: {
          'operation': 'tasks.editTask',
          'task_id': event.taskId,
          'error': e.toString(),
        },
      );
      emit(state.copyWith(errorMessage: 'Failed to edit task: $e'));
    }
  }

  Future<void> _onStatusToggled(
    TaskStatusToggled event,
    Emitter<TasksState> emit,
  ) async {
    final task = state.tasks.firstWhere((t) => t.id == event.taskId);
    final previousStatus = task.status;
    final newStatus =
        previousStatus == TaskStatus.completed ? 'pending' : 'completed';
    final today = _dateOnly(DateTime.now());
    final wasCompletedTodayBefore = state.tasks.any((t) {
      if (t.id == event.taskId ||
          t.status != TaskStatus.completed ||
          t.ownerId != _userId) {
        return false;
      }
      return _isSameDay(t.completedAt ?? t.updatedAt ?? t.createdAt, today);
    });

    LoggerService.instance.info(
      'Toggling task status',
      data: {
        'operation': 'tasks.toggleStatus',
        'task_id': event.taskId,
        'new_status': newStatus,
      },
    );

    try {
      await _client
          .from('tasks')
          .update({'status': newStatus})
          .eq('id', event.taskId);
      if (newStatus == 'completed') {
        await NotificationService.instance.cancelTaskReminder(event.taskId);
        if (!wasCompletedTodayBefore) {
          final days = <DateTime>{today};
          for (final t in state.tasks) {
            if (t.ownerId != _userId || t.status != TaskStatus.completed) {
              continue;
            }
            final d = _dateOnly(t.completedAt ?? t.updatedAt ?? t.createdAt);
            if (!d.isAfter(today)) days.add(d);
          }
          final newStreak = _streakFromDays(days.toList(), today);
          LoggerService.instance.info(
            'Streak celebration triggered',
            data: {
              'operation': 'tasks.streak',
              'streak': newStreak,
            },
          );
          await NotificationService.instance.showStreakNotification(newStreak);
          emit(state.copyWith(streakToCelebrate: newStreak));
        }
      } else if (newStatus == 'pending' &&
          previousStatus == TaskStatus.completed) {
        emit(state.copyWith(streakToCelebrate: null));
      }
    } catch (e) {
      LoggerService.instance.error(
        'Failed to toggle task status',
        data: {
          'operation': 'tasks.toggleStatus',
          'task_id': event.taskId,
          'new_status': newStatus,
          'error': e.toString(),
        },
      );
      emit(state.copyWith(errorMessage: 'Failed to update task: $e'));
    }
  }

  Future<void> _onDeleted(
    TaskDeleted event,
    Emitter<TasksState> emit,
  ) async {
    LoggerService.instance.info(
      'Deleting task',
      data: {'operation': 'tasks.deleteTask', 'task_id': event.taskId},
    );

    try {
      await _client.from('tasks').delete().eq('id', event.taskId);
      await NotificationService.instance.cancelTaskReminder(event.taskId);
    } catch (e) {
      LoggerService.instance.error(
        'Failed to delete task',
        data: {
          'operation': 'tasks.deleteTask',
          'task_id': event.taskId,
          'error': e.toString(),
        },
      );
      emit(state.copyWith(errorMessage: 'Failed to delete task: $e'));
    }
  }

  TaskEntity _taskFromJson(Map<String, dynamic> json) {
    final sharedWith = <Map<String, dynamic>>[];
    final sharedTasks = json['shared_tasks'] as List<dynamic>?;
    if (sharedTasks != null) {
      for (final item in sharedTasks) {
        final share = item as Map<String, dynamic>;
        final sharedById = share['shared_by_id'] as String?;
        final sharedWithId = share['shared_with_id'] as String?;
        final profile = sharedById == _userId
            ? share['shared_with'] as Map<String, dynamic>?
            : (sharedWithId == _userId
                ? share['shared_by'] as Map<String, dynamic>?
                : null);
        if (profile != null) {
          sharedWith.add(profile);
        }
      }
    }

    return TaskEntity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: _parsePriority(json['priority'] as String? ?? 'medium'),
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String).toLocal()
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String).toLocal()
          : null,
      sharedWith: sharedWith,
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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) => _dateOnly(a) == _dateOnly(b);

  int _streakFromDays(List<DateTime> days, DateTime today) {
    if (days.isEmpty) return 0;
    final unique = days.map(_dateOnly).toSet();
    final sorted = unique.toList()..sort((a, b) => b.compareTo(a));
    final yesterday = today.subtract(const Duration(days: 1));
    if (sorted.first != today && sorted.first != yesterday) return 0;

    var count = 0;
    var expected = sorted.first;
    for (final d in sorted) {
      if (d == expected) {
        count++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (d.isBefore(expected)) {
        break;
      }
    }
    return count;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _sharedSubscription?.cancel();
    return super.close();
  }
}
