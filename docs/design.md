# Kairo - Design System

> Kairo 2.0 direction: **"Calma viva, con carácter"**. Mature and elegant, but alive.
> The plan and phase status live in [redesign-plan.md](redesign-plan.md). Sections marked *(target)* describe the approved prototype and are not in the code yet; everything else describes the code as it is.

---

## Design Philosophy

Kairo is a calm, ADHD- and autism-friendly productivity app that people use together. It should feel like a quiet, well-made object with a little life in it.

### Core Principles

1. **One thing at a time.** Every screen has one obvious next action ("Ahora", "Enfocar", "Crear tarea").
2. **Quiet surfaces, one accent.** Light neutral ground and white cards; a single dark `ink` surface per screen carries the accent.
3. **Motion answers an action.** Things move because you did something or because state changed. The cat is the only ambient life, and reduced motion stops it.
4. **Kind language.** No guilt and no red badges for being behind. Kairo suggests; he never scolds.
5. **Accessible by construction.** WCAG AA text, 44 px targets, Dynamic Type up to 200%, never color alone.

### Anti-Patterns (What We Avoid)

- Childish styling: chunky hard shadows, saturated candy colors, emoji as icons.
- SaaS templates: identical shadowed cards, gradients, glassmorphism everywhere, left-border accent cards.
- All-caps eyebrow labels. Section headers are sentence case.
- Decorative motion that plays on its own (except Kairo's idle life).
- Information carried by color alone.

---

## Color

Tokens live in `lib/app/theme/kairo_colors.dart` (`ThemeExtension<KairoColors>`). Read them with `context.appColors`. `test/app/theme/kairo_colors_test.dart` enforces AA for every text token on `background`, `surface` and `surfaceRaised`.

### Core tokens

| Token | Name | Light | Dark | Use |
| --- | --- | --- | --- | --- |
| `background` | Niebla | `#F1F2EF` | `#0E1012` | Screen background |
| `surface` | | `#FFFFFF` | `#181B1E` | Cards, grouped rows |
| `surfaceRaised` | | `#FFFFFF` | `#22262A` | Sheets, menus |
| `fill` | | `#E6E9E5` | `#2A2E33` | Segmented control tracks, inputs |
| `label` | Tinta | `#121417` | `#F3F5F2` | Primary text |
| `labelSecondary` | Pizarra | `#59616B` | `#A7AFB7` | Secondary text |
| `labelTertiary` | | label @ 30% | label @ 30% | Placeholders and decoration only |
| `separator` | | `#E1E4E0` | `#2E3237` | Hairlines and outlines |
| `tint` | Pino | `#1E5B45` | `#86CFA0` | Brand, progress, selection |
| `tintSoft` | | `#E3EEE8` | tint @ 18% | Soft chips ("Kairo sugiere") |
| `onTint` | | `#FFFFFF` | `#0E1012` | Text on `tint` |
| `ink` | | `#121417` | `#262A30` | The accent surface: tab bar, "Ahora" card, primary buttons |
| `onInk` | | `#F3F5F2` | `#F3F5F2` | Text on `ink` |
| `onInkSecondary` | | `#A7AFB7` | `#A7AFB7` | Secondary text and idle icons on `ink` |
| `lime` | Lima | `#C6E96F` | `#C6E96F` | Accent on `ink` only: active tab, Enfocar, focus ring |
| `onLime` | | `#121417` | `#121417` | Text and icons on `lime` buttons |
| `apricot` | Albaricoque | `#E58A52` | `#F0A070` | Streak flame, celebrations. **Never text** (2.6:1 on white) |
| `destructive` | | `#C8323F` | `#FF7A7A` | Delete, errors |
| `onDestructive` | | `#FFFFFF` | `#0E1012` | Text on `destructive` |

Legacy 1.x names (`accent`, `textPrimary`, `textMuted`, ...) remain as getters that map onto these tokens until every screen is migrated (V11 deletes them).

### Priority

Always a dot **and** a label; never color alone.

| Priority | Light | Dark |
| --- | --- | --- |
| Urgente | `#C8323F` | `#FF7A7A` |
| Alta | `#A9550E` | `#F2A65A` |
| Media | `#3F6FA8` | `#86AEE3` |
| Baja | `#646C75` | `#A7AFB7` |

### Calendar and people *(target)*

Five muted tones; text on them is always `label`, and a darker dot of the same hue marks the owner.

| Name | Fill | Dot | Text |
| --- | --- | --- | --- |
| Salvia | `#DCEBE1` | `#3E8A62` | `#2C5B42` |
| Azul | `#DDE7F2` | `#3F6FA8` | `#2D4F78` |
| Arcilla | `#F4E2D7` | `#C26A3D` | `#7A3B1A` |
| Iris | `#E6E3F5` | `#6A62B8` | `#3B3570` |
| Arena | `#F1EAD2` | `#A1842A` | `#5E4C12` |

Owner colors still come from `profiles.color` and the per-side `friendships.*_color` (see Visibility below); V7 maps stored colors onto the nearest tone.

### Visibility & Privacy

- `profiles.calendar_visibility` controls whether accepted friends see your tasks in their calendar.
- Private (default): only you and the people you share a task with see it; friends see "Busy" blocks.
- Public: accepted friends see your dated tasks through the `get_public_friend_tasks` RPC (`SECURITY DEFINER`). A task with unknown visibility is treated as private.
- Task details and sharing are protected by RLS; public calendar data is exposed only through the RPC.
- Friend colors are stored per side (`requester_color` / `addressee_color`), so each user customizes their own view.

---

## Typography

**Manrope** on every platform, bundled as static weights 400-800 (`assets/fonts/Manrope-*.ttf`, OFL, cut from the official variable font). Styles live in `lib/app/theme/kairo_typography.dart`; read them with `context.typography`. Styles carry no color.

| Role | Size / line | Weight | Tracking | Usage |
| --- | --- | --- | --- | --- |
| `largeTitle` | 30 / 36 | 800 | -0.8 | Tab titles ("Buenos días", "Planear") |
| `title1` | 26 / 32 | 800 | -0.6 | Sheet titles, Kairo page |
| `title2` | 20 / 26 | 800 | -0.4 | Section headers ("Pendientes") |
| `title3` | 18 / 24 | 700 | -0.3 | Card titles |
| `headline` | 16 / 22 | 700 | -0.1 | Row titles, buttons |
| `body` | 16 / 22 | 600 | 0 | Single-line text |
| `bodyMultiline` | 16 / 22 (1.38) | 600 | 0 | Suggestions, descriptions |
| `callout` | 15 / 20 | 600 | 0 | Chips, secondary rows |
| `subheadline` | 14 / 19 | 600 | 0 | Metadata |
| `footnote` | 13 / 18 | 600 | 0 | Hints, section footers |
| `caption1` | 12 / 16 | 600 | 0 | Calendar labels; the smallest text |
| `timer` | 58 / 1.0 | 600, tabular | -2 | Focus countdown |

Rules:
- Numbers that change (counts, times, percentages) use tabular figures.
- Sizes go through `MediaQuery.textScaler`; test at 200%. Never hardcode `fontSize` in widgets.
- Sentence case everywhere. No manual letter spacing outside these tokens.

---

## Layout

### Spacing

4 px grid (`AppSpacing`). Screen margin 18. Gaps between cards 10-14.

### Radii

| Element | Radius |
| --- | --- |
| Rows inside a card | 0 (the card clips them) |
| Metric tiles, list cards | 22 |
| Hero cards ("Kairo sugiere", "Ahora") | 28 |
| Sheets | 30 top |
| Segmented control | 14 track, 11 thumb |
| Buttons, chips, tab bar | capsule |
| Avatars | circle |

### Elevation

Cards: `0 1 2 rgba(18,20,23,.04)` plus `0 12 32 rgba(18,20,23,.06)` for the hero only; other cards are flat white on Niebla. The tab bar and sheets get `0 12 32 rgba(18,20,23,.24)`. No other shadows.

### Touch targets

Minimum 44 × 44 for everything tappable, including icon buttons and check circles (draw 28, hit 44).

---

## Navigation

`ShellScaffold` uses `KairoTabBar`: Hoy (`/dashboard`), Planear (`/calendar`), Juntos (`/social`) and Yo (`/profile`), with ＋ opening the task form. The full task list lives at `/dashboard/tasks` ("Ver todas las tareas" on Hoy; old `/tasks` links redirect there). A floating `ink` capsule (64 px high, 18 px from the sides, 26 px from the bottom). Five slots:

1. **Hoy** · 2. **Planear** · 3. **＋** (lime circle, opens the create sheet) · 4. **Juntos** · 5. **Yo** (avatar)

The active tab is a `#262A30` pill with a lime icon and label; inactive tabs are icon-only in `onInkSecondary` with an accessibility label. The pill morphs between tabs with the `smooth` spring.

---

## Components

Shared components live in `lib/core/widgets/` and are listed in the debug `/gallery` route: `KairoButton`, `KairoChip`, `KairoSegmentedControl`, `KairoCard`, `KairoEntrance`, `KairoTabBar`, `GroupedSection`, `showKairoSheet`. Screens adopt them from V4 on.

### Cards and lists
- `KairoCard` styles: `tile` (white, 22), `hero` (white, 28, soft elevation), `ink` (dark accent, 28).
- White card, radius 22, rows separated by 1 px `#EEF0ED` lines; no card per row.
- Row: 28 px check circle (2 px ring in the priority color), title (`body`), meta line with priority dot + label + time (`subheadline`, secondary).

### Hoy
- `TodayPage` (`features/dashboard/presentation/pages/`) reads `TodaySummary` (domain, pure): overdue + today pending, done today, streak, next timed task, Kairo's suggestions.
- Metrics are streak, overdue and % of the day; focus time joins them once Focus records sessions (V6).

### Kairo hero (Hoy)
- White card, radius 28: Kairo (132 px) on the left; "Kairo sugiere" chip (`tintSoft` / `tint`), one-sentence suggestion (`bodyMultiline`), and a segmented progress bar (one segment per task, `tint` when done).

### "Ahora" card
- `ink` card, radius 28: lime chip "Ahora · en 18 min", title in `onInk`, meta in `onInkSecondary`, lime "Enfocar" capsule.

### Metric tiles
- Three white tiles: icon (streak flame in `apricot`, clock in `tint`, check in priority-medium blue), value (22/800, tabular), label (`caption1`, secondary).

### Buttons
- **Primary:** `ink` capsule, `onInk` text, 52-56 px.
- **Accent:** `lime` capsule with `onLime` text, only on `ink` surfaces.
- **Outline:** white capsule, 1 px `separator`, `label` text.
- **Disabled:** `fill` background, secondary text, plus a reason ("Escribe qué quieres hacer").

### Chips and segmented control
- Chips: capsule with a 1 px outline; selected is `ink` with `onInk` text.
- Segmented control: `fill` track, white thumb with a soft shadow that slides between options.

### Sheets
- Radius 30 top, grabber, background dimmed to 50%. *(target, V5)* Background scales to 0.94. Kairo peeks over the top edge and reacts to typing.

### Focus screen (V6)
- Dark (`#0E1012`) whatever the theme. 310 px lime ring that drains, with a dot at the head of the arc; Kairo (focus mood) inside the ring above the `timer`; session pills; reset, play/pause (lime, 84 px), +5.

---

## Kairo, the cat

### Implementation

`lib/features/dashboard/presentation/widgets/mascot/`:
- `MascotPose`: lerpable pose. Mood fields plus `stand`, `lean`, `paw`, `yawn`, `flick` and `headY` for the cat things.
- `MascotController`: one spring per field, plus blinks, breathing and the tail sway.
- `MascotBehaviorScheduler`: pure; takes time in seconds and an injected `Random`.
- `MascotPainter`: paints the calico for a pose and the day's progress.
- `KairoMascot`: the widget, with `progress`, `hopTrigger`, `onLongPress` and a `cue` for the gallery.

The mood itself comes from `MascotMoodResolver` (domain, pure). The debug `/gallery` route can trigger each behavior.

- **Look:** a fluffy calico. Fur `#FBF8F3` with a `#D9CFC2` outline, orange `#E0893F` and black `#24272B` patches (black left ear and eye patch, orange right ear and cheek, patches on the flanks), white scalloped chest ruff, cheek tufts, ear tufts, green-yellow eyes `#A9C95B` with slit pupils and a highlight, pink nose `#E58F86` and inner ears `#E9AFA3`, thick orange tail with a black tip.
- **Progress:** a thin white line runs along the tail with the day's progress.
- **Idle life:** breathing, blinking every 3-7 s, eyes following the finger. Every 5-11 s when idle or happy: stand up, stretch, groom a paw, yawn, look aside, or flick the tail.
- **Reactions:** completing a task makes him hop (squash and stretch). A tap twitches his ears, triggers a small behavior and rotates the suggestion. Long-press opens Focus.
- **Moods:** idle; happy (^^ eyes, blush, sparkles in lime and apricot); focus (half-lidded, looking down at the timer, still tail); sleep (lower and curled, closed eyes, "z" on tap); worried (ears down, looking down, low tail). Mood comes from `MascotMoodResolver`.
- **Accessibility:** a semantics label such as "Kairo, el gato calicó, feliz". Reduced motion shows a still pose per mood and no behaviors.

---

## Motion

Springs live in `lib/app/theme/app_motion.dart` (`KairoSpring.smooth`, `snappy`, `bouncy`); widgets read `context.motion`, which turns into 150 ms cross-fades under reduced motion.

| Pattern | Spec |
| --- | --- |
| Entrance | Cards rise 12-16 px and fade in, 60 ms apart (`smooth`) |
| Press | Scale to 0.95, release with `snappy` |
| Selection | Pills and segmented thumbs slide (`smooth`) |
| Complete task | Check draws (400 ms), row slides right and fades, Kairo hops (`bouncy`), `lightImpact` |
| Sheet | Rises with `smooth`; background dims and scales to 0.94 |
| Focus ring | Drains linearly, one step per second |

Haptics: `selectionClick` for pickers and segments, `lightImpact` for completing a task, `mediumImpact` for the streak celebration.

---

## Accessibility Checklist

- [ ] Text meets 4.5:1 (enforced by the color test); `apricot` and `lime` never carry text on light surfaces.
- [ ] Every icon-only control has a semantics label or tooltip.
- [ ] Targets are at least 44 × 44.
- [ ] Layouts hold at 200% text (goldens include a large-text variant).
- [ ] Priority, sharing and state never rely on color alone.
- [ ] Reduced motion (system or in-app) stops ambient motion and replaces springs with cross-fades.

---

## Internationalization

All copy goes through `context.l10n` (`lib/l10n/app_en.arb`, `app_es.arb`). Dates, weekdays and times use `MaterialLocalizations` and respect the 24-hour setting.

---

## Implementation Guide

### Colors

```dart
final colors = context.appColors;
Container(color: colors.surface);
Text('Ahora', style: TextStyle(color: colors.onInk));
```

### Typography

```dart
Text('Pendientes', style: context.typography.title2);
Text(meta, style: context.typography.subheadline.copyWith(
  color: context.appColors.labelSecondary,
));
```

### Adding a component

1. Build it in `lib/core/widgets/` from tokens only (no raw hex, no raw font sizes).
2. Add it to the debug `/gallery` route.
3. Add golden tests (light, dark, 200% text) under `test/goldens/`.
