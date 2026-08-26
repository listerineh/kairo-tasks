# Changelog

All notable changes to KairoTasks will be documented in this file.

Format: **V xx.yy.zz**

- `xx` = Major version (breaking changes, full redesigns)
- `yy` = New important feature/implementation
- `zz` = Minor change (individual fix, tweak, or small addition)

---

## V 01.02.07 - Theme persistence (2026-08-25)

### Added in V 01.02.07

- `ThemeService` singleton using `ValueNotifier` and `SharedPreferences`
- `KairoTasksApp` reacts to theme changes in real-time
- Appearance settings sheet now lets the user pick light/dark/system
- Theme selection is persisted across app restarts

---

## V 01.02.06 - Instant profile refresh (2026-08-25)

### Fixed in V 01.02.06

- Profile page now refreshes instantly when editing profile (returns updated data from EditProfileSheet and updates local state)
- EditProfileSheet returns the new profile map on save instead of `true`
- No need to switch tabs to see profile changes

---

## V 01.02.05 - Profile source of truth (2026-08-25)

### Changed in V 01.02.05

- `ProfilePage` now reads `display_name`, `username` and `avatar_url` from the `profiles` table (single source of truth)
- `EditProfileSheet` loads from `profiles` and falls back to auth metadata only as a suggestion
- Email sign-up now asks for both display name and username
- `AuthSignUpRequested` passes `username` to Supabase user metadata

---

## V 01.02.04 - Profile settings (2026-08-25)

### Added in V 01.02.04

- Edit Profile bottom sheet (display name, username, avatar URL, calendar visibility)
- Profile updates persist to Supabase `profiles` table and auth user metadata
- Appearance settings sheet with light/dark/system toggle
- Notifications settings sheet with preference toggles (placeholder / future)
- Profile page tiles are now interactive

---

## V 01.02.03 - Version sync (2026-08-25)

### Changed in V 01.02.03

- `pubspec.yaml` version bumped to `1.2.2+22` to match changelog V 01.02.02
- Profile page now reads version dynamically from `package_info_plus`
- Added `package_info_plus` dependency for runtime version display

---

## V 01.02.02 - Calendar UI refresh (2026-08-25)

### Changed in V 01.02.02

- Calendar UI completely refreshed to match Google Calendar more closely
- Day view: 24h timeline, tasks positioned at startDate, height reflects duration, current time red line, all-day chip top row
- Week view: now shows 2 days side-by-side (selected + next day) with hour grid
- Month view: task title previews visible inside day cells, max 3 with +N overflow
- Calendar header: month name + chevrons + circular D/W/M view toggle chips
- Week strip header with selected day highlighted and today accent color
- "Today" quick-jump button in bottom bar

---

## V 01.02.01 - Task start date & duration (2026-08-25)

### Added in V 01.02.01

- `start_date` field on tasks (new DB column via migration)
- Start date/time picker in create and edit sheets ("Start" + "End" fields)
- Tasks now have explicit duration (start → end)
- Calendar blocks sized proportionally to task duration
- `duration` getter on TaskEntity

### Changed in V 01.02.01

- Progress bar uses startDate (falls back to createdAt if not set)
- Calendar day/week views position blocks at startDate with correct height
- Calendar _tasksForDate checks range overlap for multi-hour/day tasks

---

## V 01.02.00 - Calendar views (2026-08-25)

### Added in V 01.02.00

- Calendar page with 3 views: Day, Week, Month (Google Calendar style)
- Day view: vertical timeline (24h), tasks positioned by due time, current time red indicator
- Week view: 7-column grid with hour rows, day headers with today highlight, task blocks by time
- Month view: grid with task dots, tap day to drill into day view
- View selector (Day/Week/Month) with animated toggle
- Navigation arrows + "Today" quick jump
- Tasks displayed from BLoC state with priority-based colors
- Tapping a task in calendar toggles its completion status

---

## V 01.01.11 - Timezone fix (2026-08-25)

### Fixed in V 01.01.11

- Due dates now correctly stored as UTC (`.toUtc().toIso8601String()`)
- Dates read from Supabase converted to local time (`.toLocal()`)
- Fixes issue where times appeared offset by the user timezone (e.g. ECT/UTC-5)

---

## V 01.01.10 - Time progress bar & date+time picker (2026-08-25)

### Added in V 01.01.10

- Visual time progress bar at the bottom of each task card (shows elapsed time from creation to due date)
- Bar turns red when less than 10% time remains or task is overdue
- Date+time picker: selecting a due date now also prompts for time
- Due date chip shows hours/minutes remaining when due within 24h
- Overdue display shows hours/minutes granularity

### Changed in V 01.01.10

- Due date stored with time component (not just date)
- DueDateChip shows "3h left", "45m left" for near-term tasks

---

## V 01.01.09 - Task interactions & animations (2026-08-25)

### Changed in V 01.01.09

- Swipe right to complete/uncomplete a task (replaces tap on circle)
- Swipe left to delete a task
- Status circle moved to right side of card (visual only, non-interactive)
- Dismissible uses confirmDismiss pattern to avoid tree conflicts with realtime stream

