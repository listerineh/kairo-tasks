import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:kairotasks/generated/app_localizations.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/dashboard/presentation/widgets/streak_celebration.dart';
import '../features/tasks/presentation/bloc/tasks_bloc.dart';
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
          create: (_) => AuthBloc()..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => TasksBloc()..add(const TasksLoadRequested()),
        ),
      ],
      child: BlocListener<TasksBloc, TasksState>(
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
          context.read<TasksBloc>().add(const TasksClearStreakCelebration());
        },
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
              localizationsDelegates: AppLocalizations.localizationsDelegates +
                  [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
              supportedLocales: const [Locale('es'), Locale('en')],
            ),
          ),
        ),
      ),
    );
  }
}
