-- Extend prayer periods beyond simple recurring reminders.
-- Existing rows remain valid: scheduled_date/theme_id/custom_topics are nullable,
-- and repeat stays nullable so one-time periods do not need a recurrence.

alter table public.prayer_periods
  add column if not exists scheduled_date date,
  add column if not exists theme_id uuid references public.prayer_themes(id) on delete set null,
  add column if not exists custom_topics text[];

create index if not exists prayer_periods_user_scheduled_date_idx
  on public.prayer_periods (user_id, scheduled_date)
  where scheduled_date is not null;

create index if not exists prayer_periods_user_theme_idx
  on public.prayer_periods (user_id, theme_id)
  where theme_id is not null;
