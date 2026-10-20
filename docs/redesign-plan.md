# Kairo 2.0 - Redesign & Hardening Plan

> Working brief for the V 02.00.00 redesign. Written after an audit of the codebase against `AGENTS.md`, `docs/architecture.md` and `docs/design.md` (2026-10-20).
> When a phase ships, update `docs/design.md` / `docs/architecture.md` so they describe the code as it is, and log it in `CHANGELOG.md`.

Per the changelog convention a full redesign is a **major** bump: `V 02.00.00` (pubspec `2.0.0+<next build>`). Ship intermediate phases as `V 01.18.x` if preferred, and cut `2.0.0` when the visual redesign is complete.

---

## 1. Audit findings (current state)

### 1.1 Docs vs. reality

| Documented rule | Reality |
| --- | --- |
| Every feature has `data/`, `domain/`, `presentation/` | Only `auth` and `tasks` have files in `data/` + `domain/`. The other six features have empty folders. |
| Use cases in `domain/usecases/` | None exist. |
| DI with get_it + injectable | `injection.config.dart` registers nothing; `getIt` is never used. BLoCs are built with `AuthBloc()` / `TasksBloc()`. |
| Presentation never touches data | 61 `Supabase.instance` calls in presentation/app. Worst: `social_page.dart` (13, 1238 lines), `calendar_page.dart` (10), `edit_profile_sheet.dart` (8), `profile_page.dart` (5), `create/edit_task_sheet.dart` (4 each). |
| BLoC per feature | Only `TasksBloc` and `AuthBloc`. Social, profile, calendar, notifications hold state in widgets. |
| Tests with bloc_test + mocktail | `test/` is empty. |
| `core/widgets`, `core/utils` | Empty. No shared components. |

### 1.2 Bugs found by reading

1. `app.dart`: `AppRouter.create(widget.initialLocation)` is called inside the `ValueListenableBuilder` builder, so a **new GoRouter is created on every locale change** (navigation stack reset). Create it once in `initState`.
2. `app.dart`: `ThemeService.instance.themeMode.addListener(_onThemeChanged)` runs in `build()` → **listener accumulates on every rebuild**. Move to `initState` (or use a `ValueListenableBuilder`).
3. `ThemeService.init()` / `LocaleService.init()` run twice (`main` and `initState`).
4. `AppRouter.router` is a mutable static used by `NotificationService` and the streak listener; replace with the router owned by the app (or a `GlobalKey<NavigatorState>` registered in DI).
5. One hardcoded string: `notifications_sheet.dart:116` `'View notification history'`.

### 1.3 Accessibility violations (against our own design.md)

- `textMuted` contrast ~2.6:1 (light) and ~3.2:1 (dark). Fails AA for any text.
- Dark `accent` `#7CAD71` with white text ~2.6:1. Primary buttons fail AA in dark mode.
- `MediaQuery.disableAnimations` is never checked; the mascot animates constantly.
- Zero `Semantics` widgets; icon-only buttons lack labels.
- Hardcoded `fontSize` in calendar views, focus page, mascot; raw `EdgeInsets` numbers in ~20 files.

---

## 2. Design direction - "Apple-native calm"

Kairo keeps its purpose (calm, ADHD/Autism-friendly, collaborative) but moves from the Zen/Editorial look to a design that feels like a first-party iOS app: system typography, grouped surfaces, translucent bars, sheets with detents, and spring physics. The calm now comes from **restraint and predictability**, not from serif type and cream backgrounds.

**Spend the boldness in one place: the cat.** Everything else stays quiet, system-like and disciplined.

### 2.1 Color tokens

Neutral surfaces follow Apple's grouped palette; text and tint are tuned so every text pair passes **WCAG AA**. Contrast ratios were computed, not estimated.

| Token | Light | Dark | Notes |
| --- | --- | --- | --- |
| `background` | `#F2F2F7` | `#000000` | systemGroupedBackground |
| `surface` | `#FFFFFF` | `#1C1C1E` | cards, grouped rows |
| `surfaceRaised` | `#FFFFFF` | `#2C2C2E` | sheets, menus, focused rows |
| `fill` | `#787880` @ 12% | `#787880` @ 24% | inputs, segmented control track |
| `label` | `#000000` | `#FFFFFF` | primary text |
| `labelSecondary` | `#6C6C70` (5.2:1) | `#98989F` (5.9:1) | **not** Apple's 60% alpha gray, which is 3.4:1 on white |
| `labelTertiary` | `#3C3C43` @ 30% | `#EBEBF5` @ 30% | placeholders and decorative only; never informative text |
| `separator` | `#3C3C43` @ 29% | `#545458` @ 60% | hairlines (0.5 logical px) |
| `tint` | `#3A7449` (5.6:1 vs white text) | `#5FC27A` (9.5:1 vs **black** text) | Kairo green, kept as identity |
| `tintSoft` | tint @ 12% | tint @ 20% | selected rows, chips |
| `destructive` | `#D70015` | `#FF453A` | delete, errors |

