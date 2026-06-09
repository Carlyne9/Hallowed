# Hallowed Design System

> Last updated: 2026-06-05
> Reference used: CVtoWeb's local design-system structure, adapted for Hallowed's warmer and more devotional product language.

## Design Direction

Hallowed should feel like a quiet room: warm, focused, reverent, and gently encouraging. The interface should reduce friction without feeling sterile. During prayer, the app should become simpler, darker, and more immersive.

## Principles

- Calm over clever: visual choices should lower anxiety and help the user focus.
- Warmth over cold tech: use earthy neutrals, amber-brown accents, soft surfaces, and restrained contrast.
- Sacred focus during prayer: reduce chrome, hide unnecessary controls, and keep the timer readable but not dominant.
- Encouragement without gamification overload: achievements should feel joyful, not noisy.
- Native macOS first: use SF Symbols, native controls where helpful, and responsive split-view behavior.

## Token Architecture

Use named role tokens in code rather than raw hex values wherever possible.

Swift source of truth for macOS tokens:
`apps/macos/Hallowed/Extensions/HallowedDesign.swift`

Naming pattern:
- `HallowedDesign.Palette.*` for colors
- `HallowedDesign.Spacing.*` for spacing
- `HallowedDesign.Radius.*` for corner radius
- `HallowedDesign.Typography.*` for reusable font choices
- `HallowedDesign.Layout.*` for shared layout constants

## Color Tokens

### App Surfaces

| Token | Hex | Use |
|---|---:|---|
| `background` | `#FAF8F5` | Primary app background |
| `sidebar` | `#F5F1EB` | Navigation sidebar |
| `surface` | `#F2ECE4` | Soft panels/cards |
| `surfaceRaised` | `#FFFFFF` | Popovers, elevated cards, forms |
| `surfaceSubtle` | `#EFE7DC` | Chips, selected soft backgrounds |
| `border` | `#E8DDD3` | Default borders/dividers |
| `borderStrong` | `#D8CEC4` | Emphasized borders |

### Text

| Token | Hex | Use |
|---|---:|---|
| `textPrimary` | `#2D2420` | Main readable text |
| `textSecondary` | `#5A4A3A` | Secondary labels and form copy |
| `textMuted` | `#8B7B6E` | Metadata, helper text |
| `textFaint` | `#B0A098` | Empty states, inactive icons |
| `textOnAccent` | `#FFFFFF` | Text on primary action fills |

### Brand / Accent

| Token | Hex | Use |
|---|---:|---|
| `accent` | `#8B6F4E` | Primary actions and active emphasis |
| `accentHover` | `#7A5F3E` | Pressed/hover action state |
| `accentSoft` | `#EFE7DC` | Warm selected state background |
| `accentGlow` | `#C49A6C` | Highlights, theme glow, achievement trim |

### Semantic

| Token | Hex | Use |
|---|---:|---|
| `success` | `#6E8B62` | Completed/saved states |
| `warning` | `#C9852B` | Reminder or attention state |
| `destructive` | `#B94A36` | Delete/sign out/destructive actions |
| `urgent` | `#E07B5A` | Low timer/time-sensitive moments |

### Prayer Session

| Token | Hex | Use |
|---|---:|---|
| `PrayerSession.background` | `#1C1612` | Full-screen prayer background |
| `PrayerSession.surface` | `#261E18` | Prayer content shell |
| `PrayerSession.surfaceDeep` | `#1F1814` | Deeper gradient/surface layer |
| `PrayerSession.textPrimary` | `#F5EDE0` | Main prayer text |
| `PrayerSession.textMuted` | `#8B7B6E` | Timer/supporting labels |
| `PrayerSession.divider` | `#3D302A` | Dividers in prayer mode |

## Typography

macOS uses SF Pro/SF system fonts. We can add a custom serif later, but for now the serif moments should be restrained and intentional.

| Token | Font | Use |
|---|---|---|
| `appTitle` | 15 semibold serif | Hallowed wordmark/sidebar title |
| `screenTitle` | 28 semibold serif | Large page/session titles |
| `sectionTitle` | 22 bold rounded | Popover/profile section headings |
| `heading` | 18 semibold rounded | Card headings |
| `body` | 15 regular | Primary UI body text |
| `bodyStrong` | 15 semibold | Important body text |
| `label` | 13 medium | Navigation labels and controls |
| `caption` | 12 regular | Supporting text |
| `micro` | 10 regular | Dense metadata |
| `prayerBody` | 17 light | Prayer content |
| `scripture` | 14 italic | Scripture passages |

## Spacing

Based on a soft 4pt rhythm with practical macOS values.

| Token | Value |
|---|---:|
| `xxs` | 2 |
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `xl` | 24 |
| `xxl` | 32 |
| `xxxl` | 48 |
| `huge` | 64 |

## Radius

| Token | Value | Use |
|---|---:|---|
| `xs` | 6 | Tiny tags |
| `sm` | 10 | Buttons/chips |
| `md` | 12 | Inputs and standard cards |
| `lg` | 16 | Larger cards/profile rows |
| `xl` | 20 | Sheets/forms |
| `xxl` | 28 | Prayer session shell |
| `full` | 999 | Circular avatars/pills |

## Layout

| Token | Value | Use |
|---|---:|---|
| `sidebarMinWidth` | 230 | Current sidebar minimum |
| `sidebarIdealWidth` | 250 | Current sidebar ideal |
| `sidebarMaxWidth` | 290 | Current sidebar maximum |
| `popoverWidth` | 520 | Profile/settings popover |
| `minimumHitArea` | 44 | Accessibility target size |

## Component Rules

### Sidebar

- Keep navigation labels readable unless we intentionally commit to an icon rail.
- Profile footer should feel integrated with the sidebar, not like a floating card.
- Primary actions can live in the toolbar when they are global, such as `Pray Now`.

