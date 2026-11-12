# Kairo - Architecture

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
│   │   └── shell_scaffold.dart   # Shell with the floating KairoTabBar
│   ├── locale/                   # Locale management
│   │   └── locale_service.dart   # Selected Locale persistence
│   ├── gallery/                  # Debug-only component gallery (/gallery)
│   ├── widgets/                  # Shared app-level widgets
│   │   └── notification_bell.dart # Bell with the unread badge
│   └── theme/                    # Design system implementation
│       ├── app_theme.dart        # ThemeData builder (light and dark)
│       ├── kairo_colors.dart     # Color tokens (ThemeExtension)
│       ├── kairo_typography.dart # Type scale (ThemeExtension, Manrope)
│       ├── app_motion.dart       # Springs and the reduced-motion switch
│       ├── app_spacing.dart      # Spacing, radii and sizing tokens
│       └── theme_service.dart    # Selected ThemeMode persistence
├── core/                         # Shared utilities (no business logic)
│   ├── constants/                # App-wide constants
│   ├── errors/                   # Failure & Exception classes
│   ├── extensions/               # Dart/Flutter extensions
│   ├── network/                  # NetworkInfo (connectivity_plus)
│   ├── services/                 # Notifications, haptics, preferences, logger
│   ├── session/                  # CurrentUser (who is signed in)
│   ├── utils/                    # Formatters, validators, helpers
│   └── widgets/                  # Shared components (buttons, cards, sheet, tab bar…)
└── features/                     # Feature modules
    ├── auth/                     # Authentication
    ├── onboarding/               # First-launch tour
    ├── dashboard/                # Hoy (TodaySummary) and Kairo the cat (mascot/)
    ├── tasks/                    # Task management (CRUD, priority, offline-first)
    ├── calendar/                 # Planear: day, week and month views
    ├── social/                   # Juntos: friends, shared tasks, nudges
    ├── notifications/            # Push + in-app notifications
    ├── focus/                    # Focus sessions (ADHD-friendly)
    └── profile/                  # Yo: profile, settings and Kairo's page
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
|| completed_at | TIMESTAMPTZ | nullable |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

The `completed_at` column is set by a database trigger when `status` changes to `'completed'`, and cleared when it reverts to another status. Streak calculations use this column to count only the day a task was completed, not the day it was created or last edited.

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

#### `nudges`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| sender_id | UUID | FK → profiles(id) |
| recipient_id | UUID | FK → profiles(id) |
| task_id | UUID | FK → tasks(id) |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

A nudge is a gentle push about a shared task. Inserting one sends a push to the recipient.

### Row Level Security (RLS)

All tables have RLS enabled. Key policies:

- **tasks**: Users can CRUD their own tasks. Shared users can view/edit tasks explicitly shared with them. Public friend tasks are read through the `get_public_friend_tasks` RPC, not RLS.
- **shared_tasks**: Only task owners can share. Only participants can view.
- **friendships**: Users can see their own friendship records.
- **profiles**: Public read for username/display_name. Only owner can update.
- **nudges**: Only between accepted friends, about a task both can see, and at most one per friend and task every 30 minutes.

### Public Calendar Access (RPC)

Friend calendar data is exposed through the `get_public_friend_tasks` RPC:
- The function is `SECURITY DEFINER`, so it bypasses RLS and returns all accepted friend tasks
- It uses an internal `viewer_id UUID := auth.uid()` variable (not a `current_user` parameter) to identify the calling user
- Each result includes the owner's `calendar_visibility`
- The client renders "Busy" blocks for private calendars and full task data for public calendars

### Realtime Subscriptions

Enabled on:
- `tasks` (INSERT, UPDATE, DELETE) - for shared task updates
- `shared_tasks` (INSERT, DELETE) - new shares / removed shares
- `friendships` (INSERT, UPDATE) - friend requests and color changes
- `profiles` (UPDATE) - own profile and friend color changes for calendar rendering

---

## Offline-First Tasks

Tasks work without a connection (`TaskRepositoryImpl`, V 01.35.00):

| Piece | Where | Role |
| --- | --- | --- |
| `TaskLocalStore` | `tasks/data/datasources/task_local_store.dart` | The last server rows and the outbox, per user, in `SharedPreferences` |
| `PendingOp` | `tasks/data/sync/pending_op.dart` | One waiting change: create (the whole row), update (changed columns), delete; plus shares and the time it was made |
| `enqueue` / `overlay` / `updateStillWins` | `tasks/data/sync/outbox.dart` | Pure rules: merge changes per task, show waiting changes on top of server rows, last-write-wins |
| `NetworkInfo` | `core/network/network_info.dart` | `connectivity_plus`; coming back online triggers a sync |