Priority colors (Apple's accessible variants). Always paired with an icon or label, never color alone:

| Priority | Light | Dark | Symbol |
| --- | --- | --- | --- |
| urgent | `#D70015` | `#FF453A` | `exclamationmark.2` |
| high | `#C93400` | `#FF9F0A` | `exclamationmark` |
| medium | `#0062CC` | `#0A84FF` | `minus` |
| low | `#6C6C70` | `#98989D` | `arrow.down` |

Implementation: replace `AppColorScheme` with a `ThemeExtension<KairoColors>` (supports `lerp` for animated theme switches). `context.appColors` stays as the access point. On-tint text color is a token (`onTint`: white in light, black in dark).

### 2.2 Typography

- **iOS:** the system font (SF Pro Text / Display, picked automatically by optical size). Do not bundle SF Pro: its license only allows Apple platforms.
- **Android:** **Inter** via `google_fonts` (closest open metric match to SF), with `fontFeatures` `cv11` + `ss01` off and tabular figures for timers and counts.
- DM Serif Display and DM Sans are retired.
- The scale follows Apple's Dynamic Type "Large" defaults and **must scale with `MediaQuery.textScaler`** (test at 200%).

| Role | Size / line height | Weight | Usage |
| --- | --- | --- | --- |
| `largeTitle` | 34 / 41 | Bold | Tab root titles (collapsing) |
| `title1` | 28 / 34 | Bold | Sheet hero, focus timer label |
| `title2` | 22 / 28 | Bold | Section headers on dashboard |
| `title3` | 20 / 25 | Semibold | Card titles |
| `headline` | 17 / 22 | Semibold | Task titles, row titles |
| `body` | 17 / 22 (+ 1.35 for multi-line) | Regular | Descriptions |
| `callout` | 16 / 21 | Regular | Secondary rows |
| `subheadline` | 15 / 20 | Regular | Metadata |
| `footnote` | 13 / 18 | Regular | Section footers, hints |
| `caption1` | 12 / 16 | Regular | Calendar labels (minimum for text) |
| `timer` | 76 / 1.0, tabular | Light | Focus countdown only |

Accessibility note: multi-line body text keeps a line height of at least 1.35. The old 1.6 rule was for the editorial serif look and is too airy for SF and Inter. Letter spacing follows SF tracking tables (negative at large sizes); never manually space out labels.

### 2.3 Layout & structure

- Root tabs use a **large title that collapses** into an inline translucent nav bar on scroll (`CupertinoSliverNavigationBar`-style behavior, built as a custom `SliverPersistentHeader` so it works on Android too).
- Content lives in **inset grouped sections** (16 px side inset, 10 px radius, hairline separators inset to the text start). Not a card per item.
- **Tab bar:** translucent material (blur 20 + surface at 80%), hairline top separator, SF-style symbols, labels always visible.
- **Sheets:** system-style with detents (medium / large), grabber, background scales down slightly behind (iOS 13+ card presentation). Replaces the current custom bottom sheets.
- **Radius hierarchy** (not one radius everywhere): rows/groups 10, cards 16, sheets 12 top (system), buttons capsule, avatars circle.
- **Spacing:** keep the 4 px grid tokens; screen margin is 16 (Apple), not 24.
- **Left-aligned** everything except empty states and the focus timer.

```
┌──────────────────────────────┐
│ Tasks                    ＋  │  ← large title, collapses on scroll
│ ┌──────────────────────────┐ │
│ │ Today          3 of 5    │ │  ← inset grouped section header
│ ├──────────────────────────┤ │
│ │ ◯  Call the dentist   ‼  │ │  ← row: check circle, title, priority symbol
│ │    10:00 – 10:30 · Ana   │ │
│ ├──────────────────────────┤ │
│ │ ◯  Write report          │ │
│ └──────────────────────────┘ │
│ Completed  ⌄                 │  ← collapsible section
└──────────────────────────────┘
│ ▢ Today  ✓ Tasks  ▦ Cal  ☺ … │  ← translucent tab bar
```

### 2.4 Iconography

Use `CupertinoIcons` everywhere (SF Symbols-like, works on both platforms). Outline for unselected tab, fill for selected. Every icon-only control gets a `Semantics(label:)` / `tooltip`.

### 2.5 Motion - "smooth but logical"

Rules (replace the "Animations & Motion" section in `design.md`):

1. **Motion answers an action.** Something moves because the user did something, or because state changed (a shared task arrived). No ambient motion except the cat's breathing and blinking, which turn off under reduced motion.
2. **Springs, not curves.** All interactive motion uses `SpringDescription` presets in `app/theme/app_motion.dart`:
   - `smooth` - no bounce, ~0.35 s response: navigation, sheets, layout changes
   - `snappy` - small bounce (~0.15), ~0.3 s: toggles, check circle, chips, segmented control
   - `bouncy` - bounce ~0.3, ~0.45 s: celebrations and the cat only
3. **Spatial continuity.** Things come from where they were triggered: the create sheet rises from the ＋, a completed row slides into "Completed", a calendar block expands into its detail (hero).
4. **Interruptible.** Gestures (sheet drag, swipe actions) hand their velocity to the spring. Never block taps during an animation.
5. **Haptics pair with state change:** `selectionClick` for pickers and segments, `lightImpact` for completing a task, `mediumImpact` for the streak celebration, `heavyImpact` for nothing.
6. **Reduced motion** (`MediaQuery.disableAnimations` or the in-app toggle): springs become 150 ms cross-fades, the cat holds still, no parallax. Wrap this in one helper (`context.motion`) so no widget checks it by hand.

### 2.6 The cat, redesigned

**Concept.** A soft, geometric "loaf" cat in the spirit of Apple's character design: a few primitive shapes, no outlines, a single tint fill with one tonal shade, and big dark capsule eyes. It is expressive through *pose*, not through decoration (tears, snot bubbles and stroke outlines go away).

**Shapes.** The body is a squircle loaf (continuous corners) and the head merges into it. The ears are rounded triangles. The tail is one tapered bezier. The eyes are capsules, the nose is a tiny rounded triangle, and the mouth is a single stroked curve in the eye color. Colors: `tint`, `tint` darkened 12% for the inner ears and tail tip, and `label` for the eyes. In dark mode the fill uses the dark tint automatically.

**Architecture (the "logical" part).**

- `MascotPose` is an immutable value with lerpable fields: `eyeOpen (0..1)`, `eyeCurve (-1 sad .. 1 happy ^^)`, `pupilOffset`, `earAngle`, `earDroop`, `mouthCurve`, `bodySquash`, `tailAngle`, `headTilt`, `blush (0..1)`.
- `MascotMood` (`idle`, `focused`, `happy`, `sad`, `sleeping`) maps to a target pose. Mood comes from the same daily-progress rules as today, moved into a pure `MascotMoodResolver` in domain (unit-tested).
- `MascotController` drives each field toward the target with its own spring, so mood changes **morph** naturally instead of swapping animations.
- `MascotPainter` only paints a `MascotPose`: no timers or logic inside it.

**Behaviors.** Each one has a trigger, so nothing plays at random beyond idle life:

| Trigger | Response |
| --- | --- |
| Idle | Breathing (`bodySquash` ±1.5%, 4 s), blink every 3-7 s (random), eyes slowly follow scroll direction |
| Tap the cat | Ear twitch + head tilt + `selectionClick`; 1 in 5 taps shows a small "miau" bubble |
| Task completed anywhere | Hop (bouncy spring on Y + squash on landing), eyes `^^` for 1.2 s |
| All tasks done today | Settles into `happy`: blush on, tail curls |
| Streak at risk (after 20:00, nothing done) | `sad`: ears droop, eyes look down; no tears |
| Rest day / night (00:00-06:00) | `sleeping`: eyes closed, slow breathing, a "z" drifts up only when tapped |
| Focus session running | `focused`: eyes half-open looking at the timer, tail still |
| Reduced motion | Static pose for the current mood; still changes mood, without animation |

Semantics: the mascot exposes a label such as "Kairo the cat, happy: all tasks done today".

### 2.7 Review against generic defaults

- The old cream background, high-contrast serif and earthy accent read as a generic "editorial" template, so they are retired.
- Avoid the SaaS card kit: grouped lists with a radius hierarchy instead of identical shadowed cards. No drop shadows except on sheets and menus (system-like).
- No all-caps eyebrow labels. Section headers are sentence case (`footnote`, secondary label), like iOS Settings.
- No glass everywhere. Translucency is only for the nav and tab bars, where it carries meaning (content scrolls underneath).

---

## 3. Functional improvements bundled into the redesign

Each screen is redesigned **and** moved to proper layers in the same pass. Order matters: do the shared pieces first.

### Tasks
- Swipe actions (Mail-style): leading swipe to complete, trailing swipe to delete or edit, with full-swipe commit, spring and haptic. Undo snackbar for delete and complete.
- Long-press context menu: edit, duplicate, share with…, change priority, focus on this.
- Create sheet: title-first quick add (Return creates). Optional fields reveal progressively: date, time, priority, share. Natural date chips: Today, Tomorrow, This weekend.
- Merge `create_task_sheet` and `edit_task_sheet` (500 lines each, mostly duplicated) into one `TaskFormSheet`.
- **Subtasks** (checklist inside a task): new `subtasks` table plus RLS migration. ADHD roadmap item.
- Sections: Overdue, Today, Upcoming, No date, Completed (collapsible).

### Calendar
- Move all 10 Supabase calls to `CalendarRepository` and `CalendarBloc`.
- Day and week views: pinch to change hour density, drag a block to reschedule (snaps to 15 min with haptic ticks), tap empty slot to create a task at that time.
- Month view: dots instead of truncated titles; tapping a day opens its agenda below (iOS Calendar pattern).

### Social
- Split the 1238-line page into `FriendsRepository`, `SocialBloc` and widgets (friend row, request row, search).
- Search with debounce (`bloc` transformer), empty and loading states, avatars with initials fallback.
- Color picker uses a system-style palette grid of accessible colors, not free RGB.

### Profile / Settings
- iOS Settings-style grouped list. All 13 Supabase calls go through `ProfileRepository` and `ProfileCubit`.
- New settings: **reduce motion** (in-app override), **haptics on/off**, text size preview.

### Dashboard
- Cat hero plus "Today" summary ring (Activity-style), streak, next task with a one-tap Focus action.

### Focus
- Circular progress ring that drains, using tabular numerals and the `timer` style.
- Session persists if the app is backgrounded (store end timestamp, not ticks).
- Live Activity or Dynamic Island: out of scope (needs native code); note it for the future.

### Cross-cutting
- **Offline-first cache** for tasks (roadmap V 01.08): local store plus an outbox for pending mutations, replayed on reconnect via `connectivity_plus`. Do it after the tasks layer is clean.
- Skeleton loading (`shimmer`) only where load takes more than 300 ms; error states with a retry action and plain-language copy.
- Remove `debugLogDiagnostics`, route literals to `RouteNames`, typed route params.

---

## 4. Execution phases

Each phase ends green: `flutter analyze` (0 issues), `flutter test`, golden screenshots reviewed in light, dark and 200% text.

| Phase | Scope | Exit criteria |
| --- | --- | --- |
| **0. Foundation** | Fix bugs 1.2. Wire DI (injectable) for existing repos and blocs. Test setup (mocktail, bloc_test, golden helper that loads real fonts). Add `CLAUDE.md` → `@AGENTS.md`. | App runs unchanged; first unit and bloc tests pass |
| **1. Design system** | `KairoColors` ThemeExtension, typography per platform, `app_motion.dart`, `context.motion`, haptics service. Shared components in `core/widgets/`: `KairoLargeTitleScaffold`, `GroupedSection` / `GroupedRow`, `KairoButton` (filled, tinted, plain), `KairoSheet` (detents), `CheckCircle`, `PriorityBadge`, `Avatar`, `EmptyState`, `SegmentedControl`, translucent `KairoTabBar`. A hidden debug-only `/gallery` route shows every component. | Golden tests for each component in light, dark and 200% text |
| **2. Cat** | `MascotPose`, `MascotController`, `MascotPainter`, `MascotMoodResolver` (pure plus tests), behaviors table. Mood preview in `/gallery`. | Mood resolver 100% covered; goldens per mood |
| **3. Tasks** | Repository, use cases and bloc cleanup. `TaskFormSheet`. Swipe actions, context menu, sections. Subtasks migration. | Bloc tests for create, edit, toggle, delete and undo |
| **4. Calendar** | Repository and bloc, new views, drag to reschedule | |
| **5. Social** | Split page, repository and bloc, debounce search | |
| **6. Profile / Settings** | Grouped settings, new motion and haptics settings | |
| **7. Dashboard + Focus + Onboarding + Login** | New hero, ring, onboarding in the new style | |
| **8. Offline cache** | Local store, outbox, conflict policy (last-write-wins on `updated_at`) | |
| **9. Docs** | Rewrite `docs/design.md` for this system, update `architecture.md` and `README`, `CHANGELOG` `V 02.00.00` | Docs match code |

### Verification workflow (requires running locally on the Mac)

```bash
flutter analyze
flutter test
flutter test --update-goldens test/goldens   # then review PNGs in test/goldens/
flutter run -d "iPhone 16 Pro" --dart-define-from-file=.env
xcrun simctl io booted screenshot /tmp/kairo.png
```

Golden tests must load the real fonts (Inter from assets for determinism) or text renders as boxes. Keep goldens under `test/goldens/` and do not commit failure diffs.

---

## 5. Open decisions

- **Platform fidelity on Android:** one Apple-style UI on both platforms (assumed in this plan), or Material 3 on Android?
- **Subtasks and offline:** confirm they belong in 2.0 or go to 2.1.
- **Live Activities and widgets** (iOS home screen widget showing today's tasks and the cat): needs Swift code; candidate for 2.1.
