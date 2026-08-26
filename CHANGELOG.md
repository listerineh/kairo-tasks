# Changelog

All notable changes to KairoTasks will be documented in this file.

Format: **V xx.yy.zz**

- `xx` = Major version (breaking changes, full redesigns)
- `yy` = New important feature/implementation
- `zz` = Minor change (individual fix, tweak, or small addition)

---

## V 01.05.03 - Logo on Dashboard and Social (2026-08-25)

### Added in V 01.05.03

- App logo SVG in the `DashboardPage` header next to the app name
- App logo SVG in the `SocialPage` `AppBar` title next to the screen title

---

## V 01.05.02 - Dashboard metrics trimmed (2026-08-25)

### Changed in V 01.05.02

- Removed urgent/high and completion rate metric chips from dashboard
- Kept total, completed, pending and overdue quick numbers

---

## V 01.05.01 - Dashboard visual cleanup (2026-08-25)

### Fixed in V 01.05.01

- Removed heavy `Card` containers from the dashboard
- Metric cards replaced by a lightweight wrap of value + label pairs
- Charts sit directly under section titles with no card backgrounds
- More editorial, breathable layout

---

## V 01.05.00 - Dashboard homepage with charts (2026-08-25)

### Added in V 01.05.00

- New `DashboardPage` as the home screen (first tab)
- Metric cards: total, completed, pending, overdue, urgent/high, completion rate
- `fl_chart` powered charts:
  - Donut chart for completion status
  - Bar chart for tasks by priority
  - Bar chart for tasks due in the next 7 days
- "View all tasks" button to go to the Tasks list
- Bottom navigation now has 5 tabs: Dashboard, Tasks, Calendar, Social, Profile
- New i18n keys for dashboard labels

### Changed in V 01.05.00

- `TasksPage` is now its own tab; the dashboard is the new homepage
- App `initialLocation` and login redirect point to `/dashboard`

---

## V 01.04.00 - Internationalization (2026-08-25)

### Added in V 01.04.00

- Full English/Spanish internationalization using ARB files and `flutter_localizations`
- Default locale is Spanish
- Supported locales: `es` and `en`
- App follows the device preferred language and falls back to Spanish
- New `lib/l10n/app_es.arb` and `lib/l10n/app_en.arb`
- New `context.l10n` extension for easy access to translated strings

---

## V 01.03.33 - Priority dot padding in calendar (2026-08-25)

### Fixed in V 01.03.33

- Increased left padding in Day and Week task blocks so the priority dot is not so close to the title text

---

## V 01.03.32 - Shared task avatars in calendar (2026-08-25)

### Added in V 01.03.32

- New `SharedTaskAvatars` widget for calendar task blocks
- Day and Week views now show the avatars of the people a task is shared with
- Falls back to the contact's initial when no avatar is set

---

## V 01.03.31 - Enable Supabase realtime for own color changes (2026-08-25)

### Fixed in V 01.03.31

- Added `supabase_realtime` publication for `profiles` and `friendships`
- Own color changes now propagate to the calendar in real time

---

## V 01.03.30 - Calendar colors realtime and priority dot position (2026-08-25)

### Fixed in V 01.03.30

- Fixed `_coloredTasks` so own/friend colors are actually applied to all tasks
- `CalendarPage` now subscribes to realtime changes on `profiles` and `friendships`
  - Color changes update the calendar immediately without leaving the tab
- Day and Week calendar blocks now use `profile.color` for background/border
- Priority dot is now a small circle in the top-left corner of the task block

---

## V 01.03.29 - Calendar colors and private friend "Busy" mode (2026-08-25)

### Fixed in V 01.03.29

- Calendar colors now update before friend tasks load (no longer blocked by `get_public_friend_tasks`)
- `CalendarPage` deduplicates shared and friend tasks
- New migration makes `get_public_friend_tasks` a `SECURITY DEFINER` function returning all accepted friend tasks
- Calendar now masks private friend tasks as "Busy" while keeping their time block
- Public friend tasks show full title and description
- `tasks` RLS restricted back to own + shared tasks

---

## V 01.03.28 - Calendar color auto-refresh (2026-08-25)

### Fixed in V 01.03.28

- `CalendarPage` now re-fetches `profiles.color` and `friendships.*_color` when the tab becomes visible
- Prevents stale own/friend colors from persisting across tab switches
- 2-second debounce to avoid extra DB calls

---

## V 01.03.27 - My task color moved to Profile section (2026-08-25)

### Fixed in V 01.03.27

