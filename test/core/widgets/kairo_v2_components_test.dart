import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/app/theme/kairo_colors.dart';
import 'package:kairotasks/core/widgets/kairo_button.dart';
import 'package:kairotasks/core/widgets/kairo_chip.dart';
import 'package:kairotasks/core/widgets/kairo_entrance.dart';
import 'package:kairotasks/core/widgets/kairo_tab_bar.dart';

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.golden(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('KairoChip', () {
    testWidgets('reports selection to semantics and calls onSelected', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        KairoChip(label: 'Hoy', selected: true, onSelected: () => taps++),
      );

      await tester.tap(find.text('Hoy'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(KairoChip)),
        isSemantics(label: 'Hoy', isButton: true, isSelected: true),
      );
    });

    testWidgets('is at least 44 pt tall', (tester) async {
      await pump(
        tester,
        KairoChip(label: 'Mañana', selected: false, onSelected: () {}),
      );
      expect(
        tester.getSize(find.byType(KairoChip)).height,
        greaterThanOrEqualTo(44),
      );
    });
  });

  group('KairoButton', () {
    testWidgets('filled is ink and accent is lime', (tester) async {
      await pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KairoButton(label: 'Primary', onPressed: () {}),
            KairoButton(
              label: 'Enfocar',
              variant: KairoButtonVariant.accent,
              onPressed: () {},
            ),
          ],
        ),
      );

      Color fillOf(String label) {
        final box = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return (box.decoration as ShapeDecoration).color!;
      }

      expect(fillOf('Primary'), KairoColors.light.ink);
      expect(fillOf('Enfocar'), KairoColors.light.lime);
    });
  });

  group('KairoTabBar', () {
    const items = [
      KairoTabItem(
        icon: CupertinoIcons.sun_max,
        activeIcon: CupertinoIcons.sun_max_fill,
        label: 'Hoy',
      ),
      KairoTabItem(
        icon: CupertinoIcons.calendar,
        activeIcon: CupertinoIcons.calendar,
        label: 'Planear',
      ),
    ];

    testWidgets('shows only the selected label and switches tabs', (
      tester,
    ) async {
      var index = -1;
      await pump(
        tester,
        KairoTabBar(items: items, currentIndex: 0, onTap: (i) => index = i),
      );

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Planear'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Planear'));
      expect(index, 1);
    });

    testWidgets('the center button creates', (tester) async {
      var created = 0;
      await pump(
        tester,
        KairoTabBar(
          items: items,
          currentIndex: 0,
          onTap: (_) {},
          onCreate: () => created++,
          createLabel: 'New task',
        ),
      );

      await tester.tap(find.bySemanticsLabel('New task'));
      expect(created, 1);
    });
  });

  group('KairoEntrance', () {
    testWidgets('starts lowered and transparent, then settles in place', (
      tester,
    ) async {
      await pump(tester, const KairoEntrance(index: 2, child: Text('Card')));

      double opacity() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
      double offsetY() => tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .transform!
          .getTranslation()
          .y;

      expect(opacity(), 0);
      expect(offsetY(), KairoEntrance.rise);
      // The cascade waits on a timer, which pumpAndSettle does not advance.
      await tester.pump(KairoEntrance.step * 2);
      await tester.pumpAndSettle();
      expect(opacity(), 1);
      expect(offsetY(), 0);
    });

    testWidgets('appears in place under reduced motion', (tester) async {
      await pump(
        tester,
        const KairoEntrance(index: 3, child: Text('Card')),
        reduceMotion: true,
      );

      final opacity = find.ancestor(
        of: find.text('Card'),
        matching: find.byType(AnimatedOpacity),
      );
      expect(opacity, findsNothing);
    });
  });
}
