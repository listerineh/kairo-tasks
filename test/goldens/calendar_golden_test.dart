import 'package:flutter/material.dart';
import 'package:kairotasks/features/calendar/presentation/widgets/month_view.dart';
import 'package:kairotasks/features/calendar/presentation/widgets/time_grid.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';

import '../helpers/golden.dart';

void main() {
  final day = DateTime(2026, 10, 20);
  DateTime at(int h, [int m = 0, int d = 20]) => DateTime(2026, 10, d, h, m);

  TaskEntity task(
    String id,
    String title, {
    DateTime? start,
    DateTime? due,
    String color = '#3A7449',
    TaskStatus status = TaskStatus.pending,
  }) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: title,
    startDate: start,
    dueDate: due,
    color: color,
    status: status,
    createdAt: DateTime(2026),
  );

  final tasks = [
    task('1', 'Pay rent', due: day),
    task('2', 'Standup', start: at(8), due: at(8, 30)),
    task('3', 'Write report', start: at(9), due: at(11), color: '#0062CC'),
    task('4', 'Dentist', start: at(10), due: at(11), color: '#C93400'),
    task(
      '5',
      'Walk',
      start: at(12),
      due: at(12, 30),
      status: TaskStatus.completed,
    ),
    task(
      '6',
      'Ana: busy',
      start: at(9, 30, 21),
      due: at(10, 30, 21),
      color: '#AF52DE',
    ),
    task('7', 'Gym', due: at(18, 0, 3)),
    task('8', 'Call mom', due: at(19, 0, 3), color: '#0062CC'),
    task('9', 'Groceries', due: at(10, 0, 14), color: '#C93400'),
  ];

  goldenTest(
    'calendar_week_grid',
    size: const Size(390, 520),
    builder: (_) => Scaffold(
      body: TimeGrid(
        days: [day, at(0, 0, 21)],
        tasks: tasks,
        now: at(10, 40),
        initialHourHeight: 64,
        onTaskTap: (_) {},
        onCreateAt: (_) {},
        canMove: (_) => true,
        onMove: (_, _) {},
      ),
    ),
  );

  goldenTest(
    'calendar_month',
    size: const Size(390, 640),
    builder: (_) => Scaffold(
      body: MonthView(
        selectedDate: day,
        tasks: tasks,
        now: day,
        onDateTap: (_) {},
        onTaskTap: (_) {},
      ),
    ),
  );
}