### Added in V 01.01.09

- Tap on a task opens edit sheet (title, description, priority, due date)
- Edit task persists changes to Supabase
- TaskEditRequested event in TasksBloc
- Animated task cards: fade + scale entrance animation
- Completed tasks section below active tasks, ordered by most recently completed first

---

## V 01.01.08 - Profile page (2026-08-25)

### Added in V 01.01.08

- Profile page with user info (avatar, name, email, member since)
- Google avatar displayed when signed in with Google
- Settings tiles (Edit Profile, Appearance, Notifications placeholders)
- About section with version and open source link
- Sign out button with route guard back to login

---

## V 01.01.07 - iOS Google Sign-In config (2026-08-25)

### Added in V 01.01.07

- Reversed Google Client ID in Info.plist via xcconfig variable
- Env.xcconfig for iOS-specific environment values (gitignored)
- Nonce generation for Google Sign-In token verification

### Changed in V 01.01.07

- Login page shows only Google button (Apple deferred until paid developer account)

---

## V 01.01.06 - Google & Apple OAuth (2026-08-25)

### Added in V 01.01.06

- Google Sign-In via native flow (google_sign_in 7.x) + Supabase ID token exchange
- Apple Sign-In via native flow (sign_in_with_apple) + nonce verification
- OAuth client IDs injected via environment variables (GOOGLE_WEB_CLIENT_ID, GOOGLE_IOS_CLIENT_ID)

---

## V 01.01.05 - Auth BLoC + Login flow (2026-08-25)

### Added in V 01.01.05

- AuthBloc with full state management (unknown, loading, authenticated, unauthenticated, error)
- Email sign-in and sign-up with Supabase Auth
- Login page with toggle between sign-in and sign-up modes
- Display name field during registration
- Router redirect guard: unauthenticated → /login, authenticated → /tasks

---

## V 01.01.04 - Tasks persistence with Supabase (2026-08-25)

### Changed in V 01.01.04

- TasksBloc now reads/writes directly to Supabase (removed all demo data)
- Create task inserts into Supabase `tasks` table
- Toggle status updates task in DB
- Delete task removes from DB
- Realtime stream subscription: changes from other devices sync instantly

---

## V 01.01.03 - Sort tasks by priority (2026-08-25)

### Changed in V 01.01.03

- All task views now sort by priority order: urgent → high → medium → low
- Priority sorting applies to every filter tab including "All"

---

## V 01.01.02 - Remove flutter_local_notifications (2026-08-25)

### Removed in V 01.01.02

- Removed flutter_local_notifications (incompatible with Swift Package Manager)
- Will re-add when implementing scheduled reminders with a SPM-compatible version

---

## V 01.01.01 - Supabase backend integration (2026-08-25)

### Added in V 01.01.01

- Created Supabase project (gatdyxuqmdbllbmzejwh, US East)
- Database migration: profiles, tasks, shared_tasks, friendships tables
- Row Level Security policies on all tables
- Realtime enabled on tasks, shared_tasks, friendships
- Auto-create profile trigger on user signup
- Updated_at trigger for automatic timestamps
- Auth remote datasource (email, Google, Apple OAuth)
- Task remote datasource (CRUD + realtime stream)
- Task model (JSON ↔ Entity mapping)
- Task repository implementation with Either<Failure, T>
- iOS build verified (Xcode 26.6 + iOS 26.5 SDK)
- CocoaPods integration for iOS plugins

---

## V 01.00.02 - Environment variables for secrets (2026-08-25)

### Changed in V 01.00.02

- Supabase credentials moved from hardcoded constants to environment variables
- Credentials injected at build time via `--dart-define-from-file=.env`
- Added .env.example as reference for contributors

### Security in V 01.00.02

- .env file gitignored (never committed to repository)

---

## V 01.00.01 - Initial Project Setup (2026-08-25)

### Added in V 01.00.01

- Flutter project scaffold with Clean Architecture (feature-first)
- Design system implementation: Zen/Calm Editorial theme with light/dark mode
- Color tokens (sage green accent, warm cream surfaces, priority colors)
- Typography system (DM Serif Display + DM Sans)
- Spacing system (4px grid base)
- App navigation with go_router (4-tab bottom nav: Tasks, Calendar, Social, Profile)
- Dependency injection setup (get_it + injectable)
- Tasks feature: BLoC with demo data, task cards, filter chips, create task sheet
- Auth feature scaffold: Login page with Email/Google/Apple options
- Domain entities: TaskEntity, UserEntity
- Repository contracts: TaskRepository, AuthRepository
- Core utilities: Failure classes, context extensions, app constants
- Project documentation: AGENTS.md, docs/design.md, docs/architecture.md, README.md
- Android SDK configuration for APK generation

### Technical in V 01.00.01

- Flutter 3.47.1 (stable)
- Dart 3.13.1
- very_good_analysis linting
- Zero analyzer warnings
