import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/tasks/presentation/bloc/tasks_bloc.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class KairoTasksApp extends StatelessWidget {
  const KairoTasksApp({super.key});

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
      child: MaterialApp.router(
        title: 'KairoTasks',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
