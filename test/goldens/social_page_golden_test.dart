import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kairotasks/features/social/domain/entities/friend.dart';
import 'package:kairotasks/features/social/domain/entities/person.dart';
import 'package:kairotasks/features/social/presentation/bloc/social_bloc.dart';
import 'package:kairotasks/features/social/presentation/pages/social_page.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/golden.dart';
import '../helpers/mocks.dart';

class MockSocialBloc extends MockBloc<SocialEvent, SocialState>
    implements SocialBloc {}

void main() {
  final now = DateTime(2026, 10, 21, 10, 40);

  Map<String, dynamic> person(String id, String name) => {
    'id': id,
    'username': name.toLowerCase(),
    'display_name': name,
  };

  final friends = [
    const Friend(id: 'ana', displayName: 'Ana Ruiz', color: '#C26A3D'),
    const Friend(id: 'leo', displayName: 'Leo', color: '#3F6FA8'),
    const Friend(id: 'sofi', displayName: 'Sofía', color: '#A1842A'),
    const Friend(id: 'tomas', displayName: 'Tomás', color: '#3E8A62'),
  ];
  const request = FriendRequest(
    id: 'r1',
    from: Person(id: 'mateo', displayName: 'Mateo', username: 'mateo'),
  );

  final tasks = [
    TaskEntity(
      id: 't1',
      ownerId: 'me',
      title: "Review Ana's PR",
      dueDate: DateTime(2026, 10, 21, 16),
      status: TaskStatus.inProgress,
      sharedWith: [person('ana', 'Ana')],
      createdAt: DateTime(2026),
    ),
    TaskEntity(
      id: 't2',
      ownerId: 'leo',
      title: "Leo's move",
      dueDate: DateTime(2026, 10, 24),
      sharedWith: [person('leo', 'Leo'), person('sofi', 'Sofía')],
      createdAt: DateTime(2026),
    ),
  ];

  Widget page(BuildContext context, SocialState state) {
    final social = MockSocialBloc();
    when(() => social.state).thenReturn(state);
    final tasksBloc = MockTasksBloc();
    when(() => tasksBloc.state)
        .thenReturn(TasksState(status: TasksStatus.loaded, tasks: tasks));
    // Reduced motion freezes the entrance cascade.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TasksBloc>.value(value: tasksBloc),
          BlocProvider<SocialBloc>.value(value: social),
        ],
        child: SocialView(now: now),
      ),
    );
  }

  goldenTest(
    'social_page',
    size: const Size(390, 900),
    builder: (context) => page(
      context,
      SocialState(
        status: SocialStatus.ready,
        friends: friends,
        requests: const [request],
        nudged: const {'t2'},
      ),
    ),
  );

  goldenTest(
    'social_page_empty',
    size: const Size(390, 520),
    builder: (context) =>
        page(context, const SocialState(status: SocialStatus.ready)),
  );
}
