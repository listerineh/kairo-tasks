import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kairotasks/features/dashboard/presentation/pages/today_page.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/golden.dart';
import '../helpers/mocks.dart';

void main() {
  final now = DateTime(2026, 10, 21, 10, 40);
  DateTime at(int h, [int m = 0, int d = 21]) => DateTime(2026, 10, d, h, m);

  TaskEntity task(
    String id,
    String title, {
    DateTime? due,
    DateTime? completedAt,
    TaskPriority priority = TaskPriority.medium,
  }) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: title,
    dueDate: due,
    priority: priority,
    status: completedAt == null ? TaskStatus.pending : TaskStatus.completed,
    completedAt: completedAt,
    createdAt: DateTime(2026),
  );

  final tasks = [
    task('1', 'Call the dentist', due: at(11), priority: TaskPriority.urgent),
    task('2', 'Write the Q3 report', due: at(16), priority: TaskPriority.high),
    task('3', 'Pay rent', due: at(9, 0, 19)),
    task('4', 'Buy coffee', due: at(0), priority: TaskPriority.low),
    task('5', 'Walk 20 minutes', due: at(8), completedAt: at(8, 30)),
    task('6', 'Yoga', due: at(7), completedAt: at(7, 45, 20)),
  ];

  goldenTest(
    'today_page',
    size: const Size(390, 1100),
    builder: (context) {
      final bloc = MockTasksBloc();
      when(() => bloc.state)
          .thenReturn(TasksState(status: TasksStatus.loaded, tasks: tasks));
      // Reduced motion freezes the cat and the entrance cascade.
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: BlocProvider<TasksBloc>.value(
          value: bloc,
          child: TodayPage(now: () => now, currentUserId: 'me'),
        ),
      );
    },
  );
}
