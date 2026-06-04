# Scripture text strategy

> Decided: 2026-05-25

## Canonical approach

1. **Store references only** in Postgres (`scriptures` table: book, chapter, verses, `passage_id` for api.bible).
2. **Fetch verse text at runtime** on the client using the user's `profiles.preferred_translation`.
3. **Primary provider: [api.bible](https://scripture.api.bible)** when `API_BIBLE_KEY` is set in `Secrets.xcconfig` (supports NIV, KJV, ESV, NLT, MSG).
4. **Fallback: [bible-api.com](https://bible-api.com)** only when api.bible is unavailable (no key, HTTP error, or unsupported translation). Fallback uses the same translation query param when possible; otherwise KJV-style defaults.

## Why not one provider only?

- api.bible requires a key and supports licensed translations (matches product settings).
- bible-api.com is unauthenticated and useful for local dev or when the key is missing — but it does not replace api.bible for production translation choice.

## Client implementation

- macOS: `BibleService.swift` + `SessionView` / library cards
- Mobile (planned): mirror the same two-tier logic

## Operational requirement

Production macOS builds should set `API_BIBLE_KEY` so users get their chosen translation. Without it, verses may load from the fallback with reduced translation fidelity.
