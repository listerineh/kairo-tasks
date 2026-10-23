import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/core/errors/failures.dart';
import 'package:kairotasks/features/profile/domain/entities/profile.dart';
import 'package:kairotasks/features/profile/domain/repositories/profile_repository.dart';
import 'package:kairotasks/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  const me = Profile(
    id: 'me',
    displayName: 'Sebas',
    username: 'old-name',
    color: '#3E8A62',
  );
  const ready = ProfileState(status: ProfileStatus.ready, profile: me);

  late MockProfileRepository repo;

  setUpAll(
    () => registerFallbackValue(
      const ProfileDraft(displayName: '', username: ''),
    ),
  );

  setUp(() => repo = MockProfileRepository());

  ProfileCubit build() => ProfileCubit(repo);

  blocTest<ProfileCubit, ProfileState>(
    'loads the profile',
    setUp: () =>
        when(() => repo.getProfile()).thenAnswer((_) async => const Right(me)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [ready],
  );

  blocTest<ProfileCubit, ProfileState>(
    'fails the first load',
    setUp: () =>
        when(() => repo.getProfile())
            .thenAnswer((_) async => const Left(ServerFailure())),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const ProfileState(status: ProfileStatus.failure)],
  );

  group('save', () {
    blocTest<ProfileCubit, ProfileState>(
      'needs a name',
      build: build,
      seed: () => ready,
      act: (cubit) =>
          cubit.save(const ProfileDraft(displayName: '  ', username: 'x')),
      expect: () => [ready.copyWith(saveError: ProfileSaveError.nameMissing)],
      verify: (_) => verifyNever(() => repo.updateProfile(any())),
    );

    blocTest<ProfileCubit, ProfileState>(
      'checks a changed username, not an unchanged old one',
      setUp: () =>
          when(() => repo.updateProfile(any()))
              .thenAnswer((_) async => const Right(me)),
      build: build,
      seed: () => ready,
      act: (cubit) async {
        await cubit.save(
          const ProfileDraft(displayName: 'Sebas', username: 'no spaces'),
        );
        await cubit.save(
          const ProfileDraft(displayName: 'Sebastián', username: 'old-name'),
        );
      },
      verify: (cubit) {
        verify(
          () => repo.updateProfile(
            const ProfileDraft(displayName: 'Sebastián', username: 'old-name'),
          ),
        ).called(1);
        expect(cubit.state.saveCount, 1);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'reports a taken username',
      setUp: () =>
          when(() => repo.updateProfile(any()))
              .thenAnswer((_) async => const Left(UsernameTakenFailure())),
      build: build,
      seed: () => ready,
      act: (cubit) =>
          cubit.save(const ProfileDraft(displayName: 'S', username: 'ana')),
      expect: () => [
        ready.copyWith(saving: true),
        ready.copyWith(saveError: ProfileSaveError.usernameTaken),
      ],
    );
  });

  blocTest<ProfileCubit, ProfileState>(
    'a failed color change rolls back',
    setUp: () =>
        when(() => repo.setColor('#6A62B8'))
            .thenAnswer((_) async => const Left(ServerFailure())),
    build: build,
    seed: () => ready,
    act: (cubit) => cubit.setColor('#6A62B8'),
    expect: () => [
      ready.copyWith(profile: me.copyWith(color: '#6A62B8')),
      ready.copyWith(updateFailed: 1),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'calendar visibility flips at once',
    setUp: () =>
        when(() => repo.setCalendarPublic(value: true))
            .thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => ready,
    act: (cubit) => cubit.setCalendarPublic(value: true),
    expect: () => [ready.copyWith(profile: me.copyWith(calendarPublic: true))],
  );
}
