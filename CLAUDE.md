# Hallowed — Master Project Context

> **App name: Hallowed** (confirmed 2026-05-19)
> **Bundle IDs**: `com.hallowed.app` (iOS + Android), `com.hallowed.macos` (macOS)

## What This App Is

A cross-platform prayer companion that lets users schedule prayer periods, browse and randomize from a curated library of prayer themes/topics (each with scriptures), and — critically — take over the screen at prayer time so nothing interrupts the session.

## Platforms

| Platform | Tech Stack | Agent Responsibility |
|----------|-----------|----------------------|
| macOS (13+) | Swift 5.9+, SwiftUI, ChimeAlert | `macos-agent` |
| iOS + Android | Expo (React Native, bare workflow) | `mobile-agent` |
| Backend | Supabase (Postgres + Auth + Edge Functions) | `backend-agent` |
| Content | JSON seed files → Supabase migration | `content-agent` |

## Key Technical Decisions

- **Screen takeover on macOS**: Uses [ChimeAlert](https://github.com/uxderrick/ChimeAlert) — a Swift Package that draws NSWindow overlays. macOS app must be native Swift, not Electron.
- **Screen takeover on iOS**: Full-screen modal launched from notification tap. Apple prevents true background takeover.
- **Screen takeover on Android**: Full-screen notification intent via `expo-notifications` + foreground service.
- **Backend**: Supabase (project: `swhjihogjiwdhxiondag`) — handles auth, Postgres DB, real-time sync.
- **Auth**: Google OAuth (native Sign-In, not web flow) + Magic Link email. Apple Sign-In deferred — no Apple Developer account yet.
- **Content**: Pre-built, curated database. Prayers are authored and seeded. Not AI-generated.
- **Bible translations**: NIV, KJV, ESV, NLT, MSG (The Message). Each scripture stored per-translation.
- **Bare workflow**: Expo bare workflow (not managed) to allow custom native modules for Android overlay.

## Directory Structure

```
Our Daily Prayer/           ← repo root (folder name kept as-is)
├── CLAUDE.md               ← you are here
├── docs/
│   ├── ARCHITECTURE.md     ← system design, data flow, auth flow
│   ├── BACKEND.md          ← Supabase schema, RLS, edge functions
│   ├── MACOS_APP.md        ← Swift app, ChimeAlert integration
│   ├── MOBILE_APP.md       ← Expo app, notifications, screen takeover
│   ├── CONTENT.md          ← prayer DB structure, seeding strategy
│   ├── DESIGN_SYSTEM.md    ← colors, typography, shared UI language
│   └── AGENTS.md           ← agent responsibilities and contracts
├── apps/
│   ├── macos/              ← Swift/SwiftUI macOS app (bundle: com.hallowed.macos)
│   ├── mobile/             ← Expo React Native iOS + Android (bundle: com.hallowed.app)
│   └── backend/            ← Supabase config, migrations, functions
└── shared/
    └── content/            ← seed JSON for prayers, themes, scriptures
```

## Living Documents

All files in `docs/` are living documents. The responsible agent **must update its doc** after every meaningful implementation milestone. See [docs/AGENTS.md](docs/AGENTS.md) for update protocol.

## Core Features (MVP)

1. **Prayer Periods** — user sets recurring time blocks (e.g. 6 AM, 30 min)
2. **Theme/Topic Library** — curated categories with sub-topics
3. **Randomizer** — picks a theme/topic for the session
4. **Prayer + Scripture Display** — full-screen prayer text with scripture
5. **Screen Takeover** — locks screen until prayer period ends (macOS best-in-class, mobile graceful degradation)
6. **Cross-device Sync** — via Supabase, tied to user account
7. **Prayer History** — log of completed sessions

## Post-MVP Ideas (do not build yet)

- Streak tracking and gamification
- Community/shared prayer topics
- AI-generated prayer suggestions
- Apple Watch / widget support
- Push notifications from server (vs local-only)
- Apple Sign-In (when Apple Developer account is available)
