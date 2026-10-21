import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/features/social/domain/entities/friend.dart';
import 'package:kairotasks/features/social/domain/entities/person.dart';
import 'package:kairotasks/features/social/presentation/bloc/social_bloc.dart';
import 'package:kairotasks/features/social/presentation/pages/social_page.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:kairotasks/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

class MockSocialBloc extends MockBloc<SocialEvent, SocialState>
    implements SocialBloc {}

void main() {
  const request = FriendRequest(
    id: 'r1',
    from: Person(id: 'mateo', displayName: 'Mateo', username: 'mateo'),
  );
  final shared = TaskEntity(
    id: 't1',
    ownerId: 'me',
    title: 'Correr 5K',
    sharedWith: const [
      {'id': 'ana', 'username': 'ana', 'display_name': 'Ana'},
    ],
    createdAt: DateTime(2026),
  );

  late MockSocialBloc social;
  late MockTasksBloc tasks;

  setUpAll(() => registerFallbackValue(const SocialStarted()));

  setUp(() {
    social = MockSocialBloc();
    tasks = MockTasksBloc();
    when(() => tasks.state)
        .thenReturn(TasksState(status: TasksStatus.loaded, tasks: [shared]));
  });

  Future<void> pump(WidgetTester tester, SocialState state) async {
    when(() => social.state).thenReturn(state);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<TasksBloc>.value(value: tasks),
              BlocProvider<SocialBloc>.value(value: social),
            ],
            child: const SocialView(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('accepting a request sends the answer', (tester) async {
    await pump(
      tester,
      const SocialState(status: SocialStatus.ready, requests: [request]),
    );
    expect(find.text('Mateo wants to join'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Accept Mateo'));
    verify(() => social.add(const FriendRequestAnswered(request, accept: true)))
        .called(1);
  });

  testWidgets('shared tasks offer a nudge', (tester) async {
    await pump(
      tester,
      const SocialState(
        status: SocialStatus.ready,
        friends: [Friend(id: 'ana', displayName: 'Ana')],
      ),
    );
    expect(find.text('Doing together'), findsOneWidget);
    expect(find.text('Correr 5K'), findsOneWidget);
    await tester.tap(find.text('Nudge'));
    verify(() => social.add(NudgeSent(shared))).called(1);
  });

  testWidgets('a nudged task shows it was sent', (tester) async {
    await pump(
      tester,
      const SocialState(
        status: SocialStatus.ready,
        friends: [Friend(id: 'ana', displayName: 'Ana')],
        nudged: {'t1'},
      ),
    );
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Nudge'), findsNothing);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    await pump(tester, const SocialState(status: SocialStatus.failure));
    await tester.tap(find.text('Try again'));
    verify(() => social.add(const SocialStarted())).called(1);
  });
}