### Profile Popover

- Profile identity first: avatar + name.
- Settings live here, grouped in raised white cards.
- Sign out stays at the bottom as the destructive action.
- Achievements should feel celebratory but quiet.

### Prayer Period Form

- Prefer clear grouped sections over dense settings.
- Use warm surfaces and active accent chips.
- Avoid forced recurrence when the user selected a specific date.

### Themed Prayer Flow

- Keep hierarchy obvious: Themes -> Topics -> Prayer Points.
- Back actions should be singular and predictable.
- Responsive behavior should avoid clipping at partial window widths.

### Prayer Session

- Full-screen prayer is dark, immersive, and centered.
- Timer and step indicators should be visible but secondary.
- For themed prayers, prayer bullet points and scripture can be paced across the selected duration.
- For just-pray sessions, do not show step counts.

## Motion

- Use fade/scale for prayer session entry.
- Use subtle hover/press states, not bouncy motion.
- Avoid constant animation outside the active prayer session.
- ChimeAlert-style pulsing is appropriate only for prayer/session focus moments.

## Accessibility

- Minimum hit area: 44pt.
- All icon-only buttons need accessibility labels/help text.
- Avoid relying on color alone for status.
- Preserve text readability over decorative layout.
- Use line limits carefully; identity text should be allowed enough room where possible.

## Migration Plan

- Add macOS design tokens. Done.
- Gradually replace repeated `Color(hex:)` values with `HallowedDesign.Palette` references.
- Extract reusable cards/buttons/chips only after the current profile/settings experiment stabilizes.
- Keep this document updated as the UI direction settles.

## ElevenLabs-Inspired Adaptation

Research source notes:
- ElevenLabs UI is a shadcn-based component library for multimodal agent, transcription, audio, and voice interfaces. Relevant components include Orb, Waveform, Live Waveform, Audio Player, Conversation, Speech Input, Transcript Viewer, Voice Button, Voice Picker, and Shimmering Text.
- ElevenLabs brand guidance emphasizes generous clearance, simple symbols, neutral/monochrome precision for API surfaces, orange for creative surfaces, blue/spherical graphics for agents, and Chladni-pattern/audio-inspired graphic motifs.
- Apple platform guidance remains the constraint layer: use native platform controls where possible, keep interactions familiar, maintain readable typography, support accessibility, and preserve at least 44pt interactive targets.

How we adapt this for Hallowed:
- Use signal/orb/waveform language for prayer state, timer, chime, and completion moments.
- Keep Hallowed's warm devotional palette instead of copying ElevenLabs' brand colors.
- Avoid ElevenLabs marks, logos, exact brand assets, or trademarked visual shorthand.
- Prefer soft pulse and waveform motion only during active prayer moments.
- Use neutral raised cards and pill controls sparingly, with native macOS/iOS behavior intact.

### Signal Components

Swift source:
`apps/macos/Hallowed/Extensions/HallowedSignalViews.swift`

| Component | Purpose | Current Use |
|---|---|---|
| `HallowedSignalOrb` | Soft pulse/completion/focus state inspired by audio orbs | Prayer completion state |
| `HallowedWaveform` | Compact living signal for timed prayer state | Timer capsule in prayer session |

Guidelines:
- Orbs should represent state, not decoration.
- Waveforms should be subtle and low-contrast unless the timer is urgent.
- Motion should stop or become static when the state is complete.
- Always pair visual state with text so VoiceOver and low-vision users are not dependent on motion/color.

### Future Components To Consider

- `PrayerTranscriptCard`: for a future spoken/reflection history experience.
- `PrayerVoiceButton`: if voice input or spoken prayer notes are added.
- `PrayerResponseCard`: for Bible/API fallback messages and generated prayer summaries.
- `PrayerShimmerText`: only for loading scripture or preparing a prayer session; avoid decorative shimmer during active prayer.
- `PrayerSignalPicker`: if we later add chime sounds, notification tones, or voice-guided prayer modes.

## Apple Platform Guardrails

- Minimum interactive target is 44x44pt.
- Keep macOS sidebar navigation label-based unless the compact rail is explicitly committed and tested.
- On iOS, avoid dense desktop sidebars; use stack/tab/navigation patterns that preserve reachability and safe areas.
- Prefer native `Button`, `Toggle`, `Picker`, `NavigationSplitView`, sheets, and popovers before custom controls.
- Do not use time-boxed dismissals for critical messaging; prayer completion should remain visible until the user acknowledges it.
- Keep custom animated controls accessible with labels, reduce-motion compatibility where possible, and text alternatives.

## Warm Spatial Direction

This is the current visual direction for Hallowed.

Spatial does not mean sci-fi or glass everywhere. For Hallowed, it means the interface has depth, air, and atmosphere while staying quiet and readable.

Visual ingredients:
- Warm layered backgrounds instead of flat off-white pages.
- Soft amber, rose, and olive aura glows used as environmental depth.
- Raised translucent cards for important content, with white-to-warm borders.
- Earthy amber-brown actions with soft shadows.
- Rounded, tactile cards that feel calm rather than sharp.
- Signal/orb moments used sparingly for prayer state, not decoration.

Implementation:
- `HallowedSpatialBackground` provides the shared atmospheric page backdrop.
- `HallowedSpatialCard` provides raised translucent surfaces.
- Dashboard greeting, scripture, stat cards, and profile popover cards now use this language.

Guardrails:
- Do not place glass cards over low-contrast text.
- Do not use motion/glow on every component; reserve it for prayer state, completion, or hero moments.
- Keep native macOS controls recognizable inside spatial surfaces.
- Use warm colors from tokens, not arbitrary new hex values.
