import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kairotasks/features/focus/domain/focus_session.dart';
import 'package:kairotasks/features/focus/presentation/cubit/focus_cubit.dart';
import 'package:kairotasks/features/focus/presentation/cubit/focus_state.dart';
import 'package:kairotasks/features/focus/presentation/pages/focus_page.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/golden.dart';
import '../helpers/mocks.dart';

class _MockFocusCubit extends MockCubit<FocusState> implements FocusCubit {}

void main() {
  final now = DateTime(2026, 10, 21, 10);
  final task = TaskEntity(
    id: 't1',
    ownerId: 'me',
    title: 'Write the Q3 report',
    dueDate: DateTime(2026, 10, 21, 16),
    createdAt: DateTime(2026),
  );

  Widget page(FocusState state) {
    final focus = _MockFocusCubit();
    when(() => focus.state).thenReturn(state);
    final tasks = MockTasksBloc();
    when(() => tasks.state)
        .thenReturn(TasksState(status: TasksStatus.loaded, tasks: [task]));
    return Builder(
      // Kairo and the halo hold still under reduced motion.
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: BlocProvider<TasksBloc>.value(
          value: tasks,
          child: FocusPage(cubit: focus),
        ),
      ),
    );
  }

  goldenTest(
    'focus_running',
    size: const Size(390, 844),
    builder: (_) => page(
      FocusState(
        now: now,
        // Round 2, 7 min 18 s in.
        session: const FocusSession(round: 2)
            .start(now.subtract(const Duration(minutes: 7, seconds: 18))),
        task: task,
        chosen: true,
      ),
    ),
  );

  goldenTest(
    'focus_picker',
    size: const Size(390, 844),
    builder: (_) => page(FocusState(now: now)),
  );
}
