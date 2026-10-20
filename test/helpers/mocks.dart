import 'package:kairotasks/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}
