# KairoTasks - Design System

> Zen/Calm Editorial design language with accessibility-first principles.

---

## Design Philosophy

### Core Principles

1. **Calm over chaos**: Every element has purpose. No decorative clutter.
2. **Accessibility first**: Designed for neurodivergent users (ADHD, Autism). Clear hierarchy, generous spacing, predictable patterns.
3. **Editorial typography**: Typography that breathes and guides the eye naturally.
4. **Intentional motion**: Animations serve a purpose (feedback, orientation). Never distracting.
5. **Inclusive contrast**: All text meets WCAG 2.2 AA minimum contrast ratios (4.5:1 for body, 3:1 for large text).

### Anti-Patterns (What We Avoid)
- Excessive gradients or glassmorphism
- Tiny text or cramped layouts
- Animations that can't be disabled
- Information overload on a single screen
- Generic Material Design "out of the box" look

---

## Color Tokens

### Light Mode

| Token | Hex | Usage |
|-------|-----|-------|
| `surface` | `#FAF9F7` | Main background - warm cream |
| `surfaceElevated` | `#FFFFFF` | Cards, elevated surfaces |
| `surfaceSubtle` | `#F3F1ED` | Input backgrounds, secondary areas |
| `textPrimary` | `#1A1A1A` | Primary text - near black |
| `textSecondary` | `#6B6B6B` | Secondary/supporting text |
| `textMuted` | `#9B9B9B` | Disabled, metadata, timestamps |
| `accent` | `#4A6741` | Primary action - sage green |
| `accentSoft` | `#E8F0E6` | Selected/hover states |
| `urgent` | `#C45D4A` | Urgent priority - warm red |
| `high` | `#D4894A` | High priority - amber |
| `medium` | `#6B8FA3` | Medium priority - slate blue |
| `low` | `#8B9D83` | Low priority - muted green |
| `border` | `#E5E2DE` | Subtle borders |

### Dark Mode

| Token | Hex | Usage |
|-------|-----|-------|
| `surface` | `#1A1B1E` | Main background |
| `surfaceElevated` | `#242529` | Cards, elevated surfaces |
| `surfaceSubtle` | `#2C2D31` | Input backgrounds |
| `textPrimary` | `#F0EDE8` | Primary text |
| `textSecondary` | `#B0ADA8` | Secondary text |
| `textMuted` | `#6B6964` | Disabled text |
| `accent` | `#7CAD71` | Primary action - lighter sage |
| `accentSoft` | `#2A3528` | Selected states |
| `urgent` | `#E07B6A` | Urgent - lighter red |
| `high` | `#E8A366` | High - lighter amber |
| `medium` | `#7FAABB` | Medium - lighter blue |
| `low` | `#A3B59B` | Low - lighter green |
| `border` | `#3A3B3F` | Borders |

### Priority Color System
Priority colors are used exclusively for:
- Left-side indicator bar on task cards
- Priority selector chips
- Priority filter badges
- Calendar dot indicators (when no owner color is set)

Never use priority colors for backgrounds or large areas.

### Visibility & Privacy
- `profiles.calendar_visibility` controls whether an accepted friend can see your tasks in their calendar
- Private (default): only you and users you explicitly share a task with can see it
- Public: all accepted friends can see your tasks with due dates via the `get_public_friend_tasks` RPC
- Task details and sharing are still protected by RLS; public only exposes task title, time and priority

### Calendar Color Coding
Calendar events are colored by their owner to help distinguish whose task is whose:
- **Own tasks**: use the current user's `profiles.color` (default: app `accent` green `#4A6741`)
- **Friend public tasks**: use the `friendships.*_color` assigned by the current user (default muted slate `#6B8FA3`)
- **Priority color**: used only as a fallback when no owner color is set

### Social Color Indicators
- Each friend row in the Social tab displays a small circular color chip
- Tapping the chip opens a color picker to change the friend's calendar color
- Colors are stored per-side (`requester_color` / `addressee_color`) so each user can customize their own view

---

## Typography

### Font Families
- **Display/Headings**: DM Serif Display (editorial, sophisticated)
- **Body/UI**: DM Sans (clean, highly readable, generous x-height)

### Type Scale

| Style | Font | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|------|--------|-------------|----------------|-------|
| `displayLarge` | DM Serif Display | 32px | 400 | 1.3 | 0 | App title, major headers |
| `displayMedium` | DM Serif Display | 28px | 400 | 1.3 | 0 | Section titles |
| `titleLarge` | DM Serif Display | 22px | 400 | 1.3 | 0 | Screen titles |
| `titleMedium` | DM Sans | 18px | 600 | 1.4 | 0 | Subtitles, card titles |
| `titleSmall` | DM Sans | 16px | 600 | 1.4 | 0 | Task titles |
| `bodyLarge` | DM Sans | 16px | 400 | 1.6 | 0.2px | Primary body text |
| `bodyMedium` | DM Sans | 14px | 400 | 1.6 | 0.2px | Secondary body text |
| `bodySmall` | DM Sans | 12px | 400 | 1.5 | 0 | Descriptions, captions |
| `labelLarge` | DM Sans | 14px | 600 | 1.4 | 0.3px | Buttons, chip labels |
| `labelMedium` | DM Sans | 12px | 500 | 1.4 | 0 | Small labels |
| `labelSmall` | DM Sans | 11px | 500 | 1.4 | 0.5px | Metadata, timestamps |

