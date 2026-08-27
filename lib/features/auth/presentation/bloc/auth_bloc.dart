import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/logger_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.displayName,
    this.username,
  });
  final String email;
  final String password;
  final String displayName;
  final String? username;

  @override
  List<Object?> get props => [email, password, displayName, username];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthAppleSignInRequested extends AuthEvent {
  const AuthAppleSignInRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

// State
enum AuthStatus { unknown, authenticated, unauthenticated, loading, error }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthAppleSignInRequested>(_onAppleSignIn);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final session = _client.auth.currentSession;
    if (session != null) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: _client.auth.currentUser,
        ),
      );
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerService.instance.info(
      'Signing in',
      data: {'operation': 'auth.signIn', 'provider': 'email'},
    );
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final response = await _client.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
        ),
      );
      LoggerService.instance.info(
        'Sign in successful',
        data: {
          'operation': 'auth.signIn',
          'provider': 'email',
          'user_id': response.user?.id,
        },
      );
    } on AuthException catch (e) {
      LoggerService.instance.error(
        'Sign in failed',
        data: {
          'operation': 'auth.signIn',
          'provider': 'email',
          'error': e.message,
        },
      );
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerService.instance.info(
      'Signing up',
      data: {'operation': 'auth.signUp', 'provider': 'email'},
    );
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final response = await _client.auth.signUp(
        email: event.email,
        password: event.password,
        data: {
          'display_name': event.displayName,
          'username': event.username ?? event.email.split('@').first,
        },
      );
      if (response.user != null && response.session != null) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: response.user,
          ),
        );
        LoggerService.instance.info(
          'Sign up successful',
          data: {
            'operation': 'auth.signUp',
            'provider': 'email',
            'user_id': response.user?.id,
          },
        );
      } else {
        // Email confirmation required
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Check your email to confirm your account.',
          ),
        );
      }
    } on AuthException catch (e) {
      LoggerService.instance.error(
        'Sign up failed',
        data: {
          'operation': 'auth.signUp',
          'provider': 'email',
          'error': e.message,
        },
      );
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerService.instance.info(
      'Signing in with Google',
      data: {'operation': 'auth.signIn', 'provider': 'google'},
    );
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

      if (webClientId.isEmpty) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Google Web Client ID is missing.',
          ),
        );
        return;
      }

      // Generate nonce for token verification
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: Platform.isIOS && iosClientId.isNotEmpty
            ? iosClientId
            : null,
        serverClientId: webClientId,
        nonce: hashedNonce,
      );

      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Failed to get Google ID token.',
          ),
        );
        return;
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (response.user == null || response.session == null) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Google sign-in did not return a valid session.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
        ),
      );
      LoggerService.instance.info(
        'Google sign in successful',
        data: {
          'operation': 'auth.signIn',
          'provider': 'google',
          'user_id': response.user?.id,
        },
      );
    } on AuthException catch (e) {
      LoggerService.instance.error(
        'Google sign in failed',
        data: {
          'operation': 'auth.signIn',
          'provider': 'google',
          'error': e.message,
        },
      );
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.message,
        ),
      );
    } on Exception catch (e) {
      LoggerService.instance.error(
        'Google sign in failed',
        data: {
          'operation': 'auth.signIn',
          'provider': 'google',
          'error': e.toString(),
        },
      );
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Google sign-in failed: $e',
        ),
      );
    }
  }

  Future<void> _onAppleSignIn(
    AuthAppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerService.instance.info(
      'Signing in with Apple',
      data: {'operation': 'auth.signIn', 'provider': 'apple'},
    );
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      // Generate a secure nonce for Apple sign-in
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Failed to get Apple ID token.',
          ),
        );
        return;
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
        ),
      );
      LoggerService.instance.info(
        'Apple sign in successful',
        data: {
          'operation': 'auth.signIn',
          'provider': 'apple',
          'user_id': response.user?.id,
        },
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      } else {
        LoggerService.instance.error(
          'Apple sign in failed',
          data: {
            'operation': 'auth.signIn',
            'provider': 'apple',
            'error': e.message,
          },
        );
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Apple sign-in failed: ${e.message}',
          ),
        );
      }
    } on AuthException catch (e) {
      LoggerService.instance.error(
        'Apple sign in failed',
        data: {
          'operation': 'auth.signIn',
          'provider': 'apple',
          'error': e.message,
        },
      );
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      LoggerService.instance.error(
        'Apple sign in failed',
        data: {
          'operation': 'auth.signIn',
          'provider': 'apple',
          'error': e.toString(),
        },
      );
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Apple sign-in failed. Please try again.',
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerService.instance.info(
      'Signing out',
      data: {'operation': 'auth.signOut'},
    );
    await _client.auth.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
    LoggerService.instance.info(
      'Sign out successful',
      data: {'operation': 'auth.signOut'},
    );
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}
