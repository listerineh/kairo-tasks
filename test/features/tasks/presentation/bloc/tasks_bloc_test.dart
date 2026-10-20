import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockSupabaseClient client;

  setUp(() => client = MockSupabaseClient());

  test('initial state is empty and unfiltered', () async {
    final bloc = TasksBloc(client);
    expect(bloc.state, const TasksState());
    await bloc.close();
  });

  blocTest<TasksBloc, TasksState>(
    'TasksFilterChanged updates the filter',
    build: () => TasksBloc(client),
    act: (bloc) => bloc.add(const TasksFilterChanged(TasksFilter.urgent)),
    expect: () => [const TasksState(filter: TasksFilter.urgent)],
  );

  group('TasksState.activeTasks', () {
    TaskEntity task(String id, TaskPriority p, TaskStatus s) => TaskEntity(
          id: id,
          ownerId: 'u1',
          title: id,
          createdAt: DateTime(2026),
          priority: p,
          status: s,
        );

    final tasks = [
      task('low', TaskPriority.low, TaskStatus.pending),
      task('urgent', TaskPriority.urgent, TaskStatus.pending),
      task('done', TaskPriority.urgent, TaskStatus.completed),
    ];

    test('hides completed tasks and sorts by priority', () {
      final state = TasksState(tasks: tasks);
      expect(state.activeTasks.map((t) => t.id), ['urgent', 'low']);
    });

    test('urgent filter keeps only pending urgent tasks', () {
      final state = TasksState(tasks: tasks, filter: TasksFilter.urgent);
      expect(state.activeTasks.map((t) => t.id), ['urgent']);
    });
  });
}
