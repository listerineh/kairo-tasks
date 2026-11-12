import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/logger_service.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/friends_repository.dart';
import '../../domain/shared_tasks.dart';

// Events

sealed class SocialEvent extends Equatable {
  const SocialEvent();

  @override
  List<Object?> get props => [];
}

/// Loads everything and follows server changes.
class SocialStarted extends SocialEvent {
  const SocialStarted();
}

/// Pull to refresh; [done] completes when the reload finishes, even when
/// nothing changed.
class SocialRefreshed extends SocialEvent {
  const SocialRefreshed([this.done]);

  final Completer<void>? done;
}

class SocialSearchChanged extends SocialEvent {
  const SocialSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class FriendRequestSent extends SocialEvent {
  const FriendRequestSent(this.person);

  final Person person;

  @override
  List<Object?> get props => [person];
}

class FriendRequestAnswered extends SocialEvent {
  const FriendRequestAnswered(this.request, {required this.accept});

  final FriendRequest request;
  final bool accept;

  @override
  List<Object?> get props => [request, accept];
}

class FriendRemoved extends SocialEvent {
  const FriendRemoved(this.friend);

  final Friend friend;

  @override
  List<Object?> get props => [friend];
}

class FriendColorChanged extends SocialEvent {
  const FriendColorChanged(this.friend, this.color);

  final Friend friend;
  final String color;

  @override
  List<Object?> get props => [friend, color];
}

class NudgeSent extends SocialEvent {
  const NudgeSent(this.task);

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

class _ServerChanged extends SocialEvent {
  const _ServerChanged();
}

// State

enum SocialStatus { loading, ready, failure }

/// One-shot feedback the page turns into a snackbar.
enum SocialNotice {
  requestSent,
  requestAccepted,
  requestDeclined,
  friendRemoved,
  nudged,
  nudgedRecently,
  failed,
}

class SocialState extends Equatable {
  const SocialState({
    this.status = SocialStatus.loading,
    this.friends = const [],
    this.requests = const [],
    this.sentIds = const {},
    this.query = '',
    this.searching = false,
    this.found = const [],
    this.nudged = const {},
    this.notice,
    this.noticeCount = 0,
  });

  final SocialStatus status;
  final List<Friend> friends;
  final List<FriendRequest> requests;

  /// People I asked who haven't answered.
  final Set<String> sentIds;

  final String query;
  final bool searching;

  /// Raw search hits; [results] adds how each one relates to me.
  final List<Person> found;

  /// Task ids nudged in this session (the button then reads "Enviado").
  final Set<String> nudged;

  final SocialNotice? notice;

  /// Bumped with every notice so the same one can show twice.
  final int noticeCount;

  List<Person> get results {
    final friendIds = {for (final f in friends) f.id};
    final incoming = {for (final r in requests) r.from.id};
    return [
      for (final p in found)
        p.withRelation(
          friendIds.contains(p.id)
              ? Relation.friend
              : incoming.contains(p.id)
              ? Relation.incoming
              : sentIds.contains(p.id)
              ? Relation.requested
              : Relation.none,
        ),
    ];
  }

  SocialState copyWith({
    SocialStatus? status,
    List<Friend>? friends,
    List<FriendRequest>? requests,
    Set<String>? sentIds,
    String? query,
    bool? searching,
    List<Person>? found,
    Set<String>? nudged,
  }) => SocialState(
    status: status ?? this.status,
    friends: friends ?? this.friends,
    requests: requests ?? this.requests,
    sentIds: sentIds ?? this.sentIds,
    query: query ?? this.query,
    searching: searching ?? this.searching,
    found: found ?? this.found,
    nudged: nudged ?? this.nudged,
    notice: notice,
    noticeCount: noticeCount,
  );

