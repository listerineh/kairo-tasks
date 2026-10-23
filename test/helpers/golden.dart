import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/generated/app_localizations.dart';

/// The three renders every component is reviewed in
/// (docs/redesign-plan.md §4).
enum GoldenVariant {
  light,
  dark,

  /// Light theme at 200% text, the Dynamic Type stress case.
  largeText,
}

/// Registers one golden test per [GoldenVariant] for the widget built by
/// [builder], saved as `<name>.<variant>.png` next to the calling test.
///
/// The large-text variant doubles the canvas height so growth is visible
/// rather than clipped; an overflow there fails the test, which is the point.
void goldenTest(
  String name, {
  required WidgetBuilder builder,
  Size size = const Size(390, 240),
}) {
  for (final variant in GoldenVariant.values) {
    testWidgets('$name (${variant.name})', (tester) async {
      final large = variant == GoldenVariant.largeText;
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = large ? Size(size.width, size.height * 2) : size;
      addTearDown(tester.view.reset);
      // flutter_test paints shadows as solid shapes by default; goldens should
      // show the real blurred elevation. Restored before the test ends, where
      // flutter_test checks it.
      debugDisableShadows = false;
      try {
        await _pumpAndMatch(tester, name, variant, builder);
      } finally {
        debugDisableShadows = true;
      }
    });
  }
}

Future<void> _pumpAndMatch(
  WidgetTester tester,
  String name,
  GoldenVariant variant,
  WidgetBuilder builder,
) async {
  final large = variant == GoldenVariant.largeText;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.golden(
        variant == GoldenVariant.dark ? Brightness.dark : Brightness.light,
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
        child: child!,
      ),
      home: Builder(builder: builder),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$name.${variant.name}.png'),
  );
}

/// A plain grouped-background page with [child] at the top, for components
/// that don't bring their own scaffold.
class GoldenCanvas extends StatelessWidget {
  const GoldenCanvas({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Align(alignment: Alignment.topCenter, child: child),
      ),
    );
  }
}
