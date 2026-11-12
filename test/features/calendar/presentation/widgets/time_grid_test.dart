import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/features/calendar/presentation/widgets/time_grid.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:kairotasks/generated/app_localizations.dart';

void main() {
  final day = DateTime(2026, 10, 20);
  // 01:00, so the grid opens scrolled to the top.
  final now = DateTime(2026, 10, 20, 1);
  const hour = 56.0;

  TaskEntity task(
    String id, {
    DateTime? start,
    DateTime? due,
    String owner = 'me',
  }) => TaskEntity(
    id: id,
    ownerId: owner,
    title: id,
    startDate: start,
    dueDate: due,
    createdAt: DateTime(2026),
  );

  late List<DateTime> created;
  late List<(String, DateTime)> moved;
  late List<String> tapped;

  setUp(() {
    created = [];
    moved = [];
    tapped = [];
  });

  Future<void> pump(
    WidgetTester tester,
    List<TaskEntity> tasks, {
    List<DateTime>? days,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.golden(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TimeGrid(
            days: days ?? [day],
            tasks: tasks,
            now: now,
            onTaskTap: (t) => tapped.add(t.id),
            onCreateAt: created.add,
            canMove: (t) => t.ownerId == 'me',
            onMove: (t, start) => moved.add((t.id, start)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Offset gridOrigin(WidgetTester tester) =>
      tester.getTopLeft(find.byType(SingleChildScrollView));

  testWidgets('places a block by its time', (tester) async {
    await pump(tester, [
      task(
        'a',
        start: DateTime(2026, 10, 20, 10),
        due: DateTime(2026, 10, 20, 11),
      ),
    ]);
    final top = tester.getTopLeft(find.text('a')).dy - gridOrigin(tester).dy;
    // 10:00 at 56 px per hour, plus a tall block's 6 px text padding.
    expect(top, closeTo(10 * hour + 6, 1));
  });

  testWidgets('date-only tasks go to the all-day strip', (tester) async {
    await pump(tester, [task('allday', due: day)]);
    expect(find.text('allday'), findsOneWidget);
    final y = tester.getTopLeft(find.text('allday')).dy;
    expect(y, lessThan(gridOrigin(tester).dy));
  });

  testWidgets('tapping an empty slot creates at the snapped time', (
    tester,
  ) async {
    await pump(tester, []);
    final origin = gridOrigin(tester);
    // 9:14 rounds to 9:15.
    await tester.tapAt(
      origin + const Offset(TimeGrid.gutterWidth + 40, (9 + 14 / 60) * hour),
    );
    expect(created, [DateTime(2026, 10, 20, 9, 15)]);
  });

  testWidgets('tapping a block opens it instead of creating', (tester) async {
    await pump(tester, [
      task(
        'a',
        start: DateTime(2026, 10, 20, 10),
        due: DateTime(2026, 10, 20, 11),
      ),
    ]);
    await tester.tap(find.text('a'));
    expect(tapped, ['a']);
    expect(created, isEmpty);
  });

  testWidgets('long-press drag moves a block in 15 minute steps', (
    tester,
  ) async {
    await pump(tester, [
      task(
        'a',
        start: DateTime(2026, 10, 20, 10),
        due: DateTime(2026, 10, 20, 11),
      ),
    ]);
    final gesture = await tester.startGesture(tester.getCenter(find.text('a')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    // 1 h 20 min down rounds to 1 h 15 min.
    await gesture.moveBy(const Offset(0, hour * (80 / 60)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moved, [('a', DateTime(2026, 10, 20, 11, 15))]);
  });

  testWidgets('dragging sideways in the week view changes the day', (
    tester,
  ) async {
    await pump(
      tester,
      [
        task(
          'a',
          start: DateTime(2026, 10, 20, 10),
          due: DateTime(2026, 10, 20, 11),
        ),
      ],
      days: [day, DateTime(2026, 10, 21)],
    );
    const column = (390 - TimeGrid.gutterWidth) / 2;
    final gesture = await tester.startGesture(tester.getCenter(find.text('a')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(column, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moved, [('a', DateTime(2026, 10, 21, 10))]);
  });

  testWidgets("friends' blocks cannot be dragged", (tester) async {
    await pump(tester, [
      task(
        'theirs',
        owner: 'ana',
        start: DateTime(2026, 10, 20, 10),
        due: DateTime(2026, 10, 20, 11),
      ),
    ]);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('theirs')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, hour * 2));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moved, isEmpty);
  });

  testWidgets('pinching out makes hours taller', (tester) async {
    await pump(tester, []);
    double contentHeight() => tester
        .renderObject<RenderBox>(
          find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(SizedBox),
              )
              .first,
        )
        .size
        .height;
    expect(contentHeight(), 24 * hour);

    final center = tester.getCenter(find.byType(SingleChildScrollView));
    final a = await tester.startGesture(center - const Offset(0, 50));
    final b = await tester.startGesture(center + const Offset(0, 50));
    await a.moveBy(const Offset(0, -25));
    await b.moveBy(const Offset(0, 25));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    // The span grew from 100 to 150 px: 1.5x.
    expect(contentHeight(), closeTo(24 * hour * 1.5, 1));
  });
}
