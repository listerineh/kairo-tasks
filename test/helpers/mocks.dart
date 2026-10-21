import 'package:bloc_test/bloc_test.dart';
import 'package:kairotasks/core/session/current_user.dart';
import 'package:kairotasks/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:kairotasks/features/tasks/domain/services/task_reminders.dart';
import 'package:kairotasks/features/tasks/domain/usecases/create_task.dart';
import 'package:kairotasks/features/tasks/domain/usecases/delete_task.dart';
import 'package:kairotasks/features/tasks/domain/usecases/set_task_completed.dart';
import 'package:kairotasks/features/tasks/domain/usecases/update_task.dart';
import 'package:kairotasks/features/tasks/domain/usecases/watch_tasks.dart';
import 'package:kairotasks/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

class MockTaskReminders extends Mock implements TaskReminders {}

class MockWatchTasks extends Mock implements WatchTasks {}

class MockCreateTask extends Mock implements CreateTask {}

class MockUpdateTask extends Mock implements UpdateTask {}

class MockSetTaskCompleted extends Mock implements SetTaskCompleted {}

class MockDeleteTask extends Mock implements DeleteTask {}

class FakeCurrentUser implements CurrentUser {
  FakeCurrentUser([this.id = 'me']);

  @override
  final String? id;
}

class MockTasksBloc extends MockBloc<TasksEvent, TasksState>
    implements TasksBloc {}
