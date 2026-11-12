import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/core/errors/failures.dart';
import 'package:kairotasks/features/social/domain/entities/friend.dart';
import 'package:kairotasks/features/social/domain/entities/person.dart';
import 'package:kairotasks/features/social/domain/repositories/friends_repository.dart';
import 'package:kairotasks/features/social/presentation/bloc/social_bloc.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockFriendsRepository extends Mock implements FriendsRepository {}

void main() {
  const ana = Friend(
    id: 'ana',
    displayName: 'Ana',
    username: 'ana',
    friendshipId: 'f1',
    color: '#3E8A62',
  );
  const mateo = Person(id: 'mateo', displayName: 'Mateo', username: 'mateo');
  const request = FriendRequest(id: 'r1', from: mateo);
  const leo = Person(id: 'leo', displayName: 'Leo', username: 'leo');

  final task = TaskEntity(
    id: 't1',
    ownerId: 'me',
    title: 'Correr 5K',
    createdAt: DateTime(2026),
    sharedWith: const [
      {'id': 'ana', 'username': 'ana', 'display_name': 'Ana'},
    ],
  );

  late MockFriendsRepository repo;
  late StreamController<void> changes;

  SocialBloc build() => SocialBloc(
    repo,
    searchDebounce: const Duration(milliseconds: 10),
    changesDebounce: const Duration(milliseconds: 10),
  );

  setUpAll(() => registerFallbackValue(ana));

  setUp(() {
    repo = MockFriendsRepository();
    changes = StreamController<void>.broadcast();
    when(() => repo.changes()).thenAnswer((_) => changes.stream);
    when(() => repo.getFriends()).thenAnswer((_) async => const Right([ana]));
    when(() => repo.getIncomingRequests())
        .thenAnswer((_) async => const Right([request]));
    when(() => repo.getSentRequestIds())
        .thenAnswer((_) async => const Right({'leo'}));
  });

  tearDown(() => unawaited(changes.close()));

  group('load', () {
    blocTest<SocialBloc, SocialState>(
      'loads friends, requests and sent ids',
      build: build,
      act: (bloc) => bloc.add(const SocialStarted()),
      expect: () => [
        const SocialState(
          status: SocialStatus.ready,
          friends: [ana],
          requests: [request],
          sentIds: {'leo'},
        ),
      ],
    );

    blocTest<SocialBloc, SocialState>(
      'fails the first load when the server fails',
      setUp: () =>
          when(() => repo.getFriends())
              .thenAnswer((_) async => const Left(ServerFailure())),
      build: build,
      act: (bloc) => bloc.add(const SocialStarted()),
      expect: () => [const SocialState(status: SocialStatus.failure)],
    );

    blocTest<SocialBloc, SocialState>(
      'reloads when friendships change on the server',
      build: build,
      act: (bloc) async {
        bloc.add(const SocialStarted());
        await Future<void>.delayed(Duration.zero);
        changes
          ..add(null)
          ..add(null);
        await Future<void>.delayed(const Duration(milliseconds: 40));
      },
      verify: (_) => verify(() => repo.getFriends()).called(2),
    );
  });

  group('search', () {
    blocTest<SocialBloc, SocialState>(
      'debounces and marks how each person relates to me',
      setUp: () =>
          when(() => repo.searchPeople('le'))
              .thenAnswer((_) async => const Right([leo, mateo])),
      build: build,
      seed: () => const SocialState(
        status: SocialStatus.ready,
        friends: [ana],
        requests: [request],
        sentIds: {'leo'},
      ),
      act: (bloc) async {
        bloc
          ..add(const SocialSearchChanged('l'))
          ..add(const SocialSearchChanged('le'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      },
      verify: (bloc) {
        verifyNever(() => repo.searchPeople('l'));
        expect(bloc.state.searching, isFalse);
        expect(bloc.state.results.map((p) => p.relation), [
          Relation.requested,
          Relation.incoming,
        ]);
      },
    );

    blocTest<SocialBloc, SocialState>(
      'an empty query clears results without searching',
      build: build,
      seed: () => const SocialState(query: 'le', found: [leo]),
      act: (bloc) => bloc.add(const SocialSearchChanged('  ')),
      expect: () => [const SocialState()],
      verify: (_) => verifyNever(() => repo.searchPeople(any())),
    );
  });

  group('requests', () {
    blocTest<SocialBloc, SocialState>(
      'sending marks the person as requested right away',
      setUp: () =>
          when(() => repo.sendRequest('mateo'))
              .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (bloc) => bloc.add(const FriendRequestSent(mateo)),
      expect: () => [
        const SocialState(sentIds: {'mateo'}),
        const SocialState(
          sentIds: {'mateo'},
          notice: SocialNotice.requestSent,
          noticeCount: 1,
        ),
      ],
    );

    blocTest<SocialBloc, SocialState>(
      'declining removes the request at once',
      setUp: () =>
          when(() => repo.answerRequest('r1', accept: false))
              .thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () =>
          const SocialState(status: SocialStatus.ready, requests: [request]),
      act: (bloc) =>
          bloc.add(const FriendRequestAnswered(request, accept: false)),
      expect: () => [
        const SocialState(status: SocialStatus.ready),
        const SocialState(
          status: SocialStatus.ready,
          notice: SocialNotice.requestDeclined,
          noticeCount: 1,
        ),
      ],
      verify: (_) => verifyNever(() => repo.getFriends()),
    );

    blocTest<SocialBloc, SocialState>(
      'accepting reloads to pick up the new friend',
      setUp: () =>
          when(() => repo.answerRequest('r1', accept: true))
              .thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () =>
          const SocialState(status: SocialStatus.ready, requests: [request]),
      act: (bloc) =>
          bloc.add(const FriendRequestAnswered(request, accept: true)),
      verify: (_) => verify(() => repo.getFriends()).called(1),
    );

    blocTest<SocialBloc, SocialState>(
      'a failed answer puts the request back',
      setUp: () =>
          when(() => repo.answerRequest('r1', accept: true))
              .thenAnswer((_) async => const Left(ServerFailure())),
      build: build,
      seed: () =>
          const SocialState(status: SocialStatus.ready, requests: [request]),
      act: (bloc) =>
          bloc.add(const FriendRequestAnswered(request, accept: true)),
      expect: () => [
        const SocialState(status: SocialStatus.ready),
        const SocialState(
          status: SocialStatus.ready,
          requests: [request],
          notice: SocialNotice.failed,
          noticeCount: 1,
        ),
      ],
    );
  });

  group('friends', () {
    blocTest<SocialBloc, SocialState>(
      'removing a friend drops them before the server answers',
      setUp: () =>
          when(() => repo.removeFriend('f1'))
              .thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => const SocialState(status: SocialStatus.ready, friends: [ana]),
      act: (bloc) => bloc.add(const FriendRemoved(ana)),
      expect: () => [
        const SocialState(status: SocialStatus.ready),
        const SocialState(
          status: SocialStatus.ready,
          notice: SocialNotice.friendRemoved,
          noticeCount: 1,
        ),
      ],
    );

    blocTest<SocialBloc, SocialState>(
      'recoloring updates the friend and rolls back on failure',
      setUp: () =>
          when(() => repo.setFriendColor(any(), '#6A62B8'))
              .thenAnswer((_) async => const Left(ServerFailure())),
      build: build,
      seed: () => const SocialState(status: SocialStatus.ready, friends: [ana]),
      act: (bloc) => bloc.add(const FriendColorChanged(ana, '#6A62B8')),
      verify: (bloc) {
        expect(bloc.state.friends.single.color, '#3E8A62');
        expect(bloc.state.notice, SocialNotice.failed);
      },
    );
  });

  group('nudges', () {
    blocTest<SocialBloc, SocialState>(
      'nudges everyone else on the task once',
      setUp: () =>
          when(() => repo.nudge(['ana'], 't1'))
              .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (bloc) => bloc
        ..add(NudgeSent(task))
        ..add(NudgeSent(task)),
      expect: () => [
        const SocialState(nudged: {'t1'}),
        const SocialState(
          nudged: {'t1'},
          notice: SocialNotice.nudged,
          noticeCount: 1,
        ),
      ],
      verify: (_) => verify(() => repo.nudge(['ana'], 't1')).called(1),
    );

    blocTest<SocialBloc, SocialState>(
      'a nudge sent recently still counts as sent',
      setUp: () =>
          when(() => repo.nudge(['ana'], 't1'))
              .thenAnswer((_) async => const Left(NudgeTooSoonFailure())),
      build: build,
      act: (bloc) => bloc.add(NudgeSent(task)),
      expect: () => [
        const SocialState(nudged: {'t1'}),
        const SocialState(
          nudged: {'t1'},
          notice: SocialNotice.nudgedRecently,
          noticeCount: 1,
        ),
      ],
    );

    blocTest<SocialBloc, SocialState>(
      'a failed nudge can be tried again',
      setUp: () =>
          when(() => repo.nudge(['ana'], 't1'))
              .thenAnswer((_) async => const Left(ServerFailure())),
      build: build,
      act: (bloc) => bloc.add(NudgeSent(task)),
      expect: () => [
        const SocialState(nudged: {'t1'}),
        const SocialState(notice: SocialNotice.failed, noticeCount: 1),
      ],
    );
  });
}
