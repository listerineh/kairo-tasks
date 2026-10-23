import 'package:equatable/equatable.dart';

/// Whether the device can reach the server and how many local changes are
/// still waiting to be sent.
class TaskSyncStatus extends Equatable {
  const TaskSyncStatus({this.online = true, this.pending = 0});

  final bool online;
  final int pending;

  @override
  List<Object?> get props => [online, pending];
}
