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

import '../../core/services/haptics_service.dart' as _i239;
import '../../core/session/current_user.dart' as _i369;
import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/calendar/data/calendar_module.dart' as _i371;
import '../../features/calendar/data/repositories/calendar_repository_impl.dart'
    as _i712;
import '../../features/calendar/domain/repositories/calendar_repository.dart'
    as _i241;
import '../../features/calendar/domain/usecases/load_friend_calendar.dart'
    as _i410;
import '../../features/calendar/domain/usecases/watch_calendar_changes.dart'
    as _i158;
import '../../features/calendar/presentation/cubit/calendar_cubit.dart'
    as _i131;
import '../../features/social/data/repositories/friends_repository_impl.dart'
    as _i880;
import '../../features/social/data/social_module.dart' as _i684;
import '../../features/social/domain/repositories/friends_repository.dart'
    as _i555;
import '../../features/social/domain/usecases/get_friends.dart' as _i893;
import '../../features/tasks/data/datasources/task_remote_datasource.dart'
    as _i25;
import '../../features/tasks/data/repositories/task_repository_impl.dart'
    as _i20;
import '../../features/tasks/data/services/notification_task_reminders.dart'
    as _i509;
import '../../features/tasks/data/tasks_module.dart' as _i473;
import '../../features/tasks/domain/repositories/task_repository.dart' as _i148;
import '../../features/tasks/domain/services/task_reminders.dart' as _i18;
import '../../features/tasks/domain/usecases/create_task.dart' as _i602;
import '../../features/tasks/domain/usecases/delete_task.dart' as _i840;
import '../../features/tasks/domain/usecases/set_task_completed.dart' as _i155;
import '../../features/tasks/domain/usecases/update_task.dart' as _i739;
import '../../features/tasks/domain/usecases/watch_tasks.dart' as _i517;
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
    final socialModule = _$SocialModule();
    final tasksModule = _$TasksModule();
    final calendarModule = _$CalendarModule();
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i239.HapticsService>(() => _i239.HapticsService());
    gh.lazySingleton<_i18.TaskReminders>(
      () => _i509.NotificationTaskReminders(),
    );
    gh.lazySingleton<_i369.CurrentUser>(
      () => _i369.SupabaseCurrentUser(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i25.TaskRemoteDataSource>(
      () => _i25.TaskRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i797.AuthBloc>(
      () => _i797.AuthBloc(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
      () => _i161.AuthRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i555.FriendsRepository>(
      () => _i880.FriendsRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i369.CurrentUser>(),
      ),
    );
    gh.lazySingleton<_i241.CalendarRepository>(
      () => _i712.CalendarRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i369.CurrentUser>(),
      ),
    );
    gh.lazySingleton<_i148.TaskRepository>(
      () => _i20.TaskRepositoryImpl(
        gh<_i25.TaskRemoteDataSource>(),
        gh<_i369.CurrentUser>(),
      ),
    );
    gh.factory<_i893.GetFriends>(
      () => socialModule.getFriends(gh<_i555.FriendsRepository>()),
    );
    gh.factory<_i517.WatchTasks>(
      () => tasksModule.watchTasks(gh<_i148.TaskRepository>()),
    );
    gh.factory<_i602.CreateTask>(
      () => tasksModule.createTask(gh<_i148.TaskRepository>()),
    );
    gh.factory<_i739.UpdateTask>(
      () => tasksModule.updateTask(gh<_i148.TaskRepository>()),
    );
    gh.factory<_i155.SetTaskCompleted>(
      () => tasksModule.setTaskCompleted(gh<_i148.TaskRepository>()),
    );
    gh.factory<_i840.DeleteTask>(
      () => tasksModule.deleteTask(gh<_i148.TaskRepository>()),
    );
    gh.factory<_i410.LoadFriendCalendar>(
      () => calendarModule.loadFriendCalendar(gh<_i241.CalendarRepository>()),
    );
    gh.factory<_i158.WatchCalendarChanges>(
      () => calendarModule.watchCalendarChanges(gh<_i241.CalendarRepository>()),
    );
    gh.factory<_i447.TasksBloc>(
      () => _i447.TasksBloc(
        gh<_i517.WatchTasks>(),
        gh<_i602.CreateTask>(),
        gh<_i739.UpdateTask>(),
        gh<_i155.SetTaskCompleted>(),
        gh<_i840.DeleteTask>(),
        gh<_i18.TaskReminders>(),
        gh<_i369.CurrentUser>(),
      ),
    );
    gh.factory<_i131.CalendarCubit>(
      () => _i131.CalendarCubit(
        gh<_i410.LoadFriendCalendar>(),
        gh<_i158.WatchCalendarChanges>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

class _$SocialModule extends _i684.SocialModule {}

class _$TasksModule extends _i473.TasksModule {}

class _$CalendarModule extends _i371.CalendarModule {}
