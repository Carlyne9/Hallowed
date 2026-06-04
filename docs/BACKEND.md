# Backend

> Last updated: 2026-05-12 — all migrations pushed to production
> Responsible agent: `backend-agent`
> Platform: Supabase (Postgres 15, Auth, Edge Functions, Realtime)
> Location: `apps/backend/`

## Setup

### Prerequisites
- Supabase CLI: `brew install supabase/tap/supabase`
- Node 18+ (for edge functions)

### Local Dev
```bash
cd apps/backend
supabase start          # spins up local Postgres + Auth + Studio
supabase db reset       # re-runs all migrations from scratch
supabase functions serve # runs edge functions locally
```

### Deploy
```bash
supabase db push        # pushes migrations to remote project
supabase functions deploy
```

---

## Database Schema

### `profiles`
Extends `auth.users`. Created automatically on sign-up via trigger.

```sql
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url   text,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
```

### `prayer_themes`
Top-level prayer categories. Seeded, read-only for users.

```sql
create table public.prayer_themes (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,          -- e.g. "Thanksgiving"
  description text,
  icon        text,                          -- SF Symbol name
  color_hex   text,                          -- brand color for theme
  sort_order  int default 0,
  created_at  timestamptz default now()
);
```

### `prayer_topics`
Sub-topics within a theme. Seeded, read-only for users.

```sql
create table public.prayer_topics (
  id          uuid primary key default gen_random_uuid(),
  theme_id    uuid not null references public.prayer_themes(id),
  title       text not null,
  description text,
  tags        text[],
  sort_order  int default 0,
  created_at  timestamptz default now()
);
```

### `prayers`
The prayer body text, linked to a topic.

```sql
create table public.prayers (
  id         uuid primary key default gen_random_uuid(),
  topic_id   uuid not null references public.prayer_topics(id),
  title      text not null,
  body       text not null,               -- the prayer text
  author     text,                        -- optional attribution
  is_classic boolean default false,       -- marks well-known traditional prayers
  created_at timestamptz default now()
);
```

