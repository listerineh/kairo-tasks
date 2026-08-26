import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/tasks/presentation/bloc/tasks_bloc.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_service.dart';

class KairoTasksApp extends StatefulWidget {
  const KairoTasksApp({super.key});

  @override
  State<KairoTasksApp> createState() => _KairoTasksAppState();
}

class _KairoTasksAppState extends State<KairoTasksApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.init();
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
      child: MaterialApp.router(
        title: 'KairoTasks',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeService.instance.themeMode.value,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