  SocialState withNotice(SocialNotice value) => SocialState(
    status: status,
    friends: friends,
    requests: requests,
    sentIds: sentIds,
    query: query,
    searching: searching,
    found: found,
    nudged: nudged,
    notice: value,
    noticeCount: noticeCount + 1,
  );

  @override
  List<Object?> get props => [
    status,
    friends,
    requests,
    sentIds,
    query,
    searching,
    found,
    nudged,
    notice,
    noticeCount,
  ];
}

// Bloc

/// Juntos: friends, requests, search and nudges. Writes are optimistic where
/// the result is obvious (answering, removing, recoloring) and roll back with
/// a [SocialNotice.failed] notice.
@injectable
class SocialBloc extends Bloc<SocialEvent, SocialState> {
  SocialBloc(
    this._repository, {
    @ignoreParam Duration searchDebounce = const Duration(milliseconds: 300),
    @ignoreParam Duration changesDebounce = const Duration(milliseconds: 400),
  }) : _searchWait = searchDebounce,
       _changesWait = changesDebounce,
       super(const SocialState()) {
    on<SocialStarted>(_onStarted);
    on<SocialRefreshed>((event, emit) async {
      await _load(emit);
      event.done?.complete();
    });
    on<_ServerChanged>((_, emit) => _load(emit));
    on<SocialSearchChanged>(_onSearchChanged);
    on<FriendRequestSent>(_onRequestSent);
    on<FriendRequestAnswered>(_onRequestAnswered);
    on<FriendRemoved>(_onFriendRemoved);
    on<FriendColorChanged>(_onColorChanged);
    on<NudgeSent>(_onNudgeSent);
  }

  final FriendsRepository _repository;
  final Duration _searchWait;
  final Duration _changesWait;

  StreamSubscription<void>? _changes;
  Timer? _changesTimer;
  String _latestQuery = '';

  Future<void> _onStarted(
    SocialStarted event,
    Emitter<SocialState> emit,
  ) async {
    await _changes?.cancel();
    _changes = _repository.changes().listen((_) {
      _changesTimer?.cancel();
      _changesTimer = Timer(_changesWait, () {
        if (!isClosed) add(const _ServerChanged());
      });
    }, onError: (Object _) {});
    await _load(emit);
  }

  Future<void> _load(Emitter<SocialState> emit) async {
    final results = await Future.wait([
      _repository.getFriends(),
      _repository.getIncomingRequests(),
      _repository.getSentRequestIds(),
    ]);
    final friends = results[0] as Either<Failure, List<Friend>>;
    final requests = results[1] as Either<Failure, List<FriendRequest>>;
    final sent = results[2] as Either<Failure, Set<String>>;

    final failure = [friends, requests, sent]
        .map((r) => r.fold<Failure?>((f) => f, (_) => null))
        .whereType<Failure>()
        .firstOrNull;
    if (failure != null) {
      LoggerService.instance.error(
        'Failed to load social data',
        data: {'operation': 'social.load', 'error': failure.message},
      );
      // Keep what is on screen after a refresh; fail only the first load.
      emit(
        state.status == SocialStatus.ready
            ? state.withNotice(SocialNotice.failed)
            : state.copyWith(status: SocialStatus.failure),
      );
      return;
    }
    emit(
      state.copyWith(
        status: SocialStatus.ready,
        friends: friends.getOrElse(() => const []),
        requests: requests.getOrElse(() => const []),
        sentIds: sent.getOrElse(() => const {}),
      ),
    );
  }

  Future<void> _onSearchChanged(
    SocialSearchChanged event,
    Emitter<SocialState> emit,
  ) async {
    final query = event.query.trim();
    _latestQuery = query;
    if (query.isEmpty) {
      emit(state.copyWith(query: '', searching: false, found: const []));
      return;
    }
    emit(state.copyWith(query: query, searching: true));
    await Future<void>.delayed(_searchWait);
    if (_latestQuery != query) return;

    final result = await _repository.searchPeople(query);
    if (_latestQuery != query) return;
    result.fold(
      (failure) => emit(
        state
            .copyWith(searching: false, found: const [])
            .withNotice(SocialNotice.failed),
      ),
      (people) => emit(state.copyWith(searching: false, found: people)),
    );
  }

