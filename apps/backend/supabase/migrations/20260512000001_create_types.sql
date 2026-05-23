-- Enum types used across the schema

create type public.bible_translation as enum ('NIV', 'KJV', 'ESV', 'NLT', 'MSG');

create type public.repeat_type as enum ('daily', 'weekdays', 'weekends', 'custom');

create type public.session_status as enum ('completed', 'skipped', 'partial');

create type public.topic_pref as enum ('pinned', 'hidden');
