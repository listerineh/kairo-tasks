import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/tasks/data/sync/outbox.dart';
import 'package:kairotasks/features/tasks/data/sync/pending_op.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 22, 9);
  final t1 = DateTime.utc(2026, 10, 22, 9, 5);

  PendingOp create(String id, {String title = 'New'}) => PendingOp(
    kind: PendingKind.create,
    taskId: id,
    at: t0,
    changes: {'id': id, 'title': title, 'owner_id': 'me'},
  );
  PendingOp update(String id, Map<String, dynamic> changes, {DateTime? at}) =>
      PendingOp(
        kind: PendingKind.update,
        taskId: id,
        at: at ?? t1,
        changes: changes,
      );
  PendingOp delete(String id) =>
      PendingOp(kind: PendingKind.delete, taskId: id, at: t1);

  group('enqueue', () {
    test('a create absorbs later updates', () {
      final queue = enqueue([create('a')], update('a', {'title': 'Edited'}));
      expect(queue.single.kind, PendingKind.create);
      expect(queue.single.changes['title'], 'Edited');
      expect(queue.single.changes['owner_id'], 'me');
    });

    test('create then delete leaves nothing to send', () {
      expect(enqueue([create('a')], delete('a')), isEmpty);
    });

    test('two updates merge, the later fields win', () {
      final queue = enqueue([
        update('a', {'title': 'One', 'priority': 'high'}, at: t0),
      ], update('a', {'title': 'Two'}));
      expect(queue.single.changes, {'title': 'Two', 'priority': 'high'});
      expect(queue.single.at, t1);
    });

    test('an update then a delete becomes a delete', () {
      final queue = enqueue([
        update('a', {'title': 'x'}),
      ], delete('a'));
      expect(queue.single.kind, PendingKind.delete);
    });

    test('changes to different tasks keep their order', () {
      final queue = enqueue(
        enqueue([create('a')], create('b')),
        update('a', {'title': 'A2'}),
      );
      expect(queue.map((o) => o.taskId), ['a', 'b']);
    });

    test('a change to the task being sent is appended, not merged', () {
      final queue = enqueue([create('a')], delete('a'), firstInFlight: true);
      expect(queue.map((o) => o.kind), [
        PendingKind.create,
        PendingKind.delete,
      ]);
      // A third change merges into the appended one, not the in-flight one.
      expect(enqueue(queue, delete('a'), firstInFlight: true).length, 2);
    });

    test('later shares replace earlier ones; null keeps them', () {
      final first = PendingOp(
        kind: PendingKind.update,
        taskId: 'a',
        at: t0,
        shares: const ['ana'],
      );
      expect(enqueue([first], update('a', {'title': 'x'})).single.shares, [
        'ana',
      ]);
    });
  });

  group('overlay', () {
    final rows = [
      {'id': 'a', 'title': 'Server A'},
      {'id': 'b', 'title': 'Server B'},
    ];

    test('shows offline creates first, edits in place, hides deletes', () {
      final shown = overlay(rows, [
        create('c', title: 'Offline'),
        update('a', {'title': 'Edited A'}),
        delete('b'),
      ]);
      expect(shown.map((r) => r['title']), ['Offline', 'Edited A']);
    });

    test('a create the server already has is not shown twice', () {
      final shown = overlay(
        [
          {'id': 'c', 'title': 'Synced'},
        ],
        [create('c')],
      );
      expect(shown.single['title'], 'Synced');
    });
  });

  group('updateStillWins (last-write-wins)', () {
    test('wins when the server row is older', () {
      expect(
        updateStillWins(update('a', {}), {'updated_at': t0.toIso8601String()}),
        isTrue,
      );
    });

    test('loses when the server changed after the local edit', () {
      final later = t1.add(const Duration(minutes: 1));
      expect(
        updateStillWins(update('a', {}), {
          'updated_at': later.toIso8601String(),
        }),
        isFalse,
      );
    });

    test('loses when the task was deleted on the server', () {
      expect(updateStillWins(update('a', {}), null), isFalse);
    });
  });

  test('ops survive a JSON round trip', () {
    final op = PendingOp(
      kind: PendingKind.update,
      taskId: 'a',
      at: t1,
      changes: const {'title': 'x'},
      shares: const ['ana'],
    );
    expect(PendingOp.fromJson(op.toJson()), op);
  });
}
