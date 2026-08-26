# KairoTasks - Architecture

> Clean Architecture with BLoC pattern, feature-first organization.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                          │
│  Widgets ← BLoC/Cubit (State Management)                │
│  Pages, Widgets, BLoCs, Events, States                  │
├─────────────────────────────────────────────────────────┤
│                      DOMAIN                             │
│  Entities, Repository Contracts, Use Cases              │
│  (Pure Dart - No Flutter, No External Packages)         │
├─────────────────────────────────────────────────────────┤
│                       DATA                              │
│  Repository Implementations, Data Sources, Models/DTOs  │
│  (Supabase, Local Storage, Network)                     │
└─────────────────────────────────────────────────────────┘
```

### The Dependency Rule

**Source code dependencies point inward:**
- Presentation → Domain (allowed)
- Data → Domain (allowed)
- Domain → Nothing (pure Dart)
- Presentation ↛ Data (forbidden - use DI)
- Data ↛ Presentation (forbidden)

---

## Folder Structure

```
lib/
├── main.dart                     # Entry point
├── app/                          # Application-level configuration
│   ├── app.dart                  # Root MaterialApp widget
│   ├── di/                       # Dependency injection (get_it + injectable)
│   │   ├── injection.dart        # GetIt setup
│   │   └── injection.config.dart # Generated code
│   ├── router/                   # Navigation (go_router)
│   │   ├── app_router.dart       # Route definitions
│   │   ├── route_names.dart      # Named route constants
│   │   └── shell_scaffold.dart   # Bottom navigation shell
│   └── theme/                    # Design system implementation
│       ├── app_theme.dart        # ThemeData builder
│       ├── app_colors.dart       # Color tokens
│       └── app_spacing.dart      # Spacing & sizing tokens
├── core/                         # Shared utilities (no business logic)
│   ├── constants/                # App-wide constants
│   ├── errors/                   # Failure & Exception classes
│   ├── extensions/               # Dart/Flutter extensions
│   ├── network/                  # Connectivity helpers
│   ├── utils/                    # Formatters, validators, helpers
│   └── widgets/                  # Shared reusable widgets
└── features/                     # Feature modules
    ├── auth/                     # Authentication
    ├── tasks/                    # Task management (CRUD, priority)
    ├── calendar/                 # Calendar view
    ├── social/                   # Friends, shared calendars
    ├── notifications/            # Push + in-app notifications
    └── profile/                  # User settings & profile
```

### Feature Module Structure

Each feature follows the same internal structure:

```
features/[feature_name]/
├── data/
│   ├── datasources/              # Remote & local data access
│   │   ├── feature_remote_datasource.dart
│   │   └── feature_local_datasource.dart
│   ├── models/                   # DTOs (JSON serializable)
│   │   └── feature_model.dart
│   └── repositories/            # Concrete implementations
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/                # Business objects (equatable)
│   │   └── feature_entity.dart
│   ├── repositories/            # Abstract contracts
│   │   └── feature_repository.dart
│   └── usecases/                # Single-responsibility business logic
│       └── get_feature.dart
└── presentation/
    ├── bloc/                    # State management
    │   └── feature_bloc.dart
    ├── pages/                   # Full-screen widgets
    │   └── feature_page.dart
    └── widgets/                 # Feature-specific widgets
        └── feature_widget.dart
```

---

## Data Flow

### Unidirectional Data Flow (BLoC Pattern)

```
User Interaction
      │
      ▼
  ┌─────────┐     ┌─────────┐     ┌──────────────┐
  │  Event  │ ──→ │  BLoC   │ ──→ │    State     │
  └─────────┘     └────┬────┘     └──────┬───────┘
                       │                  │
                       ▼                  ▼
                  ┌─────────┐        ┌─────────┐
                  │Use Case │        │   UI    │
                  └────┬────┘        │ Rebuild │
                       │             └─────────┘
                       ▼
                  ┌──────────┐
                  │Repository│
                  └────┬─────┘
                       │
                       ▼
                  ┌──────────┐
                  │  Remote  │ ← Supabase
                  │  Local   │ ← SharedPrefs / Drift
                  └──────────┘