### `scriptures`
Scripture verse references. Text is **not stored** — fetched at runtime via [api.bible](https://scripture.api.bible) and cached on device. This avoids licensing issues with NIV, ESV, NLT, MSG.

```sql
create table public.scriptures (
  id          uuid primary key default gen_random_uuid(),
  book        text not null,      -- display name e.g. "Psalms"
  book_code   text not null,      -- api.bible code e.g. "PSA"
  chapter     int not null,
  verse_start int not null,
  verse_end   int,                -- null if single verse
  reference   text not null,     -- display string e.g. "Psalm 23:1-3"
  created_at  timestamptz default now(),
  unique (book_code, chapter, verse_start, verse_end)
);
```

**api.bible Translation IDs** (used by client apps to fetch verse text):
| Translation | api.bible Bible ID |
|-------------|-------------------|
| NIV | `78a9f6124f344018-01` |
| KJV | `de4e12af7f28f599-02` |
| ESV | `f421fe261da7624f-01` |
| NLT | `65eec8e0b60e656b-01` |
| MSG | `65eec8e0b60e656b-02` |

> Verify these IDs at https://scripture.api.bible before going live — they can change.

### `prayer_scripture_links`
Many-to-many: prayers ↔ scriptures.

```sql
create table public.prayer_scripture_links (
  prayer_id    uuid not null references public.prayers(id) on delete cascade,
  scripture_id uuid not null references public.scriptures(id) on delete cascade,
  primary key (prayer_id, scripture_id)
);
```

### `prayer_periods`
User-defined prayer schedule. Periods can be one-time on a specific date, recurring, theme-focused, custom-topic-focused, or open prayer without assigned prayer points.

```sql
create type public.repeat_type as enum ('daily', 'weekdays', 'weekends', 'custom');

create table public.prayer_periods (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  label         text,                           -- e.g. "Morning Prayer"
  scheduled_date date,                          -- one-time prayer date; null means recurring
  time_of_day   time not null,                  -- e.g. 06:00:00
  duration_mins int not null default 15,
  repeat        public.repeat_type default 'daily',
  custom_days   int[],                          -- 0=Sun … 6=Sat, used when repeat='custom'
  theme_id      uuid references public.prayer_themes(id) on delete set null,
  custom_topics text[],
  is_active     boolean default true,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);
```

Migration `20260604000008_extend_prayer_periods.sql` adds the nullable `scheduled_date`, `theme_id`, and `custom_topics` columns to existing deployments.

### `prayer_sessions`
Log of every prayer session (completed or skipped).

```sql
create type public.session_status as enum ('completed', 'skipped', 'partial');

create table public.prayer_sessions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  period_id    uuid references public.prayer_periods(id) on delete set null,
  prayer_id    uuid references public.prayers(id) on delete set null,
  topic_id     uuid references public.prayer_topics(id) on delete set null,
  started_at   timestamptz not null,
  ended_at     timestamptz,
  duration_s   int,                             -- actual seconds prayed
  status       public.session_status default 'completed',
  notes        text,
  created_at   timestamptz default now()
);
```

### `user_topic_preferences`
Lets users pin or hide topics from the randomizer.

```sql
create type public.topic_pref as enum ('pinned', 'hidden');

create table public.user_topic_preferences (
  user_id  uuid not null references auth.users(id) on delete cascade,
  topic_id uuid not null references public.prayer_topics(id) on delete cascade,
  pref     public.topic_pref not null,
  primary key (user_id, topic_id)
);
```

---

## Row Level Security (RLS)

All tables have RLS enabled. Policies below.

### Content tables (read-only for authenticated users)
Applies to: `prayer_themes`, `prayer_topics`, `prayers`, `scriptures`, `prayer_scripture_links`

```sql
-- Enable RLS
alter table public.prayer_themes enable row level security;
-- (repeat for each content table)

-- Allow any authenticated user to read
create policy "Authenticated users can read themes"
  on public.prayer_themes for select
  to authenticated
  using (true);
```

### User-owned tables
Applies to: `profiles`, `prayer_periods`, `prayer_sessions`, `user_topic_preferences`

```sql
-- profiles
create policy "Users manage own profile"
  on public.profiles for all
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- prayer_periods
create policy "Users manage own periods"
  on public.prayer_periods for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- prayer_sessions
create policy "Users manage own sessions"
  on public.prayer_sessions for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- user_topic_preferences
create policy "Users manage own topic prefs"
  on public.user_topic_preferences for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
```

---

## Triggers

### Auto-create profile on sign-up
```sql
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

### Auto-update `updated_at`
```sql
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

create trigger set_periods_updated_at
  before update on public.prayer_periods
  for each row execute procedure public.set_updated_at();
```

---

## Edge Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `get-daily-prayer` | HTTP GET | Returns a randomized prayer + scriptures for a given topic |
| `sync-periods` | HTTP POST | Validates and upserts prayer periods from a device |

> Edge function source lives in `apps/backend/supabase/functions/`

---

## Auth Configuration

### Providers to enable in Supabase dashboard
- **Sign in with Apple** — requires Apple Developer account, Service ID, key file
- **Google OAuth** — requires Google Cloud project, OAuth 2.0 client ID

### Redirect URLs
```
# Mobile deep link
myapp://auth/callback

# macOS deep link
myapp://auth/callback
```

---

## Indexes

```sql
create index on public.prayer_periods (user_id, is_active);
create index on public.prayer_sessions (user_id, started_at desc);
create index on public.prayers (topic_id);
create index on public.prayer_topics (theme_id);
create index on public.scriptures (book, chapter, translation);
```

---

## Migration Files

All migrations live in `apps/backend/supabase/migrations/`. Naming convention:
```
YYYYMMDDHHMMSS_description.sql
```

## Status

- [x] Supabase project created — `swhjihogjiwdhxiondag`
- [ ] Local dev environment working (`supabase start`)
- [x] Initial migrations written and pushed (2026-05-12)
- [x] RLS policies live
- [x] Auth providers configured — Google OAuth live (2026-05-19), Apple deferred (no dev account yet)
  - Web client ID: configured in Supabase (verifies all native tokens)
  - iOS client ID: saved, used for native SDK init on mobile
  - macOS client ID: saved, used for native SDK init on macOS
  - Deep links registered: `com.hallowed.app://auth/callback`, `com.hallowed.macos://auth/callback`
- [ ] Edge functions scaffolded
- [ ] Content seed data applied (see [CONTENT.md](CONTENT.md))
- [x] Deployed to production
