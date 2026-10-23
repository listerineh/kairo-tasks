import 'package:equatable/equatable.dart';

/// What a queued change does to a task row.
enum PendingKind { create, update, delete }

/// A local change waiting in the outbox until the server confirms it.
///
/// [changes] holds the row fields: the whole new row for a create, the
/// changed columns for an update, nothing for a delete. [shares] is the
/// friend list to apply after the row (null leaves shares alone). [at] is
/// when the user made the change, compared with the server's `updated_at`
/// for last-write-wins.
class PendingOp extends Equatable {
  const PendingOp({
    required this.kind,
    required this.taskId,
    required this.at,
    this.changes = const {},
    this.shares,
  });

  factory PendingOp.fromJson(Map<String, dynamic> json) => PendingOp(
    kind: PendingKind.values.byName(json['kind'] as String),
    taskId: json['task_id'] as String,
    at: DateTime.parse(json['at'] as String),
    changes: Map<String, dynamic>.from(
      (json['changes'] as Map?) ?? const <String, dynamic>{},
    ),
    shares: (json['shares'] as List?)?.cast<String>(),
  );

  final PendingKind kind;
  final String taskId;
  final DateTime at;
  final Map<String, dynamic> changes;
  final List<String>? shares;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'task_id': taskId,
    'at': at.toUtc().toIso8601String(),
    'changes': changes,
    if (shares != null) 'shares': shares,
  };

  @override
  List<Object?> get props => [kind, taskId, at, changes, shares];
}
