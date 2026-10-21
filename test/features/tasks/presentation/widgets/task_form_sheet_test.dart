import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/core/errors/failures.dart';
import 'package:kairotasks/features/social/domain/entities/friend.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_draft.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:kairotasks/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:kairotasks/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  // A Tuesday; "This weekend" is Saturday the 24th.
  final now = DateTime(2026, 10, 20, 15);
  const ana = Friend(id: 'ana', displayName: 'Ana Torres');
  late MockTasksBloc bloc;

  setUpAll(() => registerFallbackValue(const TasksLoadRequested()));

  setUp(() {
    bloc = MockTasksBloc();
    when(() => bloc.state).thenReturn(const TasksState());
  });

  /// Opens the form on a pushed route so saving can pop it.
  Future<void> open(
    WidgetTester tester, {
    TaskEntity? task,
    String? initialFriendId,
    String currentUserId = 'me',
    List<Friend> friends = const [ana],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.golden(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<TasksBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider<TasksBloc>.value(
                    value: bloc,
                    child: Scaffold(
                      body: TaskFormSheet(
                        task: task,
                        initialFriendId: initialFriendId,
                        currentUserId: currentUserId,
                        now: now,
                        loadFriends: () async =>
                            Right<Failure, List<Friend>>(friends),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder headerButton(String label) =>
      find.widgetWithText(CupertinoButton, label);

  TasksEvent lastEvent() =>
      verify(() => bloc.add(captureAny())).captured.last as TasksEvent;

  testWidgets('Return creates the task from the title alone', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField).first, 'Buy milk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      lastEvent(),
      const TaskCreateRequested(title: 'Buy milk', sharedWith: []),
    );
    expect(find.byType(TaskFormSheet), findsNothing);
  });

  testWidgets('Add is disabled until there is a title', (tester) async {
    await open(tester);
    await tester.tap(headerButton('Add'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any()));
    expect(find.byType(TaskFormSheet), findsOneWidget);
  });

  testWidgets('optional sections stay folded until asked for', (tester) async {
    await open(tester);
    expect(find.text('This weekend'), findsNothing);

    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();
    expect(find.text('This weekend'), findsOneWidget);
    // Opening the date section picks today as a start.
    expect(find.text('Time'), findsOneWidget);
  });

  testWidgets('date chips set a date without a time', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'Hike');
    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This weekend'));
    await tester.pumpAndSettle();
    await tester.tap(headerButton('Add'));
    await tester.pumpAndSettle();

    final event = lastEvent() as TaskCreateRequested;
    expect(event.dueDate, DateTime(2026, 10, 24));
    expect(event.startDate, isNull);
  });

  testWidgets('editing can remove a date and keeps the rest', (tester) async {
    await open(
      tester,
      task: TaskEntity(
        id: 't1',
        ownerId: 'me',
        title: 'Pay rent',
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 10, 21, 9),
        createdAt: DateTime(2026),
      ),
    );
    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Remove date'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Remove date'));
    await tester.pumpAndSettle();
    await tester.tap(headerButton('Save'));
    await tester.pumpAndSettle();

    expect(
      lastEvent(),
      const TaskEdited(
        't1',
        TaskDraft(
          title: 'Pay rent',
          priority: TaskPriority.high,
          sharedWithIds: [],
        ),
      ),
    );
  });

  testWidgets('shares with picked friends; Social can preselect one', (
    tester,
  ) async {
    await open(tester, initialFriendId: 'ana');
    // Preselected sharing is visible right away.
    expect(find.text('Ana Torres'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Plan trip');
    await tester.pump();
    await tester.tap(headerButton('Add'));
    await tester.pumpAndSettle();

    expect((lastEvent() as TaskCreateRequested).sharedWith, ['ana']);
  });

  testWidgets('only the owner can change sharing', (tester) async {
    await open(
      tester,
      currentUserId: 'someone-else',
      task: TaskEntity(
        id: 't1',
        ownerId: 'me',
        title: 'Shared with me',
        createdAt: DateTime(2026),
      ),
    );
    expect(find.text('Share with'), findsNothing);

    await tester.tap(headerButton('Save'));
    await tester.pumpAndSettle();
    expect((lastEvent() as TaskEdited).draft.sharedWithIds, isNull);
  });
}
