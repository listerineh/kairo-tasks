class AppConstants {
  AppConstants._();

  static const String appName = 'KairoTasks';
  static const String appTagline = 'Your collaborative moment';

  // Supabase
  static const String supabaseUrl = 'https://gatdyxuqmdbllbmzejwh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhdGR5eHVxbWRibGxibXplandoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2MzcxMDYsImV4cCI6MjEwMzIxMzEwNn0.jHw54cYtSPo4b1Cu-J2h-Z-zjZos2W8yooVGKLY3-yc';

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
}
