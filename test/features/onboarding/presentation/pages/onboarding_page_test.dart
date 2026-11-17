import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:kairotasks/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => const MediaQuery(
            data: MediaQueryData(size: Size(390, 844), disableAnimations: true),
            child: OnboardingPage(),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, _) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('walks through the four steps and back', (tester) async {
    await pump(tester);
    expect(find.text("Hi, I'm Kairo."), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('One moment at a time.'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 2 of 4'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text("Hi, I'm Kairo."), findsOneWidget);
  });

  testWidgets('skip goes to the last step, and Get started finishes', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Better together.'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_onboarding'), isTrue);
  });
}
