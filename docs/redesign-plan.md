# Kairo 2.0 - Redesign Plan (v2: "Calma viva, con carácter")

> Working brief for the V 02.00.00 redesign. Rewritten on 2026-10-21 after the interactive prototype was approved.
> When a phase ships, update `docs/design.md` / `docs/architecture.md` so they describe the code as it is, and log it in `CHANGELOG.md`.

Per the changelog convention a full redesign is a **major** bump: `V 02.00.00`. Intermediate phases ship as `V 01.x`; cut `2.0.0` when every screen uses the new direction.

**Prototype (source of truth for the look):** the Kairo 2.0 canvas on claude.ai (artifact `3sbNk11BjYsLwPu1Qmf5FV`, private to the owner). Boards: Hoy, Crear tarea, Foco, Planear, Juntos, Kairo (el gato), Sistema, and the `Cat` component.

---

## 1. Where we are

Phases 0-4 of the first plan shipped (V 01.19 - V 01.25) and stay valid underneath the new look:

| Done | What it gave us |
| --- | --- |
| 0. Foundation | Bug fixes, DI with injectable, test setup (mocktail, bloc_test, golden helper) |
| 1. Design system | `KairoColors` / `KairoTypography` ThemeExtensions, `app_motion.dart` springs, `context.motion`, haptics, shared components in `core/widgets/`, debug `/gallery` |
| 2. Mascot | `MascotPose`, `MascotController`, `MascotPainter`, pure `MascotMoodResolver` |
| 3. Tasks | Repository, use cases, optimistic `TasksBloc`, `TaskFormSheet`, sections, swipe actions |
| 4. Calendar | `CalendarRepository` + `CalendarCubit`, hour grid (pinch, tap to create, drag to reschedule), month view with agenda |

The architecture (Clean Architecture, BLoC, repositories, use cases) does not change. What changes is the **visual direction**: the "Apple-native calm" look of plan v1 read as too plain, and the first playful prototype read as too childish. The approved direction sits between them.

---

## 2. Design direction - "Calma viva, con carácter"

Mature and elegant, but alive. Calm comes from a quiet palette and clear hierarchy; character comes from motion, one dark accent surface per screen, and Kairo the cat.

Full tokens and component rules live in `docs/design.md`. Summary:

### 2.1 Palette

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `background` (Niebla) | `#F1F2EF` | `#0E1012` | Screen background |
| `surface` | `#FFFFFF` | `#181B1E` | Cards, grouped rows |
| `surfaceRaised` | `#FFFFFF` | `#22262A` | Sheets, menus |
| `fill` | `#E6E9E5` | `#2A2E33` | Segmented tracks, inputs |
| `label` (Tinta) | `#121417` | `#F3F5F2` | Primary text |
| `labelSecondary` (Pizarra) | `#59616B` | `#A7AFB7` | Secondary text (5.6:1 or better) |
| `separator` | `#E1E4E0` | `#2E3237` | Hairlines |
| `tint` (Pino) | `#1E5B45` | `#86CFA0` | Brand, progress, selected |
| `tintSoft` | `#E3EEE8` | tint @ 18% | Chips, soft highlights |
| `ink` | `#121417` | `#262A30` | The one dark surface: tab bar, "Ahora" card, primary buttons |
| `onInk` / `onInkSecondary` | `#F3F5F2` / `#A7AFB7` | same | Text on `ink` |
| `lime` | `#C6E96F` | `#C6E96F` | Accent **on ink only** (active tab, Enfocar, focus ring) |
| `apricot` | `#E58A52` | `#F0A070` | Streak and celebration. Icons and decoration only, never text (2.6:1) |
| `destructive` | `#C8323F` | `#FF7A7A` | Delete, errors |

Priority (always dot + label, never color alone): urgent `#C8323F`, high `#A9550E`, medium `#3F6FA8`, low `#646C75` (dark: `#FF7A7A`, `#F2A65A`, `#86AEE3`, `#A7AFB7`).

Calendar and people use five muted tones with ink text: sage, blue, clay, iris, sand (`design.md` §Color).

### 2.2 Typography

**Manrope** on every platform (bundled static weights 400-800, OFL). One family keeps iOS and Android identical and goldens deterministic. Titles 800 with negative tracking, text 600, tabular figures for numbers. Scale with `MediaQuery.textScaler` up to 200%. Inter and the DM fonts are retired.

### 2.3 Structure and navigation

Four destinations plus create, in a floating `ink` bar (64 px, capsule, 18 px from the edges). The active tab expands into a pill with its label in `lime`:

| Tab | Content |
| --- | --- |
| **Hoy** | Kairo hero with a suggestion, three metrics (streak, overdue, % of day; focus time once V6 records it), dark "Ahora" card with Enfocar, pending list, collapsible "Hechas", link to all tasks. Replaces Dashboard + Tasks. |
| **Planear** | Calendar (Día / Semana / Mes) and "Algún día" (tasks without a date). |
| **＋** | Create sheet (lime button in the bar). |
| **Juntos** | Friends, requests, shared tasks with progress, nudges, focus together. |
| **Yo** | Profile, settings, and Kairo's page. |