### Typography Rules
- Body line-height MUST be >= 1.5 (we use 1.6) for readability
- Never go below 11px for any text
- Letter spacing of 0.2-0.5px prevents character crowding (ADHD-friendly)
- Use DM Serif Display ONLY for display/title roles, never for body

---

## Spacing System

Base unit: **4px**

| Token | Value | Usage |
|-------|-------|-------|
| `spacing2` | 2px | Micro spacing (icon-text gap in inline elements) |
| `spacing4` | 4px | Tight spacing (between related elements) |
| `spacing8` | 8px | Small spacing (padding in dense UI) |
| `spacing12` | 12px | Comfortable gap (list item separation) |
| `spacing16` | 16px | Standard padding (input fields, cards) |
| `spacing20` | 20px | Section gap |
| `spacing24` | 24px | Screen padding (horizontal) |
| `spacing32` | 32px | Major section separation |
| `spacing40` | 40px | Large breathing room |
| `spacing48` | 48px | Hero spacing |
| `spacing64` | 64px | Bottom scroll overflow |

### Border Radii

| Token | Value | Usage |
|-------|-------|-------|
| `radiusSmall` | 8px | Chips, small cards |
| `radiusMedium` | 12px | Cards, inputs, buttons |
| `radiusLarge` | 16px | Bottom sheets, modals |
| `radiusXLarge` | 24px | Full-screen overlays |
| `radiusFull` | 999px | Pills, circular elements |

---

## Touch Targets

All interactive elements MUST meet minimum touch target requirements:

| Token | Value | Standard |
|-------|-------|----------|
| `minTouchTarget` | 44px | WCAG 2.5.8 / Apple HIG minimum |
| `buttonHeight` | 48px | Primary action buttons |
| `iconButtonSize` | 44px | Icon-only buttons |

---

## Component Patterns

### Task Card
```
┌─────────────────────────────────────────────┐
│▎  ○  Task Title                             │
│▎     Description text here...               │
│▎     📅 In 3 days                           │
└─────────────────────────────────────────────┘
 ↑  ↑   ↑
 │  │   └── Content: title, description, metadata
 │  └────── Circular checkbox (32px diameter)
 └───────── Priority color bar (4px width)
```

- Left border: 4px colored bar indicating priority
- Checkbox: Circle, unfilled when pending, filled accent when completed
- Card has 0.5px border + no elevation (clean look)
- Dismiss to left to delete (with red background hint)

### Filter Chips
- Pill-shaped (`radiusFull`)
- Selected: filled with accent color, white text
- Unselected: transparent with border, secondary text
- Horizontal scroll when overflow
- Height: 36px (with padding meeting 44px touch target via gesture area)

### Bottom Navigation
- 4 tabs: Tasks, Calendar, Social, Profile
- Outlined icons (unselected) / Filled icons (selected)
- Label always visible (no icon-only mode)
- No elevation shadow - separated by subtle border at top

### Create Task Bottom Sheet
- Rounded top corners (`radiusXLarge`)
- Handle bar indicator (40px wide, 4px height)
- Appears with slide-up animation (300ms)
- Keyboard-aware padding (adjusts when keyboard shows)
- Priority selector: 4 equal-width options in a row

### Empty States
- Centered vertically
- Large muted icon (64px)
- Title in `titleMedium`
- Subtitle in `bodyMedium` (secondary color)
- Optional CTA button below

---

## Animations & Motion

### Duration Standards
| Type | Duration | Curve |
|------|----------|-------|
| Micro-interactions | 200ms | easeInOut |
| Page transitions | 300ms | easeInOut |
| Modals/sheets | 300ms | easeOut |
| State changes | 200ms | easeInOut |
| Loading shimmer | continuous | linear |

### Motion Rules
1. **Respect `prefers-reduced-motion`**: Check `MediaQuery.disableAnimations`
2. **No decorative animations**: Every animation must serve UX (feedback, orientation, continuity)
3. **No auto-playing animations**: Nothing should move without user trigger
4. **Consistent direction**: Elements enter from bottom, exit to bottom. Navigation is horizontal.
5. **Never block interaction**: Animations don't prevent taps

---

## Accessibility Checklist

When implementing any new component, verify:

- [ ] Touch target >= 44x44px
- [ ] Text contrast >= 4.5:1 (body) or 3:1 (large text/decorative)
- [ ] Semantic labels on all icons/images
- [ ] Focus order is logical
- [ ] States are communicated (not just via color)
- [ ] Line height >= 1.5x for body text
- [ ] No text smaller than 11px
- [ ] Animations can be disabled via system setting
- [ ] Error states include text explanation (not just red color)

---

## Implementation Guide

### How to Use Colors in Widgets
```dart
// Access color scheme via context extension
final colors = context.appColors;

// Use colors
Container(
  color: colors.surface,
  child: Text('Hello', style: TextStyle(color: colors.textPrimary)),
);
```

### How to Use Typography
```dart
// Use theme text styles
Text('Title', style: context.textTheme.titleLarge);
Text('Body', style: context.textTheme.bodyLarge);

// Override specific properties when needed
Text(
  'Custom',
  style: context.textTheme.bodyLarge?.copyWith(
    color: context.appColors.accent,
  ),
);
```

### How to Add a New Component
1. Check if a similar component exists
2. Follow the spacing system (4px grid)
3. Use design tokens, never hardcode values
4. Ensure 44px minimum touch targets
5. Add semantic labels for accessibility
6. Test in both light and dark mode
7. Verify animations respect reduced-motion
