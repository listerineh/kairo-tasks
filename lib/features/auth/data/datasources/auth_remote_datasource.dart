import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
  });

  Future<AuthResponse> signInWithGoogle();

  Future<AuthResponse> signInWithApple();

  Future<void> signOut();

  User? get currentUser;

  Stream<AuthState> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'username': username,
        },
      );
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.kairotasks.kairotasks://login-callback',
      );
      if (!response) {
        throw const ServerException(message: 'Google sign-in was cancelled');
      }
      // OAuth returns via deep link, auth state stream handles the result
      // Return a placeholder - the actual session comes through authStateChanges
      throw const ServerException(
        message: 'Waiting for OAuth callback',
      );
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<AuthResponse> signInWithApple() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.kairotasks.kairotasks://login-callback',
      );
      if (!response) {
        throw const ServerException(message: 'Apple sign-in was cancelled');
      }
      throw const ServerException(
        message: 'Waiting for OAuth callback',
      );
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
