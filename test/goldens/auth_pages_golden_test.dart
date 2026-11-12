import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kairotasks/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kairotasks/features/auth/presentation/pages/login_page.dart';
import 'package:kairotasks/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/golden.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  // Reduced motion holds Kairo still so every render matches.
  Widget still(BuildContext context, Widget child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  );

  goldenTest(
    'login_page',
    size: const Size(390, 844),
    builder: (context) {
      final auth = MockAuthBloc();
      when(() => auth.state).thenReturn(const AuthState());
      return still(
        context,
        BlocProvider<AuthBloc>.value(
          value: auth,
          child: LoginPage(now: DateTime(2026, 10, 21, 15), drift: 0.15),
        ),
      );
    },
  );

  goldenTest(
    'onboarding_page',
    size: const Size(390, 844),
    builder: (context) => still(context, const OnboardingPage()),
  );
}
