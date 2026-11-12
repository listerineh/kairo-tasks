import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:kairotasks/generated/app_localizations.dart';

import '../core/services/preferences_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/dashboard/presentation/widgets/streak_celebration.dart';
import '../features/tasks/presentation/bloc/tasks_bloc.dart';
import 'di/injection.dart';
import 'locale/locale_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_service.dart';

class KairoApp extends StatelessWidget {
  const KairoApp({required this.router, super.key});

  /// Created once in `main` and shared through DI, so locale or theme
  /// changes never rebuild the navigation stack.
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => getIt<TasksBloc>()..add(const TasksLoadRequested()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          // Tasks load at startup, before a session may exist; load them
          // again whenever someone signs in.
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                current.status == AuthStatus.authenticated &&
                previous.user?.id != current.user?.id,
            listener: (context, _) =>
                context.read<TasksBloc>().add(const TasksLoadRequested()),
          ),
          BlocListener<TasksBloc, TasksState>(
            listenWhen: (previous, current) =>
                current.streakToCelebrate != null &&
                previous.streakToCelebrate != current.streakToCelebrate,
            listener: (context, state) {
              final navigator = router.routerDelegate.navigatorKey.currentState;
              if (navigator != null && navigator.mounted) {
                showStreakCelebration(
                  navigator.context,
                  state.streakToCelebrate!,
                );
              }
              context.read<TasksBloc>().add(
                const TasksClearStreakCelebration(),
              );
            },
          ),
        ],
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.instance.themeMode,
          builder: (context, themeMode, _) => ValueListenableBuilder<Locale>(
            valueListenable: LocaleService.instance.locale,
            builder: (context, locale, _) => MaterialApp.router(
              title: 'Kairo',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: router,
              locale: locale,
              localizationsDelegates:
                  AppLocalizations.localizationsDelegates +
                  [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
              supportedLocales: const [Locale('es'), Locale('en')],
              builder: (context, child) => _WithPreferences(child: child!),
            ),
          ),
        ),
      ),
    );
  }
}

/// Applies the in-app accessibility preferences (reduce motion, text size)
/// on top of the system ones.
class _WithPreferences extends StatelessWidget {
  const _WithPreferences({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final prefs = registeredPreferences;
    if (prefs == null) return child;
    return ListenableBuilder(
      listenable: Listenable.merge([prefs.reduceMotion, prefs.textScale]),
      builder: (context, _) =>
          MediaQuery(data: prefs.apply(MediaQuery.of(context)), child: child),
    );
  }
}
