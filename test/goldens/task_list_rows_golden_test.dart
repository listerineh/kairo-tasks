import 'package:flutter/material.dart';
import 'package:kairotasks/core/widgets/grouped_section.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/widgets/task_row.dart';

import '../helpers/golden.dart';

void main() {
  final now = DateTime(2026, 10, 20, 15);

  TaskEntity task(
    String title, {
    DateTime? start,
    DateTime? due,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.pending,
    List<Map<String, dynamic>> sharedWith = const [],
  }) => TaskEntity(
    id: title,
    ownerId: 'me',
    title: title,
    startDate: start,
    dueDate: due,
    priority: priority,
    status: status,
    sharedWith: sharedWith,
    createdAt: DateTime(2026),
  );

  final tasks = [
    task(
      'Call the dentist',
      start: DateTime(2026, 10, 20, 10),
      due: DateTime(2026, 10, 20, 10, 30),
      priority: TaskPriority.urgent,
      sharedWith: [
        {'display_name': 'Ana'},
      ],
    ),
    task('Pay rent', due: DateTime(2026, 10, 18), priority: TaskPriority.high),
    task('Plan the trip', due: DateTime(2026, 10, 21, 9)),
    task('Read a chapter', priority: TaskPriority.low),
    task('Water the plants', status: TaskStatus.completed),
  ];

  goldenTest(
    'task_list_rows',
    size: const Size(390, 360),
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: GoldenCanvas(
        child: GroupedSection(
          header: 'Today',
          separatorInset: TaskRow.separatorInset,
          children: [
            for (final t in tasks) TaskRow(task: t, now: now, onToggle: () {}),
          ],
        ),
      ),
    ),
  );
}
