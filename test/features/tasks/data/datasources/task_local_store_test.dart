import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/tasks/data/datasources/task_local_store.dart';
import 'package:kairotasks/features/tasks/data/sync/pending_op.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final op = PendingOp(
    kind: PendingKind.delete,
    taskId: 'a',
    at: DateTime.utc(2026, 10, 22),
  );

  test('rows and outbox round-trip per user', () async {
    final store = PrefsTaskLocalStore();
    expect(await store.readRows('me'), isNull);
    expect(await store.readOutbox('me'), isEmpty);

    await store.writeRows('me', [
      {'id': 'a', 'title': 'A'},
    ]);
    await store.writeOutbox('me', [op]);

    expect(await store.readRows('me'), [
      {'id': 'a', 'title': 'A'},
    ]);
    expect(await store.readOutbox('me'), [op]);
    // Another account sees nothing.
    expect(await store.readRows('someone'), isNull);
  });

  test('clear forgets the user', () async {
    final store = PrefsTaskLocalStore();
    await store.writeRows('me', const []);
    await store.writeOutbox('me', [op]);
    await store.clear('me');
    expect(await store.readRows('me'), isNull);
    expect(await store.readOutbox('me'), isEmpty);
  });
}
