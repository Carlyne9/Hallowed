-- ── User profiles ─────────────────────────────────────────────────────────────
-- Extends auth.users. One row per user, created automatically on sign-up.
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url   text,
  preferred_translation public.bible_translation default 'NIV',
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

-- ── Content: Prayer Themes ─────────────────────────────────────────────────────
-- Top-level categories (e.g. Thanksgiving, Intercession). Seeded, read-only.
create table public.prayer_themes (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  description text,
  icon        text,          -- SF Symbol name (e.g. "hands.sparkles")
  color_hex   text,          -- brand color for this theme (e.g. "#F59E0B")
  sort_order  int default 0,
  created_at  timestamptz default now()
);

-- ── Content: Prayer Topics ─────────────────────────────────────────────────────
-- Sub-topics within a theme (e.g. "Gratitude for Creation"). Seeded, read-only.
create table public.prayer_topics (
  id          uuid primary key default gen_random_uuid(),
  theme_id    uuid not null references public.prayer_themes(id) on delete cascade,
  title       text not null,
  description text,
  tags        text[],
  sort_order  int default 0,
  created_at  timestamptz default now()
);

-- ── Content: Prayers ──────────────────────────────────────────────────────────
-- The actual prayer body text, linked to a topic. Seeded, read-only.
create table public.prayers (
  id         uuid primary key default gen_random_uuid(),
  topic_id   uuid not null references public.prayer_topics(id) on delete cascade,
  title      text not null,
  body       text not null,
  author     text,
  is_classic boolean default false,
  created_at timestamptz default now()
);

-- ── Content: Scriptures ───────────────────────────────────────────────────────
-- One row per verse per translation. Seeded, read-only.
create table public.scriptures (
  id          uuid primary key default gen_random_uuid(),
  book        text not null,
  chapter     int not null,
  verse_start int not null,
  verse_end   int,
  translation public.bible_translation not null,
  text        text not null,
  reference   text not null,   -- e.g. "Psalm 19:1 (NIV)"
  created_at  timestamptz default now(),
  unique (book, chapter, verse_start, verse_end, translation)
);

-- ── Content: Prayer ↔ Scripture Links ─────────────────────────────────────────
create table public.prayer_scripture_links (
  prayer_id    uuid not null references public.prayers(id) on delete cascade,
  scripture_id uuid not null references public.scriptures(id) on delete cascade,
  primary key (prayer_id, scripture_id)
);

-- ── User: Prayer Periods ──────────────────────────────────────────────────────
-- Each user's scheduled prayer times (e.g. 6:00 AM, 30 min, daily).
create table public.prayer_periods (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  label         text,
  time_of_day   time not null,
  duration_mins int not null default 15,
  repeat        public.repeat_type default 'daily',
  custom_days   int[],         -- 0=Sun … 6=Sat, only used when repeat='custom'
  is_active     boolean default true,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- ── User: Prayer Sessions ─────────────────────────────────────────────────────
-- Log of every prayer session the user has started.
create table public.prayer_sessions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  period_id    uuid references public.prayer_periods(id) on delete set null,
  prayer_id    uuid references public.prayers(id) on delete set null,
  topic_id     uuid references public.prayer_topics(id) on delete set null,
  started_at   timestamptz not null,
  ended_at     timestamptz,
  duration_s   int,
  status       public.session_status default 'completed',
  notes        text,
  created_at   timestamptz default now()
);

-- ── User: Topic Preferences ───────────────────────────────────────────────────
-- Users can pin topics (weighted higher in randomizer) or hide them entirely.
create table public.user_topic_preferences (
  user_id  uuid not null references auth.users(id) on delete cascade,
  topic_id uuid not null references public.prayer_topics(id) on delete cascade,
  pref     public.topic_pref not null,
  primary key (user_id, topic_id)
);
