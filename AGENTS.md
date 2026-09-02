# Kairo - Project Guidelines

> Collaborative productivity app built with Flutter + Supabase. "Kairo" comes from the Greek concept of the opportune moment.

---

## Project Overview

Kairo is a mobile-first collaborative task management app with:
- Real-time task synchronization between users
- Calendar and priority views
- Social features (friends, shared calendars, shared tasks)
- Accessibility-first design (ADHD/Autism friendly)
- Open source, completely free tech stack

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Flutter | 3.47+ |
| Backend | Supabase (Free Tier) | - |
| Auth | Supabase Auth (Email + Google + Apple) | - |
| State Management | flutter_bloc (BLoC/Cubit) | 8.x |
| DI | get_it + injectable | 7.x / 2.x |
| Navigation | go_router | 14.x |
| Realtime | Supabase Realtime (Postgres Changes) | - |
| Push Notifications | Firebase Cloud Messaging | - |
| Calendar | table_calendar | 3.x |

## Architecture

This project follows **Clean Architecture** with a **feature-first** folder structure. See [docs/architecture.md](docs/architecture.md) for full details.

### Key Rules:
1. **Domain layer** is pure Dart. No Flutter imports, no external packages except `equatable` and `dartz`.
2. **Dependencies point inward**: Presentation → Domain ← Data.
3. **Each feature is self-contained**: its own data/, domain/, presentation/ layers.
4. **BLoC pattern**: Events in → States out. Never call BLoC methods directly from widgets.
5. **Repository pattern**: Always code against the abstract interface (in domain/), never the implementation.

## Design System

See [docs/design.md](docs/design.md) for the complete design system including tokens, colors, typography, and component guidelines.

