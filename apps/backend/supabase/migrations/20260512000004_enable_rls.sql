-- ── Enable RLS on every table ─────────────────────────────────────────────────
alter table public.profiles                enable row level security;
alter table public.prayer_themes           enable row level security;
alter table public.prayer_topics           enable row level security;
alter table public.prayers                 enable row level security;
alter table public.scriptures              enable row level security;
alter table public.prayer_scripture_links  enable row level security;
alter table public.prayer_periods          enable row level security;
alter table public.prayer_sessions         enable row level security;
alter table public.user_topic_preferences  enable row level security;

-- ── Content tables: any authenticated user can read ───────────────────────────
create policy "Authenticated read prayer_themes"
  on public.prayer_themes for select to authenticated using (true);

create policy "Authenticated read prayer_topics"
  on public.prayer_topics for select to authenticated using (true);

create policy "Authenticated read prayers"
  on public.prayers for select to authenticated using (true);

create policy "Authenticated read scriptures"
  on public.scriptures for select to authenticated using (true);

create policy "Authenticated read prayer_scripture_links"
  on public.prayer_scripture_links for select to authenticated using (true);

-- ── User-owned tables: full access scoped to own rows ─────────────────────────
create policy "Users manage own profile"
  on public.profiles for all to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "Users manage own prayer_periods"
  on public.prayer_periods for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Users manage own prayer_sessions"
  on public.prayer_sessions for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Users manage own topic_preferences"
  on public.user_topic_preferences for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
