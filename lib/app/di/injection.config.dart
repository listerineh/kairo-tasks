// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/tasks/data/datasources/task_remote_datasource.dart'
    as _i25;
import '../../features/tasks/data/repositories/task_repository_impl.dart'
    as _i20;
import '../../features/tasks/domain/repositories/task_repository.dart' as _i148;
import '../../features/tasks/presentation/bloc/tasks_bloc.dart' as _i447;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i25.TaskRemoteDataSource>(
      () => _i25.TaskRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i797.AuthBloc>(
      () => _i797.AuthBloc(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i447.TasksBloc>(
      () => _i447.TasksBloc(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
      () => _i161.AuthRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i148.TaskRepository>(
      () => _i20.TaskRepositoryImpl(gh<_i25.TaskRemoteDataSource>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
