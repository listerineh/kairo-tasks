import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/features/calendar/presentation/widgets/month_view.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/generated/app_localizations.dart';

void main() {
  final selected = DateTime(2026, 10, 20);

  TaskEntity task(String id, {DateTime? start, DateTime? due}) => TaskEntity(
    id: id,
    ownerId: 'me',
    title: id,
    startDate: start,
    dueDate: due,
    createdAt: DateTime(2026),
  );

  late List<DateTime> dates;
  late List<String> tapped;

  setUp(() {
    dates = [];
    tapped = [];
  });

  Future<void> pump(WidgetTester tester, List<TaskEntity> tasks) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.golden(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MonthView(
            selectedDate: selected,
            tasks: tasks,
            now: selected,
            onDateTap: dates.add,
            onTaskTap: (t) => tapped.add(t.id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the selected day, all-day first, then by time', (
    tester,
  ) async {
    await pump(tester, [
      task(
        'late',
        start: DateTime(2026, 10, 20, 15),
        due: DateTime(2026, 10, 20, 16),
      ),
      task('early', due: DateTime(2026, 10, 20, 9)),
      task('allday', due: DateTime(2026, 10, 20)),
      task('tomorrow', due: DateTime(2026, 10, 21, 9)),
    ]);
    final ys = [
      for (final t in ['allday', 'early', 'late'])
        tester.getTopLeft(find.text(t)).dy,
    ];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.text('tomorrow'), findsNothing);
    expect(find.text('All day'), findsOneWidget);

    await tester.tap(find.text('late'));
    expect(tapped, ['late']);
  });

  testWidgets('an empty day says nothing is planned', (tester) async {
    await pump(tester, []);
    expect(find.text('Nothing planned'), findsOneWidget);
  });

  testWidgets('tapping a day selects it', (tester) async {
    await pump(tester, []);
    await tester.tap(find.text('7'));
    expect(dates, [DateTime(2026, 10, 7)]);
  });

  testWidgets('shows at most three dots per day', (tester) async {
    await pump(tester, [
      for (var i = 0; i < 5; i++)
        task('t$i', due: DateTime(2026, 10, 3, 9 + i)),
    ]);
    final dayCell = find
        .ancestor(of: find.text('3'), matching: find.byType(Column))
        .first;
    final dots = find.descendant(
      of: dayCell,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
            w.constraints?.maxWidth == 5,
      ),
    );
    expect(dots, findsNWidgets(MonthView.maxDots));
  });
}