```

### Repository Pattern

```dart
// Domain layer defines the contract
abstract class TaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getTasks();
  Stream<List<TaskEntity>> watchTasks();
}

// Data layer implements it
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remoteDataSource, this._localDataSource);
  
  final TaskRemoteDataSource _remoteDataSource;
  final TaskLocalDataSource _localDataSource;
  
  @override
  Future<Either<Failure, List<TaskEntity>>> getTasks() async {
    try {
      final models = await _remoteDataSource.getTasks();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
```

---

## Database Schema (Supabase / Postgres)

### Tables

#### `profiles`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, references auth.users(id) |
| username | TEXT | UNIQUE, NOT NULL |
| display_name | TEXT | NOT NULL |
| avatar_url | TEXT | nullable |
| color | TEXT | DEFAULT '#4A6741' |
| calendar_visibility | TEXT | DEFAULT 'private', CHECK('public','private') |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `tasks`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() |
| owner_id | UUID | FK → profiles(id), NOT NULL |
| title | TEXT | NOT NULL |
| description | TEXT | nullable |
| priority | TEXT | DEFAULT 'medium', CHECK('urgent','high','medium','low') |
| status | TEXT | DEFAULT 'pending', CHECK('pending','in_progress','completed') |
| due_date | TIMESTAMPTZ | nullable |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `shared_tasks`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| task_id | UUID | FK → tasks(id) ON DELETE CASCADE |
| shared_with_id | UUID | FK → profiles(id) |
| shared_by_id | UUID | FK → profiles(id) |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| | | UNIQUE(task_id, shared_with_id) |

#### `friendships`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| requester_id | UUID | FK → profiles(id) |
| addressee_id | UUID | FK → profiles(id) |
| status | TEXT | DEFAULT 'pending', CHECK('pending','accepted','rejected') |
| requester_color | TEXT | DEFAULT '#6B8FA3' |
| addressee_color | TEXT | DEFAULT '#6B8FA3' |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| | | UNIQUE(requester_id, addressee_id) |

### Row Level Security (RLS)

All tables have RLS enabled. Key policies:

- **tasks**: Users can CRUD their own tasks. Shared users can view/edit tasks explicitly shared with them. Public friend tasks are read through the `get_public_friend_tasks` RPC, not RLS.
- **shared_tasks**: Only task owners can share. Only participants can view.
- **friendships**: Users can see their own friendship records.
- **profiles**: Public read for username/display_name. Only owner can update.

### Public Calendar Access (RPC)

Friend calendar data is exposed through the `get_public_friend_tasks` RPC:
- The function is defined as `SECURITY DEFINER` so it bypasses RLS and returns all accepted friend tasks
- Each result includes the owner's `calendar_visibility`
- The client renders "Busy" blocks for private calendars and full task data for public calendars

### Realtime Subscriptions

Enabled on:
- `tasks` (INSERT, UPDATE, DELETE) - for shared task updates
- `shared_tasks` (INSERT, DELETE) - new shares / removed shares
- `friendships` (INSERT, UPDATE) - friend requests and color changes
- `profiles` (UPDATE) - own profile and friend color changes for calendar rendering

---

## Realtime Communication Flow

```
┌─────────────┐                              ┌─────────────┐
│  User A     │                              │  User B     │
│  (Flutter)  │                              │  (Flutter)  │
└──────┬──────┘                              └──────┬──────┘
       │                                            │
       │ 1. Creates/edits task                      │
       ▼                                            │
┌──────────────┐                                    │
│   Supabase   │                                    │
│   Database   │                                    │
└──────┬───────┘                                    │
       │                                            │
       │ 2. Postgres Change detected                │
       ▼                                            │
┌──────────────┐                                    │
│  Supabase    │  3. Broadcasts to subscribed       │
│  Realtime    │ ──────────────────────────────────→ │
└──────┬───────┘    clients                         │
       │                                            ▼
       │ 4. If user offline,              ┌─────────────────┐
       │    trigger Edge Function         │  BLoC updates   │
       ▼                                  │  state → UI     │
┌──────────────┐                          │  recomposes     │
│ Edge Function│                          └─────────────────┘
│ → FCM Push   │
└──────────────┘
```

### Subscription Strategy

```dart
// In the data source, subscribe to task changes
final subscription = supabase
  .from('tasks')
  .stream(primaryKey: ['id'])
  .eq('owner_id', userId)
  .listen((data) {
    // Emit updated tasks to the repository stream
  });

// For shared tasks, join subscription
final sharedSubscription = supabase
  .from('shared_tasks')
  .stream(primaryKey: ['id'])
  .eq('shared_with_id', userId)
  .listen((data) {
    // Fetch full task details and emit
  });
```

---

## Internationalization (i18n/l10n)

The app uses Flutter's `flutter_localizations` with ARB files and code generation:

- Translations are stored in `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`
- `flutter gen-l10n` generates `AppLocalizations` and `AppLocalizations.localizationsDelegates` for `MaterialApp`
- All UI strings are accessed via `context.l10n` (an extension on `BuildContext`)
- Spanish (`es`) is the default locale; `supportedLocales` is set to `es` and `en`, with device-locale fallback
- Adding a new string requires updating both ARB files and regenerating localizations

## Dependency Injection

Using `get_it` with `injectable` for code generation.

### Registration Order
1. **Core services** (network, storage)
2. **Data sources** (remote, local)
3. **Repositories** (implementations bound to interfaces)
4. **BLoCs/Cubits** (registered as factory - new instance per use)

### Example
```dart
@module
abstract class AppModule {
  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}

@LazySingleton(as: TaskRepository)
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(@Named('remote') this._remote);
  // ...
}

@injectable
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc(this._taskRepository) : super(const TasksState());
  // ...
}
```

---

## Navigation

Using `go_router` with declarative routing.

### Route Structure
```
/login              → LoginPage
/tasks              → TasksPage (tab 0)
/tasks/:id          → TaskDetailPage
/tasks/create       → CreateTaskPage
/calendar           → CalendarPage (tab 1)
/social             → SocialPage (tab 2)
/social/friends     → FriendsListPage
/profile            → ProfilePage (tab 3)
/profile/settings   → SettingsPage
```

### Shell Route
The main tabs (tasks, calendar, social, profile) share a `ShellRoute` with `BottomNavigationBar`, preserving state between tabs.

---

## Adding a New Feature

1. Create the feature directory: `lib/features/new_feature/`
2. Define entities in `domain/entities/`
3. Define repository contract in `domain/repositories/`
4. Implement data layer (`data/datasources/`, `data/models/`, `data/repositories/`)
5. Create BLoC in `presentation/bloc/`
6. Build pages and widgets in `presentation/pages/` and `presentation/widgets/`
7. Register dependencies in DI (`@injectable`, `@LazySingleton`)
8. Add routes in `app/router/app_router.dart`
9. Run `dart run build_runner build --delete-conflicting-outputs`

---

## Testing Strategy

### Unit Tests
- Domain: Test entities, use cases (pure logic)
- Data: Test repository implementations with mocked data sources
- BLoC: Test event → state transitions with `bloc_test`

### Widget Tests
- Test individual widgets with mocked BLoC
- Verify rendering, interactions, accessibility

### Integration Tests
- Test full feature flows (create task, toggle complete, etc.)
- Use Supabase local development for backend tests (future)

### File Naming
```
test/
├── features/
│   └── tasks/
│       ├── domain/
│       │   └── entities/
│       │       └── task_entity_test.dart
│       ├── data/
│       │   └── repositories/
│       │       └── task_repository_impl_test.dart
│       └── presentation/
│           └── bloc/
│               └── tasks_bloc_test.dart
└── core/
    └── ...
```
