import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Who is signed in, without exposing the auth client to callers.
abstract class CurrentUser {
  /// The signed-in user's id, or null when signed out.
  String? get id;
}

@LazySingleton(as: CurrentUser)
class SupabaseCurrentUser implements CurrentUser {
  SupabaseCurrentUser(this._client);

  final SupabaseClient _client;

  @override
  String? get id => _client.auth.currentUser?.id;
}
