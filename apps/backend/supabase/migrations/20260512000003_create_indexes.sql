-- Performance indexes

create index on public.prayer_periods (user_id, is_active);
create index on public.prayer_sessions (user_id, started_at desc);
create index on public.prayers (topic_id);
create index on public.prayer_topics (theme_id);
create index on public.scriptures (book, chapter, translation);
create index on public.user_topic_preferences (user_id);
