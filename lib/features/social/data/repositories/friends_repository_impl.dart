import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/session/current_user.dart';
import '../../domain/entities/friend.dart';
import '../../domain/repositories/friends_repository.dart';

@LazySingleton(as: FriendsRepository)
class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl(this._client, this._user);

  final SupabaseClient _client;
  final CurrentUser _user;

  @override
  Future<Either<Failure, List<Friend>>> getFriends() async {
    final me = _user.id;
    if (me == null) return const Left(AuthFailure(message: 'Not signed in'));
    try {
      final rows = await _client
          .from('friendships')
          .select('''
            requester_id,
            addressee_id,
            requester:profiles!requester_id(username, display_name, avatar_url),
            addressee:profiles!addressee_id(username, display_name, avatar_url)
          ''')
          .or('requester_id.eq.$me,addressee_id.eq.$me')
          .eq('status', 'accepted');
      final friends = [
        for (final row in List<Map<String, dynamic>>.from(rows))
          _friendFrom(row, me),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return Right(friends);
    } on PostgrestException catch (e) {
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
    );
  }
}
