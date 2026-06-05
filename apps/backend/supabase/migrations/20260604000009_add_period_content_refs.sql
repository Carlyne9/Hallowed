-- Allow scheduled prayer periods to reopen the exact topic/prayer selected.
-- Nullable columns preserve existing open, theme-only, and custom-topic periods.

alter table public.prayer_periods
  add column if not exists topic_id uuid references public.prayer_topics(id) on delete set null,
  add column if not exists prayer_id uuid references public.prayers(id) on delete set null;

create index if not exists prayer_periods_user_topic_idx
  on public.prayer_periods (user_id, topic_id)
  where topic_id is not null;

create index if not exists prayer_periods_user_prayer_idx
  on public.prayer_periods (user_id, prayer_id)
  where prayer_id is not null;
