import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kairotasks/generated/app_localizations.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/dashboard/presentation/widgets/streak_celebration.dart';
import '../features/tasks/presentation/bloc/tasks_bloc.dart';
import 'locale/locale_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_service.dart';

class KairoApp extends StatefulWidget {
  const KairoApp({required this.initialLocation, super.key});

  final String initialLocation;

  @override
  State<KairoApp> createState() => _KairoAppState();
}

class _KairoAppState extends State<KairoApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.init();
    LocaleService.instance.init();
  }

  @override
  void dispose() {
    ThemeService.instance.themeMode.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ThemeService.instance.themeMode.addListener(_onThemeChanged);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc()..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => TasksBloc()..add(const TasksLoadRequested()),
        ),
      ],
      child: ValueListenableBuilder<Locale>(
        valueListenable: LocaleService.instance.locale,
        builder: (context, locale, _) {
          return BlocListener<TasksBloc, TasksState>(
            listenWhen: (previous, current) =>
                current.streakToCelebrate != null &&
                previous.streakToCelebrate != current.streakToCelebrate,
            listener: (context, state) {
              showStreakCelebration(context, state.streakToCelebrate!);
              context.read<TasksBloc>().add(const TasksClearStreakCelebration());
            },
            child: MaterialApp.router(
              title: 'Kairo',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeService.instance.themeMode.value,
              routerConfig: AppRouter.create(widget.initialLocation),
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates +
                  [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
              supportedLocales: const [Locale('es'), Locale('en')],
            ),
          );
        },
      ),
    );
  }
}
