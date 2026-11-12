import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';

/// The signed-in user's profile.
abstract class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile();

  /// Saves name, username and (when [ProfileDraft.avatarPath] is set) a new
  /// photo. A [UsernameTakenFailure] means someone else has the username.
  Future<Either<Failure, Profile>> updateProfile(ProfileDraft draft);

  Future<Either<Failure, Unit>> setColor(String color);

  Future<Either<Failure, Unit>> setCalendarPublic({required bool value});
}
