import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:kairotasks/features/tasks/presentation/pages/tasks_page.dart';
import 'package:kairotasks/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockTasksBloc extends MockBloc<TasksEvent, TasksState>
    implements TasksBloc {}

void main() {
  late MockTasksBloc bloc;
  final today = DateTime.now();

  TaskEntity task(
    String id, {
    DateTime? due,
    TaskStatus status = TaskStatus.pending,
    TaskPriority priority = TaskPriority.medium,
  }) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: 'Task $id',
    dueDate: due,
    status: status,
    priority: priority,
    createdAt: DateTime(2026),
  );

  Future<void> pump(
    WidgetTester tester,
    TasksState state, {
    Stream<TasksState>? states,
  }) {
    bloc = MockTasksBloc();
    if (states != null) {
      whenListen(bloc, states, initialState: state);
    } else {
      when(() => bloc.state).thenReturn(state);
    }
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.golden(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<TasksBloc>.value(
          value: bloc,
          child: const TasksPage(),
        ),
      ),
    );
  }

  testWidgets('groups tasks under section headers', (tester) async {
    await pump(
      tester,
      TasksState(
        status: TasksStatus.loaded,
        tasks: [
          task('1', due: DateTime(today.year, today.month, today.day, 23)),
          task('2'),
          task('3', due: DateTime(2000)),
        ],
      ),
    );

    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('No date'), findsOneWidget);
    expect(find.text('Task 1'), findsOneWidget);
  });

  testWidgets('completed tasks stay folded until asked', (tester) async {
    await pump(
      tester,
      TasksState(
        status: TasksStatus.loaded,
        tasks: [task('9', status: TaskStatus.completed)],
      ),
    );

    expect(find.text('Completed · 1'), findsOneWidget);
    expect(find.text('Task 9'), findsNothing);

    await tester.tap(find.text('Completed · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Task 9'), findsOneWidget);
  });

  testWidgets('the priority filter hides other tasks', (tester) async {
    await pump(
      tester,
      TasksState(
        status: TasksStatus.loaded,
        filter: TasksFilter.urgent,
        tasks: [
          task('u', priority: TaskPriority.urgent),
          task('l', priority: TaskPriority.low),
        ],
      ),
    );
    expect(find.text('Task u'), findsOneWidget);
    expect(find.text('Task l'), findsNothing);
  });

  testWidgets('empty list invites to create the first task', (tester) async {
    await pump(tester, const TasksState(status: TasksStatus.loaded));
    expect(find.text('All clear'), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets('a load error offers to try again', (tester) async {
    await pump(tester, const TasksState(status: TasksStatus.error));
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const TasksLoadRequested())).called(1);
  });

  testWidgets('deleting shows an undo snackbar wired to the bloc', (
    tester,
  ) async {
    final a = task('1');
    // Stub the stream before the page subscribes to it.
    await pump(
      tester,
      TasksState(status: TasksStatus.loaded, tasks: [a]),
      states: Stream.value(
        TasksState(status: TasksStatus.loaded, pendingDeletion: a),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Task deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    verify(() => bloc.add(const TaskDeleteUndone())).called(1);
  });

  testWidgets('a failed action shows plain language, never the exception', (
    tester,
  ) async {
    final a = task('1');
    await pump(
      tester,
      TasksState(status: TasksStatus.loaded, tasks: [a]),
      states: Stream.value(
        TasksState(
          status: TasksStatus.loaded,
          tasks: [a],
          errorMessage: 'PostgrestException(code: PGRST205)',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.textContaining('PostgrestException'), findsNothing);
    expect(
      find.text(
        "Something went wrong and your change wasn't saved. Please try again.",
      ),
      findsOneWidget,
    );
  });
}