### Quick Reference:
- Style: **Zen/Calm Editorial**
- Fonts: DM Serif Display (headings) + DM Sans (body)
- Primary accent: Sage green (#4A6741)
- Min touch target: 44x44px
- Line height: 1.6x for body text
- Animations: 200-300ms, ease-in-out
- Reuse the shared `KairoHeader` widget for app branding on new screens

## Code Conventions

### File Naming
- All files use `snake_case`
- BLoC files: `feature_bloc.dart`, `feature_event.dart`, `feature_state.dart` (or combined)
- Pages: `feature_page.dart`
- Widgets: `descriptive_name_widget.dart` or just `descriptive_name.dart`
- Entities: `entity_name.dart`
- Repositories: `feature_repository.dart`

### Import Order
1. Dart SDK imports
2. Flutter imports
3. Package imports (third-party)
4. Project imports (relative)

### BLoC Conventions
- Use `Cubit` for simple state (no complex event handling needed)
- Use `Bloc` when you need event-driven logic, transformations, or debouncing
- Always emit new state objects (immutable state)
- Name events as past tense actions: `TaskCreated`, `FilterChanged`
- Name states descriptively: `TasksLoading`, `TasksLoaded`, `TasksError`

### Widget Rules
- Prefer `const` constructors wherever possible
- Extract reusable widgets into separate files when used 2+ times
- Keep widget build methods lean (< 80 lines ideally)
- Use `context.read<Bloc>()` for events, `BlocBuilder` for state

### Error Handling
- Use `Either<Failure, T>` (from dartz) for repository return types
- Define specific `Failure` subclasses in `core/errors/failures.dart`
- Never catch generic `Exception` without reason
- Show user-friendly error messages, log technical details

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (after adding @injectable annotations)
dart run build_runner build --delete-conflicting-outputs

# Run analyzer
flutter analyze

# Run tests
flutter test

# Run on iOS simulator
flutter run -d iPhone

# Run on connected device
flutter run

# Build APK (for Android testing)
flutter build apk --split-per-abi

# Build iOS (requires Xcode)
flutter build ios
```

## Environment Setup

### Prerequisites
- macOS with Apple Silicon
- Xcode (from App Store) + Command Line Tools
- Flutter SDK (via Homebrew: `brew install --cask flutter`)
- CocoaPods (`brew install cocoapods`)
- Android SDK (command-line tools for APK generation)

### Environment Variables

Copy `.env.example` to `.env` and fill in the real values:

```bash
cp .env.example .env
```

Runtime variables used by the Flutter app:

| Variable | Source | Purpose |
|----------|--------|---------|
| `SUPABASE_URL` | Supabase project settings | Supabase API URL |
| `SUPABASE_ANON_KEY` | Supabase project settings | Supabase public anon key |
| `LOGS_API_KEY` | Any strong random UUID | Shared secret for the logs Edge Function |
| `GOOGLE_WEB_CLIENT_ID` | Google Cloud Console | Web OAuth client ID |
| `GOOGLE_IOS_CLIENT_ID` | Google Cloud Console | iOS OAuth client ID |

iOS also needs `ios/Flutter/Env.xcconfig` with the reversed Google client ID:

```
REVERSED_GOOGLE_CLIENT_ID=com.googleusercontent.apps.<YOUR_IOS_CLIENT_ID>
```

### iOS Testing (Free Provisioning)
1. Connect iPhone via USB
2. Enable Developer Mode on iPhone (Settings → Privacy & Security → Developer Mode)
3. In Xcode: Sign with Personal Team (free Apple ID)
4. Trust the developer on iPhone (Settings → General → VPN & Device Management)
5. Certificate expires every 7 days - re-sign when needed

### Android APK
```bash
flutter build apk --split-per-abi
# Output (per ABI): build/app/outputs/flutter-apk/Kairo-<version>+<code>-<abi>-release.apk

# Single universal APK (larger, works on all ABIs)
flutter build apk
# Output: build/app/outputs/flutter-apk/Kairo-<version>+<code>-release.apk
```

## CI/CD (GitHub Actions)

Two workflows are provided in `.github/workflows/`:

- `release.yml` — builds a signed Android APK and attaches it to a GitHub Release.
- `release_ios.yml` — builds a signed iOS IPA and attaches it to a GitHub Release.

Both trigger automatically when you push a git tag matching `v*` (for example `git tag v1.17.8+94 && git push origin v1.17.8+94`).

### Required repository secrets

| Secret | Workflow | Description |
|--------|----------|-------------|
| `ENV_FILE_BASE64` | Both | Base64-encoded contents of `.env` (or skip if not required). |
| `GOOGLE_SERVICES_JSON_BASE64` | Android | Base64-encoded `android/app/google-services.json`. |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | iOS | Base64-encoded `ios/Runner/GoogleService-Info.plist`. |
| `KEYSTORE_BASE64` | Android | Base64-encoded `upload-keystore.jks` (optional, debug signing used if missing). |
| `KEYSTORE_PASSWORD` | Android | Keystore password. |
| `KEY_ALIAS` | Android | Keystore alias. |
| `KEY_PASSWORD` | Android | Alias key password. |
| `IOS_P12_CERTIFICATE` | iOS | Base64-encoded `.p12` distribution/development certificate. |
| `IOS_P12_PASSWORD` | iOS | Password for the `.p12` file. |
| `IOS_PROVISIONING_PROFILE_BASE64` | iOS | Base64-encoded `.mobileprovision` profile. |
| `IOS_TEAM_ID` | iOS | Apple Team ID (example: `V9G9CUPUMF`). |
| `IOS_PROVISIONING_NAME` | iOS | Exact name of the provisioning profile. |

### iOS distribution note

GitHub Releases is convenient for Android APKs. iOS `.ipa` files attached to a release can only be installed on devices registered in the provisioning profile (ad-hoc) or through an Enterprise/Mobile Device Management flow. For public iOS distribution, use TestFlight or the App Store.

## Notifications Strategy

| Type | Channel | When |
|------|---------|------|
| Task shared with you | Push (FCM) | Always |
| Friend request | Push (FCM) | Always |
| Task due soon | Push (FCM) | Based on user preference |
| Shared task completed | Push (FCM) | Only if shared task |
| Shared task edited | In-app banner | While user is active |
| Sync complete | In-app banner | While user is active |

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history. Format: `V xx.yy.zz`
- xx = major version (breaking changes)
- yy = new important feature
- zz = minor change (every individual change)

### Version Source of Truth

The latest `CHANGELOG.md` entry is the single source of truth for the current app version. After every meaningful change:

1. Add or update a `V xx.yy.zz` entry at the top of `CHANGELOG.md`.
2. Use the latest changelog version when naming APKs, referencing releases, or communicating the current version.
3. Keep `CHANGELOG.md` in sync with shipped features, fixes, and migrations.

## Git

- Commits must be made in the user's name only.
- Commit messages must contain only the description of the changes.
- Do not include signatures, footers, `Co-Authored-By`, `Generated with`, or any bot attribution.

## Contributing

See [README.md](README.md) for contribution guidelines.
