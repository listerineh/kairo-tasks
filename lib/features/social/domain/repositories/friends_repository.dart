import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/friend.dart';
import '../entities/person.dart';

/// Friends, requests and nudges for the signed-in user.
abstract class FriendsRepository {
  /// Accepted friends, sorted by name.
  Future<Either<Failure, List<Friend>>> getFriends();

  /// Requests waiting for my answer, newest first.
  Future<Either<Failure, List<FriendRequest>>> getIncomingRequests();

  /// Ids of people I asked who haven't answered yet.
  Future<Either<Failure, Set<String>>> getSentRequestIds();

  /// Profiles whose username contains [query], without me.
  Future<Either<Failure, List<Person>>> searchPeople(String query);

  Future<Either<Failure, Unit>> sendRequest(String userId);

  Future<Either<Failure, Unit>> answerRequest(
    String requestId, {
    required bool accept,
  });

  Future<Either<Failure, Unit>> removeFriend(String friendshipId);

  /// Stores [color] on my side of the friendship.
  Future<Either<Failure, Unit>> setFriendColor(Friend friend, String color);

  /// Sends a push to each of [userIds] about [taskId]. A
  /// [NudgeTooSoonFailure] means one was sent in the last half hour.
  Future<Either<Failure, Unit>> nudge(List<String> userIds, String taskId);

  /// Fires when friendships change on the server.
  Stream<void> changes();
}
