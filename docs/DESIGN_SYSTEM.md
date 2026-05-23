# Design System

> Last updated: 2026-05-08 — initial scaffold
> Responsible agent: any agent — update when UI decisions are made

## Philosophy

Calm, reverent, and focused. The app should feel like a quiet room — nothing competing for attention. The screen takeover especially should feel purposeful and sacred, not alarming.

**Principles:**
- Minimal chrome during prayer (full-screen, distraction-free)
- Warm, earthy palette — not cold tech
- Large, readable typography (legibility > style during prayer)
- Subtle animation, never jarring

---

## Color Palette

### Base
| Token | Hex | Use |
|-------|-----|-----|
| `background` | `#FAF7F2` | App background (warm off-white) |
| `surface` | `#F0EBE1` | Cards, panels |
| `surface-raised` | `#FFFFFF` | Modals, popovers |
| `border` | `#E5DDD0` | Dividers |
| `text-primary` | `#1C1917` | Body text |
| `text-secondary` | `#78716C` | Captions, metadata |
| `text-muted` | `#A8A29E` | Placeholders |

### Accent
| Token | Hex | Use |
|-------|-----|-----|
| `accent` | `#92400E` | Primary actions, links (deep amber/brown) |
| `accent-light` | `#FDE68A` | Highlights, tags |
| `accent-dark` | `#451A03` | Active states |

### Semantic
| Token | Hex | Use |
|-------|-----|-----|
| `success` | `#10B981` | Completed session |
| `warning` | `#F59E0B` | Snooze indicator |
| `error` | `#EF4444` | Errors |

### Theme Colors
Each prayer theme has its own accent color (defined in [CONTENT.md](CONTENT.md)). Used for theme cards and session backgrounds.

### Prayer Session (full-screen)
The session screen uses a deep, immersive background:
- Background: `#0C0A09` (near black, warm tint)
- Text: `#FDF8F0` (warm white)
- Border glow: theme color (passed from ChimeAlert / session config)
- Scripture text: `#D6C9B3` (muted warm)

---

## Typography

### macOS (SF Pro)
| Style | Font | Size | Weight |
|-------|------|------|--------|
| Title | SF Pro Display | 28pt | Semibold |
| Heading | SF Pro Display | 22pt | Medium |
| Body | SF Pro Text | 15pt | Regular |
| Caption | SF Pro Text | 12pt | Regular |
| Prayer Body | SF Pro Text | 17pt | Light — extra line height (1.8) |
| Scripture | SF Pro Text | 14pt | Italic |

### Mobile (System font / Expo)
| Style | Size | Weight | Line Height |
|-------|------|--------|-------------|
| Title | 26 | 600 | 32 |
| Heading | 20 | 600 | 26 |
| Body | 16 | 400 | 24 |
| Caption | 13 | 400 | 18 |
| Prayer Body | 18 | 300 | 34 |
| Scripture | 15 | 400 italic | 24 |

---

## Spacing Scale

Based on 4pt grid:

| Token | Value |
|-------|-------|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |
| `2xl` | 48 |
| `3xl` | 64 |

---

## Border Radius

| Token | Value | Use |
|-------|-------|-----|
| `sm` | 6 | Tags, chips |
| `md` | 12 | Cards |
| `lg` | 20 | Modals, sheets |
| `full` | 9999 | Buttons, avatars |

---

## Iconography

**macOS**: SF Symbols (native, no library needed)
**Mobile**: `@expo/vector-icons` using the `Ionicons` set as primary, supplemented with SF-Symbol-inspired Ionicons equivalents

Key icons:
| Action | SF Symbol | Ionicons |
|--------|-----------|---------|
| Pray / hands | `hands.sparkles` | `hand-left-outline` |
| Schedule | `clock` | `time-outline` |
| Library | `books.vertical` | `library-outline` |
| History | `calendar` | `calendar-outline` |
| Settings | `gearshape` | `settings-outline` |
| Randomize | `shuffle` | `shuffle-outline` |
| Amen / complete | `checkmark.circle.fill` | `checkmark-circle` |
| Snooze | `clock.arrow.circlepath` | `timer-outline` |

---

## Component Patterns

### Prayer Card
- Rounded card (`md` radius) on `surface` background
- Theme color accent bar on left edge (4px)
- Title in `Heading`, body preview truncated to 2 lines
- Scripture reference in `Caption`, italic

### Period Card
- Time large (`Title`), label below in `Caption`
- Active indicator dot (accent color)
- Swipe-to-delete on mobile; right-click context menu on macOS

### Full-Screen Prayer Session
- Full bleed dark background
- Prayer title centered, large
- Prayer body scrollable (if long), `Prayer Body` style
- Scripture block at bottom, separated by thin line
- Countdown ring (circular progress) top-right corner
- "Amen" button centered at bottom — primary filled style
- "Snooze" text button above Amen

### Theme Grid
- 2-column grid on mobile, 3-column on macOS sidebar
- Each theme: colored icon, name, topic count
- Tap → topic list within theme

---

## Animation Guidelines

- Prayer session entrance: fade + slight scale up (0.95 → 1.0), 300ms ease-out
- Countdown ring: continuous, smooth, no jitter
- Card interactions: scale 0.98 on press, 120ms
- Screen transitions: cross-fade preferred over slide (feels calmer)
- ChimeAlert: use default pulsating border from ChimeAlert config (theme color)

---

## Accessibility

- Minimum tap target: 44×44pt
- All interactive elements have accessibility labels
- Dynamic Type support on both platforms
- Prayer body font scales up to `accessibilityLarge` size classes
- Sufficient contrast ratios (WCAG AA minimum)

---

## Status

- [ ] Color tokens finalized and confirmed with user
- [ ] Typography confirmed
- [ ] Figma/design file created (if applicable)
- [ ] Design tokens implemented in mobile (theme.ts)
- [ ] Design tokens implemented in macOS (Color+Extensions.swift)
- [ ] Prayer session dark theme implemented on both platforms
