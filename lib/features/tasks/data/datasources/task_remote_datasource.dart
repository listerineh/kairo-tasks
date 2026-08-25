import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks();
  Future<TaskModel> getTaskById(String id);
  Future<TaskModel> createTask(TaskModel task);
  Future<TaskModel> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Stream<List<TaskModel>> watchTasks();
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  @override
  Future<List<TaskModel>> getTasks() async {
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('owner_id', _userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TaskModel> getTaskById(String id) async {
    try {
      final response =
          await _client.from('tasks').select().eq('id', id).single();
      return TaskModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await _client
          .from('tasks')
          .insert(task.toInsertJson(_userId))
          .select()
          .single();
      return TaskModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await _client
          .from('tasks')
          .update(task.toUpdateJson())
          .eq('id', task.id)
          .select()
          .single();
      return TaskModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _client.from('tasks').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<TaskModel>> watchTasks() {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('owner_id', _userId)
        .order('created_at', ascending: false)
        .map(
          (data) => data.map(TaskModel.fromJson).toList(),
        );
  }
}