- Removed color picker from Edit Profile sheet
- Added "My task color" option in Profile page with a color preview dot
- New `ProfileColorSheet` bottom sheet to choose and save the profile task color
- Color is still saved in `profiles.color` and reflected in the calendar

---

## V 01.03.26 - Calendar owner color and priority dots (2026-08-25)

### Fixed in V 01.03.26

- Default own calendar color (`#4A6741`) is applied while the profile loads
- Friend tasks fallback to `#6B8FA3` when a friend color is not loaded yet
- Calendar day/week/month views now show the owner/friend chosen color as fill
- Added a priority dot (urgent/high/medium/low) inside each calendar task

---

## V 01.03.25 - Friend detail sheet with color and actions (2026-08-25)

### Fixed in V 01.03.25

- Friend rows are now tappable and open a full bottom sheet
- Detail sheet shows friend avatar, name, username
- Color picker moved to the detail sheet
- "Create task together" and "Remove friend" moved to the detail sheet
- Removed crowded action buttons from friend list rows

---

## V 01.03.24 - Muted color palette for friends and profile (2026-08-25)

### Fixed in V 01.03.24

- Replaced bright iOS-style color palette with muted, desaturated tones
- Default friend color changed from yellow to muted slate `#6B8FA3`
- Better readability for text over calendar task backgrounds
- Updated SQL defaults and docs

---

## V 01.03.23 - Default profile color matches app green (2026-08-25)

### Fixed in V 01.03.23

- Default `profiles.color` changed from blue to the app's green (`#4A6741`)
- App fallback for own task color also uses `#4A6741`

---

## V 01.03.22 - Friend public calendar, task colors and friend colors (2026-08-25)

### Added in V 01.03.22

- New `profiles.color` and `friendships.requester_color` / `addressee_color` columns
- New `get_public_friend_tasks` RPC to load public friend tasks for the calendar
- `CalendarPage` now loads accepted friends, their side color, and their public tasks
- Calendar day/week/month views use the owner color for each task (own `profiles.color` or friendship color)
- `SocialPage` shows a color circle for each friend and allows removing a friendship
- Friend color can be changed from a color picker in Social
- `EditProfileSheet` lets you set your own task color and calendar visibility
- RLS for `tasks` updated to allow reading public friend tasks; `friendships` update allows both sides

---

## V 01.03.21 - Edit shared friends in EditTaskSheet (2026-08-25)

### Added in V 01.03.21

- `TaskEditRequested` now accepts `sharedWith` list
- `TasksBloc` inserts/deletes `shared_tasks` rows when editing to add or remove friends
- `EditTaskSheet` loads accepted friends and shows `FilterChip`s
- Owner can select/deselect multiple friends to share/unshare
- Shared friends list is pre-selected from the existing `shared_tasks`
- Non-owners do not see the sharing section

---

## V 01.03.20 - Hide add friend button for pending requests (2026-08-25)

### Fixed in V 01.03.20

- Social search now loads sent pending friend requests
- Pending sent users appear with a "Pending" status chip (hourglass icon)
- The `person_add` button is hidden for friends and pending requests
- After sending a request, the result updates to "Pending" immediately

---

## V 01.03.19 - Share tasks with multiple friends (2026-08-25)

### Added in V 01.03.19

- `TaskEntity.sharedWith` is now a `List<Map<String, dynamic>>` to support n friends
- `TasksBloc` inserts `shared_tasks` for every selected friend
- `CreateTaskSheet` replaced the friend `DropdownButton` with multi-select `FilterChip`s
- `TaskCard` now shows the first friend plus a `+n` count when shared with multiple
- `TaskDetailSheet` lists every shared friend with avatar, display name and username

---

## V 01.03.18 - Task detail sheet with edit button (2026-08-25)

### Added in V 01.03.18

- New `TaskDetailSheet` widget
- Tapping a task opens a bottom sheet with:
  - Title and description
  - Status and priority chips
  - Start and due dates
  - Shared-with profile and avatar
  - "Edit Task" button
- The "Edit Task" button closes the detail sheet and opens `EditTaskSheet`
- `TaskCard` now triggers the detail sheet instead of jumping straight to edit

---

## V 01.03.17 - Give the friend action button a purpose (2026-08-25)

### Added in V 01.03.17

- `CreateTaskSheet` now accepts an `initialSharedWith` friend id
- `SocialPage` Friends tab icon changed from calendar to `add_task`
- Tapping a friend now opens `CreateTaskSheet` with that friend pre-selected
- Added tooltips to `_IconActionButton` for better affordance
- Friend search `person_add` shows "Send friend request" tooltip
- Friend row `add_task` shows "Create task with [name]" tooltip
- `SocialPage` SnackBars now use `SnackBarBehavior.floating` to appear above the keyboard

