import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kairotasks/features/auth/presentation/pages/login_page.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import 'package:kairotasks/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc auth;

  setUpAll(() => registerFallbackValue(const AuthGoogleSignInRequested()));

  setUp(() {
    auth = MockAuthBloc();
    when(() => auth.state).thenReturn(const AuthState());
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 900),
            disableAnimations: true,
          ),
          child: BlocProvider<AuthBloc>.value(
            value: auth,
            child: LoginPage(now: DateTime(2026, 10, 21, 9), drift: 0),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  MascotMood mood(WidgetTester tester) =>
      tester.widget<KairoMascot>(find.byType(KairoMascot)).mood;

  testWidgets('greets by the time of day', (tester) async {
    await pump(tester);
    expect(find.text('Good morning'), findsOneWidget);
  });

  testWidgets('Kairo closes his eyes for a hidden password', (tester) async {
    await pump(tester);
    expect(mood(tester), MascotMood.idle);

    await tester.tap(find.widgetWithText(TextField, 'Password'));
    await tester.pump(const Duration(seconds: 1));
    expect(mood(tester), MascotMood.sleeping);
    expect(find.text("I'm not looking, promise."), findsOneWidget);

    await tester.tap(find.byTooltip('Password'));
    await tester.pump(const Duration(seconds: 1));
    expect(mood(tester), MascotMood.idle);
  });

  testWidgets('an empty submit makes Kairo sad and sends nothing', (
    tester,
  ) async {
    await pump(tester);
    // The segmented control says "Sign In" too; the button comes last.
    await tester.tap(find.text('Sign In').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(mood(tester), MascotMood.sad);
    verifyNever(() => auth.add(any()));
    await tester.pump(const Duration(seconds: 3));
    expect(mood(tester), MascotMood.idle);
  });

  testWidgets('signing in sends the credentials', (tester) async {
    await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret123',
    );
    await tester.tap(find.text('Sign In').last);
    verify(
      () => auth.add(
        const AuthSignInRequested(
          email: 'ana@example.com',
          password: 'secret123',
        ),
      ),
    ).called(1);
  });
}
