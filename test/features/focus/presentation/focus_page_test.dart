import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/features/focus/domain/focus_session.dart';
import 'package:kairotasks/features/focus/presentation/cubit/focus_cubit.dart';
import 'package:kairotasks/features/focus/presentation/cubit/focus_state.dart';
import 'package:kairotasks/features/focus/presentation/pages/focus_page.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:kairotasks/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

class MockFocusCubit extends MockCubit<FocusState> implements FocusCubit {}

void main() {
  final now = DateTime(2026, 10, 21, 10);
  final task = TaskEntity(
    id: 't1',
    ownerId: 'me',
    title: 'Write report',
    dueDate: DateTime(2026, 10, 21, 16),
    createdAt: DateTime(2026),
  );
  late MockFocusCubit focus;
  late MockTasksBloc tasks;

  setUpAll(() => registerFallbackValue(const TasksLoadRequested()));

  Future<void> pump(WidgetTester tester, FocusState state) {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    focus = MockFocusCubit();
    when(() => focus.state).thenReturn(state);
    tasks = MockTasksBloc();
    when(() => tasks.state)
        .thenReturn(TasksState(status: TasksStatus.loaded, tasks: [task]));
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.golden(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: BlocProvider<TasksBloc>.value(
          value: tasks,
          child: FocusPage(cubit: focus),
        ),
      ),
    );
  }

  testWidgets('without a task it asks what to focus on', (tester) async {
    await pump(tester, FocusState(now: now));

    expect(find.text('What will you focus on?'), findsOneWidget);
    await tester.tap(find.text('Write report'));
    verify(() => focus.choose(task)).called(1);

    await tester.tap(find.text('Just focus'));
    verify(() => focus.choose(null)).called(1);
  });

  testWidgets('a running round shows the countdown and can pause', (
    tester,
  ) async {
    final session = const FocusSession().start(
      now.subtract(const Duration(minutes: 10)),
    );
    await pump(
      tester,
      FocusState(now: now, session: session, task: task, chosen: true),
    );

    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text("Breathe. You're doing well."), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Pause'));
    verify(() => focus.toggle()).called(1);
    await tester.tap(find.bySemanticsLabel('Add 5 minutes'));
    verify(() => focus.addExtra()).called(1);
  });

  testWidgets('a finished round offers a rest or completing the task', (
    tester,
  ) async {
    final session = const FocusSession().start(
      now.subtract(FocusSession.focusLength),
    );
    await pump(
      tester,
      FocusState(now: now, session: session, task: task, chosen: true),
    );

    expect(find.text('Take a rest'), findsOneWidget);
    await tester.tap(find.text('Complete task'));
    final events = verify(() => tasks.add(captureAny())).captured;
    expect((events.single as TaskStatusToggled).taskId, 't1');
    verify(() => focus.next()).called(1);
  });
}