- **Reading:** `watchTasks` emits the stored copy first, then each server fetch (which is stored again). Waiting changes are always laid on top. Errors reach the UI only when there is nothing stored to show.
- **Writing:** create, edit, complete and delete go to the outbox and show immediately. New tasks get their id on the device (UUID v4). Writes return `Right` as long as someone is signed in.
- **Sending:** in order, one at a time, under a lock so writes and sends never race. A network error (`NetworkException`: offline or a 15 s timeout) leaves the change waiting. A server error drops it, and the next fetch shows the server's version.
  - A change made while the same task's change is in flight is appended instead of merged, so it isn't lost.
  - A create the server already has (`23505`) is sent again as an update.
- **Conflicts:** an update loses if the server row's `updated_at` is newer than the local edit, or if the task is gone (last-write-wins).
- **Hint:** `SyncStatusPill` on Hoy shows "Sin conexión · tus cambios se guardan aquí" or "Sincronizando N cambios" from `watchSyncStatus`.

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
- Spanish (`es`) remains the default; the user can override the in-app locale from `ProfilePage`
- `LocaleService` (in `lib/app/locale/locale_service.dart`) manages and persists the selected `Locale` in `SharedPreferences` under the key `app_locale`
- `KairoApp` wraps the `MaterialApp` in a `ValueListenableBuilder<Locale>` that rebuilds from `LocaleService.instance.locale`
- The language switcher in `ProfilePage` calls `LocaleService.instance.setLocale(...)` and applies the change immediately, without a restart
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
/onboarding         → OnboardingPage
/login              → LoginPage
/dashboard          → TodayPage (tab Hoy)
/dashboard/tasks    → TasksPage (the full task list)
/calendar           → CalendarPage (tab Planear)
/social             → SocialPage (tab Juntos)
/profile            → ProfilePage (tab Yo)
/profile/kairo      → Kairo's page
/notifications      → NotificationsPage
/focus              → FocusPage (takes an optional task as `extra`)
/gallery            → Component gallery (debug builds only)
```

Old `/tasks` links redirect to `/dashboard/tasks`. Tasks are created and edited in sheets (`showTaskForm`, `showTaskDetail`), not routes.

`main` computes the initial route and registers the router in DI once, so locale and theme changes never rebuild the navigation stack:
- Signed in: `/dashboard`
- Signed out: `/login`, or `/onboarding` if `has_seen_onboarding` has not been set

A redirect sends signed-out users to `/login` and signed-in users away from it.

### Shell Route
The four tabs share a `StatefulShellRoute` with the floating `KairoTabBar` (`ShellScaffold`), preserving each tab's state. The bar's center ＋ opens the task form.

---

## Notifications

- `NotificationService` is a singleton in `lib/core/services/notification_service.dart`
- Android FCM: token stored in `profiles.fcm_token`, refresh updates Supabase
- Foreground messages are shown as local notifications
- `onMessageOpenedApp` and `getInitialMessage` navigate with the app's router
- Payload `type` values (`friend_request`, `shared_task`, `task_due`, etc.) map to routes (`/social`, `/dashboard/tasks`, `/calendar`); a nudge opens `/social`
- iOS: push notification toggles are now active; remote delivery still needs a paid Apple Developer account for APNs
- Streak reminders: 23:00 close-to-losing and 00:00:01 lost-streak notifications
- The `NotificationBell` on Hoy shows the unread badge and opens `/notifications`
- Focus round-end notifications are scheduled locally with `zonedSchedule` (through the `FocusAlarm` port)
- Soft persistent reminders (`scheduleSoftReminder`) are scheduled from `TaskDetailSheet` and cancelled when a new one replaces it

## Focus Mode

- `FocusSession` (`features/focus/domain/`, pure) holds the session: four rounds of 25 minutes, 5-minute rests, a 15-minute rest after the fourth, and +5 minutes. It stores the **end timestamp**, not ticks, so the countdown survives backgrounding.
- `FocusCubit` (`features/focus/presentation/cubit/`) is a `@lazySingleton`: the session keeps running when the user leaves the screen. It takes a clock, so tests use a fake one.
- `FocusAlarm` is the port for the round-end notification; `NotificationFocusAlarm` implements it with `NotificationService`.
- `FocusPage` (`/focus`) is dark in every theme. Hoy opens it from the "Ahora" card (with that task) or by long-pressing Kairo; with no task it asks what to focus on.
- When a round ends the user can rest or complete the task.

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
9. Run `dart run build_runner build`

---

## Testing Strategy

### Unit Tests
- Domain: Test entities, use cases (pure logic)
- Data: Test repository implementations with mocked data sources
- BLoC: Test event → state transitions with `bloc_test`

### Widget Tests
- Test individual widgets with mocked BLoC
- Verify rendering, interactions, accessibility

### Golden Tests
- `test/goldens/` holds a golden per component and per screen in light, dark and 200% text (`goldenTest` in `test/helpers/golden.dart`, which loads the real Manrope font)
- Update with `flutter test --update-goldens test/goldens` and review the PNGs
- Widgets with Kairo render with `disableAnimations: true` so they settle

### Integration Tests
- None yet. Backend rules (RLS, triggers) are checked by hand against the Supabase project.

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