---

## V 01.03.16 - Show who a shared task is with (2026-08-25)

### Added in V 01.03.16

- `TaskEntity` now carries a `sharedWith` profile map
- `TasksBloc` fetches `shared_tasks` joined with the friend `profiles`
- The task owner sees `Shared with [friend name]`
- The recipient sees `Shared by [friend name]`
- Added small avatar circle next to the shared label in `TaskCard`
- Preserves shared profile info across `tasks` realtime updates
- New `_TasksReloadFromStream` event for silent reload on `shared_tasks` changes

---

## V 01.03.15 - Shared tasks in Tasks list (2026-08-25)

### Fixed in V 01.03.15

- `TasksBloc` now loads all `tasks` rows the user can see via RLS, not only `owner_id = auth.uid()`
- Removed the `owner_id` filter from the initial task query and the `tasks` realtime stream
- Added a `shared_tasks` realtime stream filtered by `shared_with_id = auth.uid()`
- When someone shares a task with the user, the `shared_tasks` stream triggers a task reload
- Shared tasks now appear in Tasks and Calendar tabs for the recipient

---

## V 01.03.14 - Social friends loading fix (2026-08-25)

### Fixed in V 01.03.14

- Refactored `SocialPage` friends/pending queries to load `friendships` and `profiles` separately
- Profiles are now fetched with `.filter('id', 'in', [...])` using the collected `requester_id`/`addressee_id` values
- Friends and requesters are stored as `profile`/`requester_profile` maps in the lists
- `_FriendsTab` and `_RequestsTab` use the mapped profile, avoiding embedded query ambiguity
- `_loadSocialData` now shows a `SnackBar` when loading fails

---

## V 01.03.13 - Social tab overflow fix (2026-08-25)

### Fixed in V 01.03.13

- Fixed `RenderFlex` overflow in `SocialPage` `_Tab`
- Tab labels now use `Flexible` + `TextOverflow.ellipsis`
- Reduced spacing between tab icon, label, and count badge

---

## V 01.03.12 - Fix user profile creation and task FK (2026-08-25)

### Fixed in V 01.03.12

- `handle_new_user` now always produces a non-null `username` and `display_name`
- Handles Google sign-ins where `email` or `raw_user_meta_data` is missing/empty
- Backfilled missing `profiles` rows for all existing `auth.users`
- `tasks.owner_id` FK no longer fails after a successful Google sign-in
- `AuthBloc` rejects Google sign-in if `user` or `session` is null
- `TasksPage` now shows a `SnackBar` when `TasksBloc` emits an `errorMessage`

---

## V 01.03.11 - Avatar upload RLS path fix (2026-08-25)

### Fixed in V 01.03.11

- Removed redundant `avatars/` prefix from `EditProfileSheet` upload path
- Upload path is now `$userId/avatar_<timestamp>.<ext>` relative to the `avatars` bucket
- This satisfies the RLS `storage.foldername(name)[1] = auth.uid()` policy
- Avatar upload no longer raises 403 `Unauthorized` on save

---

## V 01.03.10 - iOS CocoaPods configuration (2026-08-25)

### Changed in V 01.03.10

- Disabled Swift Package Manager for iOS to ensure `image_picker_ios` is installed by CocoaPods
- Regenerated `ios/Podfile.lock` and `ios/Runner.xcodeproj/project.pbxproj`
- Removed `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `pod install` now installs all 11 iOS dependencies including `image_picker_ios`

---

## V 01.03.09 - Developer credit in Profile (2026-08-25)

### Added in V 01.03.09

- New `Developed by Listerineh` tile in `ProfilePage` under About
- Tapping the tile opens `https://listerineh.dev` in the browser
- Version number is displayed on the existing `Version` tile

---

## V 01.03.08 - iOS build fix for avatar upload (2026-08-25)

### Fixed in V 01.03.08

- Fixed non-final field promotion issue in `edit_profile_sheet.dart`
- `File? _selectedImage` is now assigned to a local variable before use
- `flutter analyze` passes and iOS build succeeds

---

## V 01.03.07 - Profile avatar upload (2026-08-25)

### Added in V 01.03.07

- `image_picker` dependency for gallery and camera access
- iOS `Info.plist` permissions for photo library and camera
- Supabase Storage `avatars` bucket with RLS for user-scoped uploads
- `EditProfileSheet` now shows avatar picker instead of URL field
- Users can pick from gallery or take a photo; image uploads to Supabase Storage
- Uploaded avatar public URL is saved to `profiles.avatar_url` and user metadata
- `SocialPage` friend cards and `ProfilePage` display the new avatars automatically

