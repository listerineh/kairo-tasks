import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/core/widgets/check_circle.dart';
import 'package:kairotasks/core/widgets/grouped_section.dart';
import 'package:kairotasks/core/widgets/kairo_avatar.dart';
import 'package:kairotasks/core/widgets/kairo_button.dart';
import 'package:kairotasks/core/widgets/kairo_segmented_control.dart';
import 'package:kairotasks/core/widgets/priority_badge.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/generated/app_localizations.dart';

Future<void> pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.golden(Brightness.light),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('KairoButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await pump(tester, KairoButton(label: 'Save', onPressed: () => taps++));

      await tester.tap(find.text('Save'));
      expect(taps, 1);
    });

    testWidgets('ignores taps while loading and keeps its label in '
        'semantics', (tester) async {
      var taps = 0;
      await pump(
        tester,
        KairoButton(label: 'Save', loading: true, onPressed: () => taps++),
      );

      await tester.tap(find.byType(KairoButton));
      expect(taps, 0);
      expect(find.bySemanticsLabel('Save'), findsOneWidget);
    });

    testWidgets('is at least 50 pt tall', (tester) async {
      await pump(tester, KairoButton(label: 'Save', onPressed: () {}));
      expect(
        tester.getSize(find.byType(KairoButton)).height,
        greaterThanOrEqualTo(50),
      );
    });
  });

  group('CheckCircle', () {
    testWidgets('toggles and exposes a 44 pt checked control', (tester) async {
      bool? changed;
      await pump(
        tester,
        CheckCircle(
          value: false,
          semanticLabel: 'Call the dentist',
          onChanged: (v) => changed = v,
        ),
      );

      expect(tester.getSize(find.byType(CheckCircle)), const Size(44, 44));
      expect(
        tester.getSemantics(find.byType(CheckCircle)),
        matchesSemantics(
          label: 'Call the dentist',
          hasCheckedState: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.byType(CheckCircle));
      expect(changed, isTrue);
    });
  });

  group('KairoSegmentedControl', () {
    testWidgets('reports a new selection only', (tester) async {
      final changes = <int>[];
      await pump(
        tester,
        SizedBox(
          width: 300,
          child: KairoSegmentedControl<int>(
            segments: const {0: 'Day', 1: 'Week', 2: 'Month'},
            selected: 0,
            onChanged: changes.add,
          ),
        ),
      );

      await tester.tap(find.text('Day'));
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(changes, [2]);
    });
  });

  test('KairoAvatar initials use first and last words', () {
    expect(KairoAvatar.initialsOf('María José Pérez'), 'MP');
    expect(KairoAvatar.initialsOf('luis'), 'L');
    expect(KairoAvatar.initialsOf('  '), '?');
  });

  testWidgets('PriorityBadge announces priority, not just color', (
    tester,
  ) async {
    await pump(tester, const PriorityBadge(priority: TaskPriority.urgent));
    expect(find.bySemanticsLabel('Priority: Urgent'), findsOneWidget);
  });

  test('GroupedRow hairline starts at the title', () {
    expect(const GroupedRow(title: 'A').separatorInset, 16);
    expect(
      const GroupedRow(title: 'A', leading: Icon(Icons.add)).separatorInset,
      56,
    );
  });
}
