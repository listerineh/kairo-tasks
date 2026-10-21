import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/friend.dart';
import '../repositories/friends_repository.dart';

class GetFriends {
  const GetFriends(this._repository);

  final FriendsRepository _repository;

  Future<Either<Failure, List<Friend>>> call() => _repository.getFriends();
}