---

## V 01.03.06 - Email in profiles (2026-08-25)

### Added in V 01.03.06

- `email` column added to `public.profiles`
- Backfilled `email` for existing profiles from `auth.users`
- Updated `handle_new_user` trigger to save `NEW.email` on signup
- Foundation for email-based search or display in future features

---

## V 01.03.05 - Google sign-in Android fixes (2026-08-25)

### Fixed in V 01.03.05

- `AuthBloc` now passes `clientId` only on iOS and `serverClientId` on both platforms
- Added `Google Web Client ID` missing check and better error messages
- `LoginPage` shows `SnackBar` on `AuthStatus.error`
- Added `com.google.android.gms` to `AndroidManifest.xml` `<queries>` for package visibility
- New debug APK built with the latest Google sign-in fixes

---

## V 01.03.04 - Share tasks with friends (2026-08-25)

### Added in V 01.03.04

- `TaskCreateRequested` accepts `sharedWith` friend user ID
- `TasksBloc` creates the task, fetches its ID, and inserts a `shared_tasks` row
- `CreateTaskSheet` loads accepted friends and shows a "Share with" dropdown
- Shared tasks appear in the friend's task list through existing `tasks` RLS policy

---

## V 01.03.03 - Fluid tab navigation (2026-08-25)

### Changed in V 01.03.03

- Migrated from `ShellRoute` to `StatefulShellRoute.indexedStack`
- Tabs are now kept alive, eliminating rebuilds and data reloads
- Switching between Tasks, Calendar, Social, and Profile is instant
- Tab state and scroll positions are preserved

---

## V 01.03.02 - Social keyboard scroll fix (2026-08-25)

### Fixed in V 01.03.02

- Replaced `NestedScrollView` / `SliverAppBar` with standard `AppBar` + `TabBarView`
- Added `resizeToAvoidBottomInset: true` to the `SocialPage` `Scaffold`
- Scrolling now works correctly when the search keyboard is open

---

## V 01.03.01 - Social redesign (2026-08-25)

### Changed in V 01.03.01

- Redesigned `SocialPage` with modern look
- Added `NestedScrollView` with `SliverAppBar` and `TabBar`
- Three tabs: Search, Friends, Requests
- Improved user cards with large avatars, shadows, and rounded corners
- Search bar with modern rounded container and shadow
- Empty states with icons and copy
- Status chips and icon action buttons

---

## V 01.03.00 - Social v1 (2026-08-25)

### Added in V 01.03.00

- New `SocialPage` with user search by username
- Send friend requests from search results
- View and accept/decline pending friend requests
- View accepted friends list
- Wired `/social` route into bottom navigation
- Reused existing `friendships` schema with symmetric relationship rows

---

## V 01.02.12 - Modern login and sign-up (2026-08-25)

### Added in V 01.02.12

- Modern, centered login/sign-up redesign with gradient background
- Animated title and form transitions between sign in and sign up
- Circular elevated logo container with soft shadow
- Modern text fields with rounded cards, floating labels, and password visibility toggle
- Primary action button with shadow and loading state
- Styled Google sign-in button
- Inline "Forgot password?" placeholder
- Better copy and visual hierarchy

---

## V 01.02.11 - Tab transitions (2026-08-25)

### Added in V 01.02.11

- Smooth fade transition when switching between bottom tabs
- `CustomTransitionPage` with `Curves.easeInOut` for Tasks, Calendar, Social, and Profile routes
- Replaced `NoTransitionPage` with animated page transitions

---

## V 01.02.10 - Unique usernames (2026-08-25)

### Added in V 01.02.10

- Unique `username` enforced in `profiles` table with unique index
- `handle_new_user` trigger now appends a numeric suffix if the desired username is already taken (e.g. `usertest1`)
- `EditProfileSheet` checks username availability before saving and shows an alert if it is already occupied
- Foundation for friend search by username

---

## V 01.02.09 - App logo B (2026-08-25)

### Added in V 01.02.09

- Selected `logo_b_kairos_hourglass.svg` as the official app icon
- Added `assets/icons/app_icon.svg` and `assets/icons/app_icon_1024.png`
- Displayed the logo on the login page
- Generated iOS and Android launcher icons with `flutter_launcher_icons`
- Added `flutter_launcher_icons.yaml` config

---

## V 01.02.08 - Open GitHub from profile (2026-08-25)

### Added in V 01.02.08

- `url_launcher` dependency
- Profile "Open Source" tile now opens the GitHub repository in the browser

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
