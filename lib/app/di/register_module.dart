import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Third-party instances that can't carry injectable annotations.
@module
abstract class RegisterModule {
  // Supabase.initialize runs in main before configureDependencies.
  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}
