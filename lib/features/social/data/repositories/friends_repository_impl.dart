import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/session/current_user.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/friends_repository.dart';

@LazySingleton(as: FriendsRepository)
class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl(this._client, this._user);

  final SupabaseClient _client;
  final CurrentUser _user;

  static const _profile = 'id, username, display_name, avatar_url';

  /// SQLSTATE the nudge trigger raises when it is too soon (see
  /// `20261021000003_nudges.sql`).
  static const _tooSoon = 'KN001';

  @override
  Future<Either<Failure, List<Friend>>> getFriends() => _run((me) async {
    final rows = await _client
        .from('friendships')
        .select('''
          id,
          requester_id,
          addressee_id,
          requester_color,
          addressee_color,
          requester:profiles!requester_id($_profile),
          addressee:profiles!addressee_id($_profile)
        ''')
        .or('requester_id.eq.$me,addressee_id.eq.$me')
        .eq('status', 'accepted');
    return [
      for (final row in List<Map<String, dynamic>>.from(rows))
        _friendFrom(row, me),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  });

  @override
  Future<Either<Failure, List<FriendRequest>>> getIncomingRequests() =>
      _run((me) async {
        final rows = await _client
            .from('friendships')
            .select('id, requester:profiles!requester_id($_profile)')
            .eq('addressee_id', me)
            .eq('status', 'pending')
            .order('created_at', ascending: false);
        return [
          for (final row in List<Map<String, dynamic>>.from(rows))
            if (row['requester'] != null)
              FriendRequest(
                id: row['id'] as String,
                from: _personFrom(
                  row['requester'] as Map<String, dynamic>,
                  Relation.incoming,
                ),
              ),
        ];
      });

  @override
  Future<Either<Failure, Set<String>>> getSentRequestIds() => _run((me) async {
    final rows = await _client
        .from('friendships')
        .select('addressee_id')
        .eq('requester_id', me)
        .eq('status', 'pending');
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['addressee_id'] as String,
    };
  });

  @override
  Future<Either<Failure, List<Person>>> searchPeople(String query) =>
      _run((me) async {
        // `%` and `_` are ILIKE wildcards; a username never needs them.
        final term = query.trim().replaceAll(RegExp('[%_]'), '');
        if (term.isEmpty) return const <Person>[];
        final rows = await _client
            .from('profiles')
            .select(_profile)
            .ilike('username', '%$term%')
            .neq('id', me)
            .order('username')
            .limit(20);
        return [
          for (final row in List<Map<String, dynamic>>.from(rows))
            _personFrom(row, Relation.none),
        ];
      });

  @override
  Future<Either<Failure, Unit>> sendRequest(String userId) => _run((me) async {
    await _client.from('friendships').insert({
      'requester_id': me,
      'addressee_id': userId,
      'status': 'pending',
    });
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> answerRequest(
    String requestId, {
    required bool accept,
  }) => _run((_) async {
    await _client
        .from('friendships')
        .update({'status': accept ? 'accepted' : 'rejected'})
        .eq('id', requestId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> removeFriend(String friendshipId) =>
      _run((_) async {
        await _client.from('friendships').delete().eq('id', friendshipId);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> setFriendColor(Friend friend, String color) =>
      _run((_) async {
        final id = friend.friendshipId;
        if (id == null) return unit;
        await _client
            .from('friendships')
            .update({
              friend.iAsked ? 'requester_color' : 'addressee_color': color,
            })
            .eq('id', id);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> nudge(List<String> userIds, String taskId) =>
      _run((me) async {
        if (userIds.isEmpty) return unit;
        await _client.from('nudges').insert([
          for (final id in userIds)
            {'sender_id': me, 'recipient_id': id, 'task_id': taskId},
        ]);
        return unit;
      });

  @override
  Stream<void> changes() {
    final me = _user.id;
    if (me == null) return const Stream.empty();
    final subs = <StreamSubscription<Object?>>[];
    late final StreamController<void> out;
    out = StreamController<void>(
      onListen: () {
        void ping(Object? _) => out.add(null);
        for (final column in ['requester_id', 'addressee_id']) {
          subs.add(
            _client
                .from('friendships')
                .stream(primaryKey: ['id'])
                .eq(column, me)
                .listen(ping, onError: out.addError),
          );
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        // Not awaited: done is never delivered once the listener is gone.
        unawaited(out.close());
      },
    );
    return out.stream;
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function(String me) body) async {
    final me = _user.id;
    if (me == null) return const Left(AuthFailure(message: 'Not signed in'));
    try {
      return Right(await body(me));
    } on PostgrestException catch (e) {
      if (e.code == _tooSoon) return const Left(NudgeTooSoonFailure());
      return Left(ServerFailure(message: e.message));
    }
  }

  /// The other side of the friendship.
  static Friend _friendFrom(Map<String, dynamic> row, String me) {
    final iAsked = row['requester_id'] == me;
    final profile =
        (iAsked ? row['addressee'] : row['requester']) as Map<String, dynamic>?;
    return Friend(
      id: (iAsked ? row['addressee_id'] : row['requester_id']) as String,
      displayName: profile?['display_name'] as String?,
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      friendshipId: row['id'] as String?,
      color:
          (iAsked ? row['requester_color'] : row['addressee_color']) as String?,
      iAsked: iAsked,
    );
  }

  static Person _personFrom(Map<String, dynamic> row, Relation relation) =>
      Person(
        id: row['id'] as String,
        displayName: row['display_name'] as String?,
        username: row['username'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        relation: relation,
      );
}
