import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/dashboard/domain/mascot/mascot_mood.dart';
import 'package:kairotasks/features/profile/presentation/widgets/kairo_lines.dart';
import 'package:kairotasks/generated/app_localizations.dart';

void main() {
  Future<String> line(
    WidgetTester tester,
    MascotMood mood,
    DateTime now,
  ) async {
    late String result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            result = kairoLine(context, mood, now: now);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('sleeping at night says it is late', (tester) async {
    final text = await line(
      tester,
      MascotMood.sleeping,
      DateTime(2026, 11, 12, 2),
    );
    expect(text, "It's late. What's left will still be here tomorrow.");
  });

  testWidgets('sleeping on a rest day does not say it is late', (tester) async {
    final text = await line(
      tester,
      MascotMood.sleeping,
      DateTime(2026, 11, 12, 12),
    );
    expect(text, "Nothing planned today. I'm resting too.");
  });
}
