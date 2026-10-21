import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/dashboard/presentation/pages/today_page.dart';
import '../../features/focus/presentation/pages/focus_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/social/presentation/pages/social_page.dart';
import '../../features/tasks/domain/entities/task_entity.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../gallery/gallery_page.dart';
import '../router/shell_scaffold.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter create(String initialLocation) {
    final instance = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: initialLocation,
      debugLogDiagnostics: false,
      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        final isLoggedIn = session != null;
        final isOnAuth =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/onboarding';

        // The debug gallery needs no session.
        if (state.matchedLocation == '/gallery') return null;
        // Tasks moved under Hoy; old links (notifications, login) still work.
        if (state.matchedLocation == '/tasks') return '/dashboard/tasks';
        if (!isLoggedIn && !isOnAuth) return '/login';
        if (isLoggedIn && isOnAuth) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: RouteNames.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/focus',
          builder: (context, state) =>
              FocusPage(initialTask: state.extra as TaskEntity?),
        ),
        if (kDebugMode)
          GoRoute(
            path: '/gallery',
            name: RouteNames.gallery,
            builder: (context, state) => const GalleryPage(),
          ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              ShellScaffold(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  name: RouteNames.dashboard,
                  builder: (context, state) => const TodayPage(),
                  routes: [
                    GoRoute(
                      path: 'tasks',
                      name: RouteNames.tasks,
                      builder: (context, state) => const TasksPage(),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/calendar',
                  name: RouteNames.calendar,
                  builder: (context, state) => const CalendarPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/social',
                  name: RouteNames.social,
                  builder: (context, state) => const SocialPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  name: RouteNames.profile,
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    return instance;
  }
}