Cards are white on Niebla with soft elevation (`0 1 2 / 4%` + `0 12 32 / 6%`), radii 22-28. No hard drop shadows, no left-border cards, no gradients.

### 2.4 Motion

Same rules as v1 (motion answers an action, springs, interruptible, haptics paired with state, one reduced-motion switch through `context.motion`), plus the v2 vocabulary:

- **Entrance:** cards rise 12-16 px in a 60 ms cascade.
- **Response:** everything tappable scales to 0.95 and springs back.
- **Continuity:** selection pills slide between options; a completed row slides out to the right while its check draws itself; the tab pill morphs between tabs.

### 2.5 Kairo, the calico cat

Kairo is now a **fluffy calico**: white fur with orange (`#E0893F`) and black (`#24272B`) patches, green-yellow eyes, pink nose and inner ears, a scalloped chest ruff, cheek tufts, and a thick orange tail with a black tip. A soft outline keeps him readable on white cards; he works unchanged on the dark Focus screen.

**Useful, not decorative:**
- A thin white line runs along his tail as the day's progress.
- Tapping him gives a concrete suggestion (what to do first, how much is left, when to rest).
- Long-press starts a focus session.

**Alive:** breathing, random blinks, and eyes that follow the finger. Every 5-11 s when calm or happy he does a cat thing on his own: stands up, stretches, grooms a paw, yawns, looks aside, or flicks his tail. Completing a task makes him hop.

**Moods** keep the v1 rules and resolver (`MascotMoodResolver`): idle, happy (^^ eyes, blush, sparkles), focus (half-lidded, looking at the timer), sleep (curled, closed eyes, a "z" on tap), worried (ears down, looking down). Reduced motion shows a still pose per mood.

**Architecture:** extend `MascotPose` with `stand`, `lean`, `paw`, `yawn`, `flick` and `headY`, plus a `MascotBehavior` scheduler (pure, testable with a fake clock and seeded random). The prototype's `Cat` component is the reference for shapes and spring constants.

---

## 3. Execution phases

Each phase ends green: `flutter analyze` with 0 issues, `flutter test`, and goldens reviewed in light, dark and 200% text.

| Phase | Scope | Exit criteria |
| --- | --- | --- |
| **V1. Visual foundation** | New palette in `KairoColors` (plus `ink`, `onInk`, `onInkSecondary`, `lime`, `onLime`, `apricot`), Manrope bundled and used by `KairoTypography` and the legacy text theme, DM/Inter retired | Contrast tests pass; every golden re-reviewed |
| **V2. Components** | Restyle `core/widgets`: buttons (ink, lime, outline), chips, sliding segmented control, cards, grouped list, floating `KairoTabBar`, sheet. Entrance cascade and press scale in `app_motion.dart` | Goldens per component |
| **V3. Kairo calico** | New painter, extended pose, `MascotBehavior`, tap suggestions, long-press to focus | Behavior scheduler and resolver tests; goldens per mood and behavior |
| **V4. Navigation + Hoy** | 4 tabs + create; Hoy merges Dashboard and Tasks | Bloc tests for Hoy; golden of Hoy |
| **V5. Create sheet** | Restyle `TaskFormSheet` (Qué / Cuándo / Hora / Prioridad / Con alguien); Kairo peeks over the sheet | Widget tests kept green |
| **V6. Foco** | Dark screen, lime ring with a progress dot, Kairo in focus mood, rounds and rests, +5, task picker | Timer survives backgrounding (end timestamp) ✓ |
| **V7. Planear** | Restyle calendar views (tones, week strip, header); "Algún día" sheet. Dragging from Algún día onto a day is deferred | Existing calendar tests green ✓ |
| **V8. Juntos** | Split `social_page.dart` (repository + bloc), new layout, nudges | Bloc tests |
| **V9. Yo, settings, onboarding, login** | Grouped settings (reduce motion, haptics, text size), Kairo page | |
| **V10. Offline cache** | Local store, outbox, last-write-wins on `updated_at` | |
| **V11. Docs + 2.0.0** | Final pass on `design.md`, `architecture.md`, README; `CHANGELOG` `V 02.00.00` | Docs match code |

Verification needs a Mac:

```bash
flutter analyze
flutter test
flutter test --update-goldens test/goldens
flutter run -d "iPhone 17 Pro" --dart-define-from-file=.env
```

---

## 4. Open decisions

- **Completed history and the full task list:** Hoy shows today and overdue, Planear shows dated and undated tasks. Does a "Todas" view still need to exist (for example under Yo), or is search enough?
- **Dark mode `ink`:** the dark surface becomes `#262A30` in dark mode. Confirm on device that the tab bar and the "Ahora" card still read as the accent surface.
- **Subtasks, Live Activities, widgets:** still planned for 2.1.
