import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/core/widgets/check_circle.dart';
import 'package:kairotasks/features/dashboard/presentation/pages/today_page.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:kairotasks/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  final now = DateTime(2026, 10, 21, 10, 40);
  DateTime at(int h, [int m = 0, int d = 21]) => DateTime(2026, 10, d, h, m);
  late MockTasksBloc bloc;

  setUpAll(() => registerFallbackValue(const TasksLoadRequested()));

  TaskEntity task(
    String id,
    String title, {
    DateTime? due,
    DateTime? completedAt,
  }) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: title,
    dueDate: due,
    status: completedAt == null ? TaskStatus.pending : TaskStatus.completed,
    completedAt: completedAt,
    createdAt: DateTime(2026),
  );

  final busyDay = [
    task('1', 'Call the dentist', due: at(11)),
    task('2', 'Write report', due: at(16)),
    task('3', 'Pay rent', due: at(9, 0, 19)),
    task('4', 'Walk', due: at(8), completedAt: at(8, 30)),
  ];

  Future<void> pump(
    WidgetTester tester,
    List<TaskEntity> tasks, {
    TasksStatus status = TasksStatus.loaded,
  }) {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    bloc = MockTasksBloc();
    when(() => bloc.state).thenReturn(TasksState(status: status, tasks: tasks));
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.golden(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The cat and the entrance cascade hold still.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: BlocProvider<TasksBloc>.value(
          value: bloc,
          child: TodayPage(now: () => now, currentUserId: 'me'),
        ),
      ),
    );
  }

  testWidgets('shows the day: greeting, suggestion, metrics and "now"', (
    tester,
  ) async {
    await pump(tester, busyDay);

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Kairo suggests'), findsOneWidget);
    expect(
      find.textContaining('Start with “Call the dentist”'),
      findsOneWidget,
    );
    expect(find.text('1 of 4 done'), findsOneWidget);
    // Streak, overdue and progress.
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('overdue'), findsOneWidget);
    // "Now" card: the dentist is in 20 minutes.
    expect(find.text('In 20 min'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
  });

  testWidgets('lists overdue and today, and checking one completes it', (
    tester,
  ) async {
    await pump(tester, busyDay);

    expect(find.text('To do'), findsOneWidget);
    expect(find.text('3 left'), findsOneWidget);
    expect(find.text('Pay rent'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    // Done tasks stay folded until asked for.
    expect(find.text('Walk'), findsNothing);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CheckCircle && w.semanticLabel == 'Write report',
      ),
    );
    await tester.pump();
    final events = verify(() => bloc.add(captureAny())).captured;
    expect(events.whereType<TaskStatusToggled>().single.taskId, '2');
  });

  testWidgets('"Done" unfolds today\'s completed tasks', (tester) async {
    await pump(tester, busyDay);

    await tester.scrollUntilVisible(find.text('Done · 1'), 200);
    await tester.tap(find.text('Done · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Walk'), findsOneWidget);
  });

  testWidgets('tapping Kairo shows the next suggestion', (tester) async {
    await pump(tester, busyDay);

    await tester.tap(find.byType(KairoMascot));
    await tester.pump();
    expect(find.textContaining("You've done 1 of 4"), findsOneWidget);
    // Let the "meow" bubble expire.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('an empty day invites to plan or rest', (tester) async {
    await pump(tester, []);

    expect(find.textContaining('Nothing planned today'), findsOneWidget);
    expect(find.text('Nothing for today'), findsOneWidget);
    expect(find.text('In 20 min'), findsNothing);
  });

  testWidgets('a failed load says so and offers a retry', (tester) async {
    await pump(tester, [], status: TasksStatus.error);

    expect(find.textContaining('Nothing planned today'), findsNothing);
    await tester.tap(find.text('Try again'));
    final events = verify(() => bloc.add(captureAny())).captured;
    expect(events.single, isA<TasksLoadRequested>());
  });
}
