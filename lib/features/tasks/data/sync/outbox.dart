import 'pending_op.dart';

/// Pure rules for the task outbox (docs/redesign-plan.md § V10): how a new
/// change merges with the ones already waiting, how waiting changes show on
/// top of the server rows, and when a change still wins against the server.

/// Adds [op] to [queue], keeping at most one change per task:
/// - create + update: still a create, with the update's fields.
/// - create + delete: nothing to send.
/// - update + update: one update with both sets of fields.
/// - anything + delete: a delete.
///
/// [firstInFlight] means `queue.first` is being sent right now: a change to
/// that task is appended instead of merged, so it isn't lost when the sent
/// one is removed.
List<PendingOp> enqueue(
  List<PendingOp> queue,
  PendingOp op, {
  bool firstInFlight = false,
}) {
  final index = queue.lastIndexWhere((o) => o.taskId == op.taskId);
  if (index == -1 || (index == 0 && firstInFlight)) return [...queue, op];

  final earlier = queue[index];
  final rest = [...queue]..removeAt(index);
  final merged = switch ((earlier.kind, op.kind)) {
    (PendingKind.create, PendingKind.delete) => null,
    (_, PendingKind.delete) => op,
    (PendingKind.create, _) => PendingOp(
      kind: PendingKind.create,
      taskId: op.taskId,
      at: op.at,
      changes: {...earlier.changes, ...op.changes},
      shares: op.shares ?? earlier.shares,
    ),
    // A delete followed by anything else can't happen from the UI (the
    // task is gone); keep the delete.
    (PendingKind.delete, _) => earlier,
    _ => PendingOp(
      kind: PendingKind.update,
      taskId: op.taskId,
      at: op.at,
      changes: {...earlier.changes, ...op.changes},
      shares: op.shares ?? earlier.shares,
    ),
  };
  // Keep the merged change where the first one was, so order is kept.
  if (merged == null) return rest;
  return [...rest]..insert(index, merged);
}

/// The server [rows] with the waiting [queue] applied, so the list shows
/// what the user did offline until the server catches up.
List<Map<String, dynamic>> overlay(
  List<Map<String, dynamic>> rows,
  List<PendingOp> queue,
) {
  final byId = {for (final r in rows) r['id'] as String: r};
  final created = <Map<String, dynamic>>[];
  for (final op in queue) {
    switch (op.kind) {
      case PendingKind.create:
        if (!byId.containsKey(op.taskId)) {
          created.add({...op.changes, 'id': op.taskId});
        }
      case PendingKind.update:
        final row = byId[op.taskId];
        if (row != null) byId[op.taskId] = {...row, ...op.changes};
      case PendingKind.delete:
        byId.remove(op.taskId);
    }
  }
  // New tasks first, like the server's newest-first order.
  return [
    ...created.reversed,
    for (final r in rows)
      if (byId[r['id']] case final row?) row,
  ];
}

/// Last-write-wins for a waiting update: it goes through unless the server
/// row was changed after it ([serverRow]'s `updated_at` is later than the
/// change) or the task is gone.
bool updateStillWins(PendingOp op, Map<String, dynamic>? serverRow) {
  if (serverRow == null) return false;
  final raw = serverRow['updated_at'];
  if (raw is! String) return true;
  final serverAt = DateTime.tryParse(raw);
  return serverAt == null || !serverAt.isAfter(op.at);
}
