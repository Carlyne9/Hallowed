# Agent Responsibilities & Coordination

> Last updated: 2026-05-08 — initial scaffold

## Agent Roster

| Agent | Owns | Primary doc |
|-------|------|-------------|
| `backend-agent` | `apps/backend/` — Supabase schema, migrations, RLS, edge functions | [BACKEND.md](BACKEND.md) |
| `macos-agent` | `apps/macos/` — Swift/SwiftUI app, ChimeAlert, GRDB, notifications | [MACOS_APP.md](MACOS_APP.md) |
| `mobile-agent` | `apps/mobile/` — Expo React Native, iOS + Android | [MOBILE_APP.md](MOBILE_APP.md) |
| `content-agent` | `shared/content/` — seed JSON, prayer authoring, scripture linking | [CONTENT.md](CONTENT.md) |

---

## Ground Rules for All Agents

1. **Update your doc** — after any meaningful implementation milestone, update the Status checklist in your primary doc and note the date at the top.
2. **Don't touch another agent's directory** without noting it here first.
3. **Shared models** (TypeScript types, Swift structs) must match the Supabase schema exactly. If you change the schema, notify the other agents by updating ARCHITECTURE.md and noting the breaking change below.
4. **Secrets are never committed** — use `.xcconfig` (macOS), `.env.local` (mobile), or environment variables (backend). See each platform doc for details.
5. **Feature flags**: if a feature is incomplete, gate it behind a `#if DEBUG` (Swift) or `__DEV__` (React Native) check — never ship broken UI.

---

## Shared Contracts

### Data Model Alignment

The canonical data model lives in Supabase (see [BACKEND.md](BACKEND.md)). Each platform maintains a local mirror:

| Entity | Supabase table | Swift model | TypeScript type |
|--------|---------------|-------------|-----------------|
| Theme | `prayer_themes` | `PrayerTheme.swift` | `PrayerTheme.ts` |
| Topic | `prayer_topics` | `PrayerTopic.swift` | `PrayerTopic.ts` |
| Prayer | `prayers` | `Prayer.swift` | `Prayer.ts` |
| Scripture | `scriptures` | `Scripture.swift` | `Scripture.ts` |
| Prayer Period | `prayer_periods` | `PrayerPeriod.swift` | `PrayerPeriod.ts` |
| Prayer Session | `prayer_sessions` | `PrayerSession.swift` | `PrayerSession.ts` |

**Rule**: if `backend-agent` changes a column name or type, it must update this table and both client agents must update their local models.

### API Surface (Supabase)

Client apps use the Supabase client directly (no custom REST API layer). Key operations:

| Operation | Table | Notes |
|-----------|-------|-------|
| Fetch themes + topics | `prayer_themes`, `prayer_topics` | Cached locally, rarely changes |
| Fetch prayers for topic | `prayers` + `prayer_scripture_links` | Cached locally |
| Fetch scriptures | `scriptures` | Cached, per translation |
| CRUD prayer periods | `prayer_periods` | User-owned, realtime sync |
| Insert prayer session | `prayer_sessions` | Write on session complete/skip |
| Update topic prefs | `user_topic_preferences` | Pin/hide topics |

### Notification Data Payload

When scheduling a local notification, both platforms use this payload shape:

```json
{
  "periodId": "uuid",
  "topicId": "uuid | null",
  "type": "prayer_period"
}
```

`topicId` may be null if randomization should happen at fire time rather than at schedule time.

---

## Breaking Change Log

> When a change in one platform requires action in another, log it here.

| Date | Changed by | Change | Action required |
|------|-----------|--------|----------------|
| — | — | — | — |

---

## Handoff Protocol

When one agent completes a piece of work that unblocks another:

1. Update your platform doc's Status checklist
2. Add an entry to the Breaking Change Log above if applicable
3. Note what the next agent needs to know in a comment at the top of the relevant file

---

## Build Order (Recommended)

The safest order to build this product:

```
1. backend-agent    → Supabase project, schema, migrations, RLS, seed data
2. content-agent    → Seed JSON files, apply seed to local Supabase
3. mobile-agent     → Expo project, auth, sync, core UI, notifications
4. macos-agent      → Swift project, auth, sync, core UI, ChimeAlert
5. All agents       → Polish, edge cases, testing
```

Agents 3 and 4 can work in parallel once steps 1–2 are complete.
