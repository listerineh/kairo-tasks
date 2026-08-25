class AppConstants {
  AppConstants._();

  static const String appName = 'KairoTasks';
  static const String appTagline = 'Your collaborative moment';

  // Supabase - injected via --dart-define-from-file=.env
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
}
