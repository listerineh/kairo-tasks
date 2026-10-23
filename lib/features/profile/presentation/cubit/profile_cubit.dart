import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

enum ProfileStatus { loading, ready, failure }

/// Why a save did not go through; the sheet shows a message for each.
enum ProfileSaveError { nameMissing, usernameInvalid, usernameTaken, failed }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.profile,
    this.saving = false,
    this.saveError,
    this.saveCount = 0,
    this.updateFailed = 0,
  });

  final ProfileStatus status;
  final Profile? profile;
  final bool saving;
  final ProfileSaveError? saveError;

  /// Bumped after each successful save, so the sheet knows to close.
  final int saveCount;

  /// Bumped when a quick setting (color, visibility) failed and rolled back.
  final int updateFailed;

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    bool? saving,
    ProfileSaveError? saveError,
    bool clearSaveError = false,
    int? saveCount,
    int? updateFailed,
  }) => ProfileState(
    status: status ?? this.status,
    profile: profile ?? this.profile,
    saving: saving ?? this.saving,
    saveError: clearSaveError ? null : saveError ?? this.saveError,
    saveCount: saveCount ?? this.saveCount,
    updateFailed: updateFailed ?? this.updateFailed,
  );

  @override
  List<Object?> get props => [
    status,
    profile,
    saving,
    saveError,
    saveCount,
    updateFailed,
  ];
}

/// Yo: loads the profile, saves edits, and flips quick settings
/// optimistically.
@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load() async {
    final result = await _repository.getProfile();
    result.fold(
      (_) => emit(
        state.copyWith(
          status: state.profile == null
              ? ProfileStatus.failure
              : ProfileStatus.ready,
        ),
      ),
      (profile) =>
          emit(state.copyWith(status: ProfileStatus.ready, profile: profile)),
    );
  }

  Future<void> save(ProfileDraft draft) async {
    final current = state.profile;
    if (current == null || state.saving) return;
    final clean = draft.normalized();
    final error = clean.displayName.isEmpty
        ? ProfileSaveError.nameMissing
        // Only a changed username has to follow the rules, so older
        // usernames never block saving a new name or photo.
        : clean.username != current.username &&
              !ProfileDraft.usernamePattern.hasMatch(clean.username)
        ? ProfileSaveError.usernameInvalid
        : null;
    if (error != null) {
      emit(state.copyWith(saveError: error));
      return;
    }

    emit(state.copyWith(saving: true, clearSaveError: true));
    final result = await _repository.updateProfile(clean);
    result.fold(
      (failure) => emit(
        state.copyWith(
          saving: false,
          saveError: failure is UsernameTakenFailure
              ? ProfileSaveError.usernameTaken
              : ProfileSaveError.failed,
        ),
      ),
      (profile) => emit(
        state.copyWith(
          saving: false,
          profile: profile,
          saveCount: state.saveCount + 1,
        ),
      ),
    );
  }

  /// Forgets the last save error, e.g. when the sheet opens again.
  void clearError() => emit(state.copyWith(clearSaveError: true));

  Future<void> setColor(String color) => _quick(
    (p) => p.copyWith(color: color),
    () => _repository.setColor(color),
  );

  Future<void> setCalendarPublic({required bool value}) => _quick(
    (p) => p.copyWith(calendarPublic: value),
    () => _repository.setCalendarPublic(value: value),
  );

  Future<void> _quick(
    Profile Function(Profile) change,
    Future<Either<Failure, Unit>> Function() write,
  ) async {
    final before = state.profile;
    if (before == null) return;
    emit(state.copyWith(profile: change(before)));
    final result = await write();
    if (result.isLeft()) {
      emit(
        state.copyWith(profile: before, updateFailed: state.updateFailed + 1),
      );
    }
  }
}
