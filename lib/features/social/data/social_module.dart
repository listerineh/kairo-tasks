import 'package:injectable/injectable.dart';

import '../domain/repositories/friends_repository.dart';
import '../domain/usecases/get_friends.dart';

/// Registers social use cases; the domain layer stays free of DI annotations.
@module
abstract class SocialModule {
  GetFriends getFriends(FriendsRepository r) => GetFriends(r);
}
