import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/core/widgets/swipe_actions.dart';

void main() {
  late List<String> fired;

  Future<void> pump(WidgetTester tester) {
    fired = [];
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.golden(Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 56,
              child: SwipeActions(
                leading: SwipeAction(
                  icon: Icons.check,
                  label: 'Complete',
                  color: Colors.green,
                  onTriggered: () => fired.add('complete'),
                ),
                trailing: [
                  SwipeAction(
                    icon: Icons.delete,
                    label: 'Delete',
                    color: Colors.red,
                    onTriggered: () => fired.add('delete'),
                  ),
                  SwipeAction(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: Colors.grey,
                    onTriggered: () => fired.add('edit'),
                  ),
                ],
                child: const ColoredBox(
                  color: Colors.white,
                  child: SizedBox.expand(child: Text('Row')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a full swipe right commits the leading action', (tester) async {
    await pump(tester);
    await tester.drag(find.text('Row'), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(fired, ['complete']);
  });

  testWidgets('a full swipe left commits the outermost trailing action', (
    tester,
  ) async {
    await pump(tester);
    await tester.drag(find.text('Row'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(fired, ['delete']);
  });

  testWidgets('a short swipe opens the buttons; tapping one triggers it', (
    tester,
  ) async {
    await pump(tester);
    await tester.drag(find.text('Row'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(fired, isEmpty);
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(fired, ['edit']);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('a tiny swipe springs back closed', (tester) async {
    await pump(tester);
    await tester.timedDrag(
      find.text('Row'),
      const Offset(-20, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsNothing);
    expect(fired, isEmpty);
  });

  testWidgets('exposes every action to assistive technologies', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    final node = tester.getSemantics(find.byType(SwipeActions));
    final labels = node.getSemanticsData().customSemanticsActionIds!.map(
      (id) => CustomSemanticsAction.getAction(id)!.label,
    );
    expect(labels, containsAll(['Complete', 'Delete', 'Edit']));
    handle.dispose();
  });
}
