-- Scriptures table: switch from storing full verse text to API.Bible references.
-- Verse text is now fetched at runtime via api.bible and cached on device.
-- This removes the need for per-translation rows and any licensing concerns.

-- Drop old unique constraint (included translation)
alter table public.scriptures
  drop constraint if exists scriptures_book_chapter_verse_start_verse_end_translation_key;

-- Remove columns no longer needed
alter table public.scriptures drop column if exists text;
alter table public.scriptures drop column if exists translation;

-- Add book_code: api.bible standard book identifier (e.g. "PSA", "MAT", "JHN")
alter table public.scriptures add column if not exists book_code text not null default '';

-- Clean up the temporary default now that column exists
alter table public.scriptures alter column book_code drop default;

-- New unique constraint: one row per verse range, regardless of translation
alter table public.scriptures
  add constraint scriptures_unique_ref
  unique (book_code, chapter, verse_start, verse_end);

-- bible_translation enum is still used on profiles.preferred_translation
-- so we leave it in place — just no longer used on this table.
