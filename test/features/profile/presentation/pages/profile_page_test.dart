import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/core/services/haptics_service.dart';
import 'package:kairotasks/core/services/preferences_service.dart';
import 'package:kairotasks/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kairotasks/features/profile/domain/entities/profile.dart';
import 'package:kairotasks/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:kairotasks/features/profile/presentation/pages/profile_page.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:kairotasks/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  const profile = Profile(id: 'me', displayName: 'Sebas', username: 'sebas');

  late MockProfileCubit cubit;
  late MockAuthBloc auth;
  late PreferencesService prefs;

  setUpAll(() => registerFallbackValue(const AuthSignOutRequested()));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cubit = MockProfileCubit();
    auth = MockAuthBloc();
    prefs = PreferencesService(HapticsService());
    when(() => auth.state).thenReturn(const AuthState());
    when(() => cubit.setCalendarPublic(value: any(named: 'value')))
        .thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, ProfileState state) async {
    when(() => cubit.state).thenReturn(state);
    final tasks = MockTasksBloc();
    when(() => tasks.state).thenReturn(const TasksState());
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 2000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<TasksBloc>.value(value: tasks),
              BlocProvider<AuthBloc>.value(value: auth),
              BlocProvider<ProfileCubit>.value(value: cubit),
            ],
            child: ProfileView(preferences: prefs, userId: 'me'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  const ready = ProfileState(status: ProfileStatus.ready, profile: profile);

  testWidgets('shows who I am', (tester) async {
    await pump(tester, ready);
    expect(find.text('Sebas'), findsOneWidget);
    expect(find.text('@sebas'), findsOneWidget);
  });

  testWidgets('the calendar switch goes through the cubit', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.byType(CupertinoSwitch).at(0));
    verify(() => cubit.setCalendarPublic(value: true)).called(1);
  });

  testWidgets('reduce motion is stored in preferences', (tester) async {
    await pump(tester, ready);
    expect(prefs.reduceMotion.value, isFalse);
    await tester.tap(find.byType(CupertinoSwitch).at(1));
    await tester.pump();
    expect(prefs.reduceMotion.value, isTrue);
  });

  testWidgets('signing out asks the auth bloc', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.text('Sign Out'));
    verify(() => auth.add(const AuthSignOutRequested())).called(1);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    when(() => cubit.load()).thenAnswer((_) async {});
    await pump(tester, const ProfileState(status: ProfileStatus.failure));
    await tester.tap(find.text('Try again'));
    verify(() => cubit.load()).called(1);
  });
}
