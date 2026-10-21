import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/core/widgets/check_circle.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/features/tasks/presentation/widgets/task_row.dart';
import 'package:kairotasks/generated/app_localizations.dart';

void main() {
  final now = DateTime(2026, 10, 20, 15);

  TaskEntity task({
    DateTime? due,
    DateTime? start,
    TaskStatus status = TaskStatus.pending,
    List<Map<String, dynamic>> sharedWith = const [],
  }) => TaskEntity(
    id: 't',
    ownerId: 'me',
    title: 'Call the dentist',
    dueDate: due,
    startDate: start,
    status: status,
    sharedWith: sharedWith,
    createdAt: DateTime(2026),
  );

  Future<void> pump(
    WidgetTester tester,
    TaskEntity t, {
    VoidCallback? onToggle,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.golden(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: Scaffold(
            body: TaskRow(task: t, now: now, onToggle: onToggle ?? () {}),
          ),
        ),
      ),
    );
  }

  testWidgets('today shows a time range', (tester) async {
    await pump(
      tester,
      task(
        start: DateTime(2026, 10, 20, 10),
        due: DateTime(2026, 10, 20, 10, 30),
      ),
    );
    expect(find.text('10:00 – 10:30'), findsOneWidget);
  });

  testWidgets('tomorrow and later days are named', (tester) async {
    await pump(tester, task(due: DateTime(2026, 10, 21, 9)));
    expect(find.text('Tomorrow, 09:00'), findsOneWidget);

    await pump(tester, task(due: DateTime(2026, 11, 3)));
    expect(find.text('Nov 3'), findsOneWidget);
  });

  testWidgets('a date-only task due today says Today', (tester) async {
    await pump(tester, task(due: DateTime(2026, 10, 20)));
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('lists who it is shared with', (tester) async {
    await pump(
      tester,
      task(
        due: DateTime(2026, 10, 20, 18),
        sharedWith: [
          {'display_name': 'Ana'},
          {'username': 'luis'},
        ],
      ),
    );
    expect(find.textContaining('Ana, luis'), findsOneWidget);
  });

  testWidgets('the check circle toggles the task', (tester) async {
    var toggles = 0;
    await pump(tester, task(), onToggle: () => toggles++);
    await tester.tap(find.byType(CheckCircle));
    expect(toggles, 1);
  });
}
