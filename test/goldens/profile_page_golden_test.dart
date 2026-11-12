import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kairotasks/core/services/haptics_service.dart';
import 'package:kairotasks/core/services/preferences_service.dart';
import 'package:kairotasks/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kairotasks/features/profile/domain/entities/profile.dart';
import 'package:kairotasks/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:kairotasks/features/profile/presentation/pages/kairo_page.dart';
import 'package:kairotasks/features/profile/presentation/pages/profile_page.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/golden.dart';
import '../helpers/mocks.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  final now = DateTime(2026, 10, 21, 10, 40);
  const profile = Profile(
    id: 'me',
    displayName: 'Sebastián Álvarez',
    username: 'listerineh',
    email: 'sebas@example.com',
    color: '#3E8A62',
    calendarPublic: true,
  );
  final tasks = [
    TaskEntity(
      id: '1',
      ownerId: 'me',
      title: 'Call the dentist',
      dueDate: DateTime(2026, 10, 21, 11),
      createdAt: DateTime(2026),
    ),
    TaskEntity(
      id: '2',
      ownerId: 'me',
      title: 'Walk',
      dueDate: DateTime(2026, 10, 21, 8),
      status: TaskStatus.completed,
      completedAt: DateTime(2026, 10, 21, 8, 30),
      createdAt: DateTime(2026),
    ),
  ];

  Widget wrap(BuildContext context, Widget child) {
    final tasksBloc = MockTasksBloc();
    when(() => tasksBloc.state)
        .thenReturn(TasksState(status: TasksStatus.loaded, tasks: tasks));
    final auth = MockAuthBloc();
    when(() => auth.state).thenReturn(const AuthState());
    // Reduced motion freezes Kairo and the entrance cascade.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TasksBloc>.value(value: tasksBloc),
          BlocProvider<AuthBloc>.value(value: auth),
        ],
        child: child,
      ),
    );
  }

  goldenTest(
    'profile_page',
    size: const Size(390, 1500),
    builder: (context) {
      final cubit = MockProfileCubit();
      when(() => cubit.state).thenReturn(
        const ProfileState(status: ProfileStatus.ready, profile: profile),
      );
      return wrap(
        context,
        BlocProvider<ProfileCubit>.value(
          value: cubit,
          child: ProfileView(
            preferences: PreferencesService(HapticsService()),
            userId: 'me',
            now: now,
          ),
        ),
      );
    },
  );

  goldenTest(
    'kairo_page',
    size: const Size(390, 1400),
    builder: (context) => wrap(context, KairoPage(now: now, userId: 'me')),
  );
}