  Future<void> _onRequestSent(
    FriendRequestSent event,
    Emitter<SocialState> emit,
  ) async {
    final id = event.person.id;
    final before = state.sentIds;
    emit(state.copyWith(sentIds: {...before, id}));
    final result = await _repository.sendRequest(id);
    result.fold(
      (_) => emit(
        state
            .copyWith(sentIds: {...state.sentIds}..remove(id))
            .withNotice(SocialNotice.failed),
      ),
      (_) => emit(state.withNotice(SocialNotice.requestSent)),
    );
  }

  Future<void> _onRequestAnswered(
    FriendRequestAnswered event,
    Emitter<SocialState> emit,
  ) async {
    final request = event.request;
    final before = state.requests;
    emit(
      state.copyWith(
        requests: [
          for (final r in before)
            if (r.id != request.id) r,
        ],
      ),
    );
    final result = await _repository.answerRequest(
      request.id,
      accept: event.accept,
    );
    if (result.isLeft()) {
      emit(state.copyWith(requests: before).withNotice(SocialNotice.failed));
      return;
    }
    emit(
      state.withNotice(
        event.accept
            ? SocialNotice.requestAccepted
            : SocialNotice.requestDeclined,
      ),
    );
    // The new friend's row (with its id and color) comes from the server.
    if (event.accept) await _load(emit);
  }

  Future<void> _onFriendRemoved(
    FriendRemoved event,
    Emitter<SocialState> emit,
  ) async {
    final id = event.friend.friendshipId;
    if (id == null) return;
    final before = state.friends;
    emit(
      state.copyWith(
        friends: [
          for (final f in before)
            if (f.id != event.friend.id) f,
        ],
      ),
    );
    final result = await _repository.removeFriend(id);
    emit(
      result.isLeft()
          ? state.copyWith(friends: before).withNotice(SocialNotice.failed)
          : state.withNotice(SocialNotice.friendRemoved),
    );
  }

  Future<void> _onColorChanged(
    FriendColorChanged event,
    Emitter<SocialState> emit,
  ) async {
    final before = state.friends;
    Friend recolor(Friend f) => Friend(
      id: f.id,
      displayName: f.displayName,
      username: f.username,
      avatarUrl: f.avatarUrl,
      friendshipId: f.friendshipId,
      color: event.color,
      iAsked: f.iAsked,
    );
    emit(
      state.copyWith(
        friends: [
          for (final f in before)
            if (f.id == event.friend.id) recolor(f) else f,
        ],
      ),
    );
    final result = await _repository.setFriendColor(event.friend, event.color);
    if (result.isLeft()) {
      emit(state.copyWith(friends: before).withNotice(SocialNotice.failed));
    }
  }

  Future<void> _onNudgeSent(NudgeSent event, Emitter<SocialState> emit) async {
    final task = event.task;
    if (state.nudged.contains(task.id)) return;
    final targets = nudgeTargets(task);
    if (targets.isEmpty) return;

    emit(state.copyWith(nudged: {...state.nudged, task.id}));
    final result = await _repository.nudge(targets, task.id);
    result.fold((failure) {
      if (failure is NudgeTooSoonFailure) {
        // Still counts as sent: the friend already got one.
        emit(state.withNotice(SocialNotice.nudgedRecently));
      } else {
        emit(
          state
              .copyWith(nudged: {...state.nudged}..remove(task.id))
              .withNotice(SocialNotice.failed),
        );
      }
    }, (_) => emit(state.withNotice(SocialNotice.nudged)));
  }

  @override
  Future<void> close() async {
    _changesTimer?.cancel();
    await _changes?.cancel();
    return super.close();
  }
}
