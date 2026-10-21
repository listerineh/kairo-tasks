import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/friend.dart';

/// Friend data for the signed-in user.
// One method for now; requests, search and removal join it in the Social
// phase, so it stays an interface rather than a function.
// ignore: one_member_abstracts
abstract class FriendsRepository {
  /// Accepted friends, sorted by name.
  Future<Either<Failure, List<Friend>>> getFriends();
}
