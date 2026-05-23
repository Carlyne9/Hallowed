# Architecture

> Last updated: 2026-05-08 — initial scaffold
> Responsible agent: any agent should update this after cross-cutting changes

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Supabase Backend                          │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │   Auth   │  │  PostgreSQL  │  │     Edge Functions       │  │
│  │ (Apple/  │  │  (prayers,   │  │  (sync triggers, etc.)   │  │
│  │  Google) │  │  schedules,  │  │                          │  │
│  └──────────┘  │   history)   │  └──────────────────────────┘  │
│                └──────────────┘                                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │ HTTPS / Supabase JS / Swift client
              ┌─────────────┴──────────────┐
              │                            │
   ┌──────────▼──────────┐    ┌────────────▼───────────┐
   │    macOS App         │    │     Mobile App          │
   │  Swift + SwiftUI    │    │  Expo (React Native)    │
   │  ChimeAlert overlay │    │  iOS + Android          │
   │  Local notifications│    │  Local notifications    │
   │  NSWindow takeover  │    │  Full-screen modal      │
   └─────────────────────┘    └─────────────────────────┘
```

## Data Flow

### Prayer Period Trigger
```
User sets prayer period (e.g. 6:00 AM, 30 min)
    → Saved to Supabase (prayer_periods table)
    → Synced to all devices via Supabase realtime
    → Each device schedules a local notification for the period
    → At trigger time:
        macOS  → ChimeAlert NSWindow takeover
        iOS    → Full-screen modal (user must tap notification)
        Android → Full-screen intent, foreground service
    → Prayer session begins, timer counts down
    → On completion → prayer_sessions row inserted
```

### Content Loading
```
App opens
    → Check local cache (SQLite / AsyncStorage)
    → If stale or first launch → fetch from Supabase
    → Prayers + scriptures stored locally for offline use
    → Randomizer runs purely client-side against local cache
```

### Auth Flow
```
New user
    → Sign in with Apple or Google (OAuth via Supabase Auth)
    → JWT issued by Supabase
    → Profile row created in public.profiles
    → RLS policies scope all data to auth.uid()

Returning user (cross-device)
    → Sign in → JWT refreshed
    → prayer_periods, user preferences, prayer_sessions synced
    → Local notification schedules rebuilt from synced data
```

## Database — Table Summary

Full schema in [BACKEND.md](BACKEND.md).

| Table | Purpose |
|-------|---------|
| `profiles` | User preferences, display name |
| `prayer_periods` | Scheduled prayer times per user |
| `prayer_themes` | Top-level categories (e.g. Thanksgiving, Intercession) |
| `prayer_topics` | Sub-topics within a theme |
| `prayers` | Prayer text body, linked to a topic |
| `scriptures` | Scripture text, translation, reference |
| `prayer_scripture_links` | Many-to-many: prayers ↔ scriptures |
| `prayer_sessions` | Log of completed/skipped sessions |
| `user_topic_preferences` | User's pinned or hidden topics |

## Sync Strategy

- **Source of truth**: Supabase Postgres
- **Local cache**: SQLite (macOS via GRDB), AsyncStorage/SQLite (mobile via expo-sqlite)
- **Sync trigger**: App foreground resume + Supabase Realtime subscription on `prayer_periods`
- **Conflict resolution**: Last-write-wins on user-owned rows (prayer_periods, preferences). Content rows (prayers, scriptures) are read-only for users.
- **Offline support**: Core prayer session works fully offline. New periods created offline queue until connectivity restored.

## Notification Architecture

| Platform | Mechanism | Background capable? |
|----------|-----------|---------------------|
| macOS | `UNUserNotificationCenter` + ChimeAlert overlay | Yes — daemon keeps running |
| iOS | `expo-notifications` (UNUserNotificationCenter) | Notification only; app must open for full-screen |
| Android | `expo-notifications` + `USE_FULL_SCREEN_INTENT` permission | Yes — full-screen intent fires without app open |

## Security

- All Supabase tables have Row Level Security (RLS) enabled
- Users can only read/write their own rows
- Content tables (prayers, scriptures, themes, topics) are read-only for all authenticated users
- Service role key never exposed to client apps
- JWT validated server-side on every request
- See [BACKEND.md](BACKEND.md) for full RLS policies

## Environment Config

Each app needs these environment variables (never committed):

**macOS / Swift:**
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

**Mobile / Expo:**
```
EXPO_PUBLIC_SUPABASE_URL=
EXPO_PUBLIC_SUPABASE_ANON_KEY=
```

**Backend / Supabase CLI:**
```
SUPABASE_ACCESS_TOKEN=
SUPABASE_PROJECT_REF=
```
