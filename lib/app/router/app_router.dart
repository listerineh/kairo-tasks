import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../router/shell_scaffold.dart';
import 'route_names.dart';

CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/tasks',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/tasks';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/tasks',
            name: RouteNames.tasks,
            pageBuilder: (context, state) => _fadePage(const TasksPage(), state),
          ),
          GoRoute(
            path: '/calendar',
            name: RouteNames.calendar,
            pageBuilder: (context, state) => _fadePage(const CalendarPage(), state),
          ),
          GoRoute(
            path: '/social',
            name: RouteNames.social,
            pageBuilder: (context, state) => _fadePage(_placeholder('Social'), state),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            pageBuilder: (context, state) => _fadePage(const ProfilePage(), state),
          ),
        ],
      ),
    ],
  );

  static Widget _placeholder(String title) {
    return Scaffold(
      body: Center(
        child: Text(title, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
