# Changelog

All notable changes to KairoTasks will be documented in this file.

Format: **V xx.yy.zz**
- `xx` = Major version (breaking changes, full redesigns)
- `yy` = New important feature/implementation
- `zz` = Minor change (individual fix, tweak, or small addition)

---

## V 01.00.01 - Initial Project Setup (2026-08-25)

### Added
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

### Technical
- Flutter 3.47.1 (stable)
- Dart 3.13.1
- very_good_analysis linting
- Zero analyzer warnings
