import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kairotasks/core/errors/failures.dart';
import 'package:kairotasks/features/social/domain/entities/friend.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:kairotasks/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/golden.dart';
import '../helpers/mocks.dart';

void main() {
  final now = DateTime(2026, 10, 20, 15);

  Widget form({TaskEntity? task}) {
    final bloc = MockTasksBloc();
    when(() => bloc.state).thenReturn(const TasksState());
    return BlocProvider<TasksBloc>.value(
      value: bloc,
      child: Scaffold(
        body: TaskFormSheet(
          task: task,
          now: now,
          currentUserId: 'me',
          loadFriends: () async => const Right<Failure, List<Friend>>([
            Friend(id: 'ana', displayName: 'Ana Torres'),
            Friend(id: 'luis', username: 'luis'),
          ]),
        ),
      ),
    );
  }

  goldenTest(
    'task_form_new',
    size: const Size(390, 420),
    builder: (_) => form(),
  );

  goldenTest(
    'task_form_edit',
    size: const Size(390, 900),
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: form(
        task: TaskEntity(
          id: 't1',
          ownerId: 'me',
          title: 'Call the dentist',
          description: 'Ask about the cleaning',
          priority: TaskPriority.high,
          startDate: DateTime(2026, 10, 21, 10),
          dueDate: DateTime(2026, 10, 21, 10, 30),
          sharedWith: const [
            {'id': 'ana', 'display_name': 'Ana Torres'},
          ],
          createdAt: DateTime(2026),
        ),
      ),
    ),
  );
}
