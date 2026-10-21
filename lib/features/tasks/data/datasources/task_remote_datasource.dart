import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';

/// Raw Supabase access for tasks and their shares. Throws
/// [ServerException]; mapping to entities happens in the repository.
abstract class TaskRemoteDataSource {
  /// Visible tasks (own and shared with me, via RLS) with the shares join.
  Future<List<Map<String, dynamic>>> fetchTasks();

  /// Inserts a task row and returns its id.
  Future<String> insertTask(Map<String, dynamic> row);

  Future<void> updateTask(String id, Map<String, dynamic> changes);

  Future<void> deleteTask(String id);

  /// Makes [taskId]'s shares by [ownerId] exactly [friendIds].
  Future<void> replaceShares(
    String taskId,
    String ownerId,
    List<String> friendIds,
  );

  /// Fires whenever tasks or shares addressed to [userId] change remotely.
  Stream<void> changes(String userId);
}

@LazySingleton(as: TaskRemoteDataSource)
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _selectColumns = '''
    *,
    shared_tasks!task_id(
      task_id,
      shared_by_id,
      shared_with_id,
      shared_with:profiles!shared_with_id(id, username, display_name, avatar_url),
      shared_by:profiles!shared_by_id(id, username, display_name, avatar_url)
    )
  ''';

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTasks() => _guard(() async {
    final rows = await _client
        .from('tasks')
        .select(_selectColumns)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  });

  @override
  Future<String> insertTask(Map<String, dynamic> row) => _guard(() async {
    final created = await _client
        .from('tasks')
        .insert(row)
        .select('id')
        .single();
    return created['id'] as String;
  });

  @override
  Future<void> updateTask(String id, Map<String, dynamic> changes) =>
      _guard(() => _client.from('tasks').update(changes).eq('id', id));

  @override
  Future<void> deleteTask(String id) =>
      _guard(() => _client.from('tasks').delete().eq('id', id));

  @override
  Future<void> replaceShares(
    String taskId,
    String ownerId,
    List<String> friendIds,
  ) => _guard(() async {
    final rows = await _client
        .from('shared_tasks')
        .select('shared_with_id')
        .eq('task_id', taskId)
        .eq('shared_by_id', ownerId);
    final current = {
      for (final r in List<Map<String, dynamic>>.from(rows))
        r['shared_with_id'] as String,
    };
    final desired = friendIds.where((id) => id != ownerId).toSet();

    final toAdd = desired.difference(current);
    if (toAdd.isNotEmpty) {
      await _client.from('shared_tasks').insert([
        for (final id in toAdd)
          {'task_id': taskId, 'shared_by_id': ownerId, 'shared_with_id': id},
      ]);
    }
    final toRemove = current.difference(desired);
    if (toRemove.isNotEmpty) {
      await _client
          .from('shared_tasks')
          .delete()
          .eq('task_id', taskId)
          .inFilter('shared_with_id', toRemove.toList());
    }
  });

  @override
  Stream<void> changes(String userId) {
    late final StreamController<void> controller;
    final subscriptions = <StreamSubscription<Object?>>[];
    controller = StreamController<void>(
      onListen: () {
        void forward(Object? _) => controller.add(null);
        subscriptions
          ..add(
            _client
                .from('tasks')
                .stream(primaryKey: ['id'])
                .listen(forward, onError: controller.addError),
          )
          ..add(
            _client
                .from('shared_tasks')
                .stream(primaryKey: ['id'])
                .eq('shared_with_id', userId)
                .listen(forward, onError: controller.addError),
          );
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }
}
