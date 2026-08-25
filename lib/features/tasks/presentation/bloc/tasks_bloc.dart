import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class TaskDeleted extends TasksEvent {
  const TaskDeleted(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
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

  List<TaskEntity> get filteredTasks {
    switch (filter) {
      case TasksFilter.all:
        return tasks.where((t) => t.status != TaskStatus.completed).toList();
      case TasksFilter.urgent:
        return tasks
            .where(
              (t) =>
                  t.priority == TaskPriority.urgent &&
                  t.status != TaskStatus.completed,
            )
            .toList();
      case TasksFilter.high:
        return tasks
            .where(
              (t) =>
                  t.priority == TaskPriority.high &&
                  t.status != TaskStatus.completed,
            )
            .toList();
      case TasksFilter.medium:
        return tasks
            .where(
              (t) =>
                  t.priority == TaskPriority.medium &&
                  t.status != TaskStatus.completed,
            )
            .toList();
      case TasksFilter.low:
        return tasks
            .where(
              (t) =>
                  t.priority == TaskPriority.low &&
                  t.status != TaskStatus.completed,
            )
            .toList();
      case TasksFilter.completed:
        return tasks
            .where((t) => t.status == TaskStatus.completed)
            .toList();
    }
  }

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
      errorMessage: errorMessage ?? this.errorMessage,
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
    on<TaskStatusToggled>(_onStatusToggled);
    on<TaskDeleted>(_onDeleted);
  }

  Future<void> _onLoadRequested(
    TasksLoadRequested event,
    Emitter<TasksState> emit,
  ) async {
    emit(state.copyWith(status: TasksStatus.loading));

    // TODO: Replace with actual repository call
    // For now, emit demo data
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit(
      state.copyWith(
        status: TasksStatus.loaded,
        tasks: _demoTasks,
      ),
    );
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
    final newTask = TaskEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ownerId: 'current-user',
      title: event.title,
      description: event.description,
      priority: event.priority,
      createdAt: DateTime.now(),
      dueDate: event.dueDate,
    );

    emit(state.copyWith(tasks: [...state.tasks, newTask]));
  }

  void _onStatusToggled(
    TaskStatusToggled event,
    Emitter<TasksState> emit,
  ) {
    final updatedTasks = state.tasks.map((task) {
      if (task.id == event.taskId) {
        return TaskEntity(
          id: task.id,
          ownerId: task.ownerId,
          title: task.title,
          description: task.description,
          priority: task.priority,
          status: task.status == TaskStatus.completed
              ? TaskStatus.pending
              : TaskStatus.completed,
          dueDate: task.dueDate,
          createdAt: task.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return task;
    }).toList();

    emit(state.copyWith(tasks: updatedTasks));
  }

  void _onDeleted(
    TaskDeleted event,
    Emitter<TasksState> emit,
  ) {
    final updatedTasks =
        state.tasks.where((task) => task.id != event.taskId).toList();
    emit(state.copyWith(tasks: updatedTasks));
  }
}

// Demo data for initial development
final _demoTasks = [
  TaskEntity(
    id: '1',
    ownerId: 'user-1',
    title: 'Design the onboarding flow',
    description: 'Create wireframes and high-fidelity mockups for the app onboarding experience',
    priority: TaskPriority.high,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    dueDate: DateTime.now().add(const Duration(days: 3)),
  ),
  TaskEntity(
    id: '2',
    ownerId: 'user-1',
    title: 'Set up Supabase project',
    description: 'Configure auth, database tables, and RLS policies',
    priority: TaskPriority.urgent,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    dueDate: DateTime.now().add(const Duration(days: 1)),
  ),
  TaskEntity(
    id: '3',
    ownerId: 'user-1',
    title: 'Write unit tests for task bloc',
    priority: TaskPriority.medium,
    createdAt: DateTime.now(),
    dueDate: DateTime.now().add(const Duration(days: 5)),
  ),
  TaskEntity(
    id: '4',
    ownerId: 'user-1',
    title: 'Research accessibility guidelines',
    description: 'Look into WCAG 2.2 AA standards for ADHD-friendly interfaces',
    priority: TaskPriority.low,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  TaskEntity(
    id: '5',
    ownerId: 'user-1',
    title: 'Review PR from teammate',
    priority: TaskPriority.medium,
    createdAt: DateTime.now(),
    dueDate: DateTime.now().add(const Duration(days: 2)),
  ),
];
