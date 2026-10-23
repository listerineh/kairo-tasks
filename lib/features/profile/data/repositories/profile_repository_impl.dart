import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/session/current_user.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._client, this._user);

  final SupabaseClient _client;
  final CurrentUser _user;

  @override
  Future<Either<Failure, Profile>> getProfile() => _run((me) async {
    final row = await _client
        .from('profiles')
        .select(
          'id, username, display_name, avatar_url, color, calendar_visibility',
        )
        .eq('id', me)
        .single();
    return _profileFrom(row);
  });

  @override
  Future<Either<Failure, Profile>> updateProfile(ProfileDraft draft) =>
      _run((me) async {
        final clean = draft.normalized();
        final taken = await _client
            .from('profiles')
            .select('id')
            .eq('username', clean.username)
            .neq('id', me)
            .maybeSingle();
        if (taken != null) throw const UsernameTakenFailure();

        final path = clean.avatarPath;
        final avatarUrl = path == null ? null : await _upload(me, File(path));
        await _client
            .from('profiles')
            .update({
              'display_name': clean.displayName,
              'username': clean.username,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', me);
        // Auth metadata feeds the first screens before the profile loads.
        await _client.auth.updateUser(
          UserAttributes(
            data: {
              'display_name': clean.displayName,
              'username': clean.username,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
            },
          ),
        );
        final row = await _client
            .from('profiles')
            .select(
              'id, username, display_name, avatar_url, color, '
              'calendar_visibility',
            )
            .eq('id', me)
            .single();
        return _profileFrom(row);
      });

  @override
  Future<Either<Failure, Unit>> setColor(String color) => _run((me) async {
    await _client
        .from('profiles')
        .update({
          'color': color,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', me);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> setCalendarPublic({required bool value}) =>
      _run((me) async {
        await _client
            .from('profiles')
            .update({
              'calendar_visibility': value ? 'public' : 'private',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', me);
        return unit;
      });

  Future<String> _upload(String me, File file) async {
    final raw = file.path.split('.').last.toLowerCase();
    final ext = const ['jpg', 'jpeg', 'png', 'webp'].contains(raw)
        ? raw
        : 'jpg';
    final type = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final name = '$me/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bucket = _client.storage.from('avatars');
    await bucket.upload(
      name,
      file,
      fileOptions: FileOptions(contentType: type),
    );
    return bucket.getPublicUrl(name);
  }

  Profile _profileFrom(Map<String, dynamic> row) {
    final auth = _client.auth.currentUser;
    return Profile(
      id: row['id'] as String,
      displayName: (row['display_name'] as String?) ?? '',
      username: (row['username'] as String?) ?? '',
      email: auth?.email,
      avatarUrl: row['avatar_url'] as String?,
      color: row['color'] as String?,
      calendarPublic: row['calendar_visibility'] == 'public',
      memberSince: DateTime.tryParse(auth?.createdAt ?? '')?.toLocal(),
    );
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function(String me) body) async {
    final me = _user.id;
    if (me == null) return const Left(AuthFailure(message: 'Not signed in'));
    try {
      return Right(await body(me));
    } on Failure catch (f) {
      return Left(f);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on StorageException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    }
  }
}
