import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood.dart';
import 'package:kairotasks/features/dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import 'package:kairotasks/generated/app_localizations.dart';

/// Always draws 0, so every tap says "miau".
class _AlwaysZero implements math.Random {
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0.5;
  @override
  bool nextBool() => true;
}

Future<void> pumpMascot(
  WidgetTester tester,
  MascotMood mood, {
  bool reduced = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.golden(Brightness.light),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
          body: Center(
            child: KairoMascot(mood: mood, random: _AlwaysZero()),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('announces the mood in words', (tester) async {
    await pumpMascot(tester, MascotMood.happy);
    expect(
      find.bySemanticsLabel('Kairo the cat, happy: all tasks done today'),
      findsOneWidget,
    );
  });

  testWidgets('a tap can say meow, then the bubble goes away', (tester) async {
    await pumpMascot(tester, MascotMood.idle);

    await tester.tap(find.byType(KairoMascot));
    await tester.pump();
    expect(find.text('meow'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('meow'), findsNothing);
  });

  testWidgets('tapping a sleeping cat lets a z drift up', (tester) async {
    await pumpMascot(tester, MascotMood.sleeping);

    await tester.tap(find.byType(KairoMascot));
    await tester.pump();
    expect(find.text('z'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('keeps animating (breathing) when motion is allowed', (
    tester,
  ) async {
    await pumpMascot(tester, MascotMood.idle, reduced: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isTrue);
    // Unmount so the ambient ticker stops before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stays still under reduced motion', (tester) async {
    await pumpMascot(tester, MascotMood.idle);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
