# Rotating exposed credentials

These keys were referenced in local config and docs. **Rotation must be done in each provider's dashboard** — the app cannot rotate them for you.

## Status

| Secret | In git history? | Action |
|--------|-----------------|--------|
| Supabase anon key | Partial refs in `docs/MACOS_APP.md` (redacted) | Rotate in [Supabase Dashboard](https://supabase.com/dashboard) → Project Settings → API → regenerate **anon** key |
| Google OAuth client IDs | In local `.env` / `Secrets.xcconfig` (git-ignored) | [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials → create new OAuth clients or reset secrets |
| api.bible key (optional) | Only if committed | [api.bible](https://scripture.api.bible) → regenerate API key |

`apps/macos/Secrets.xcconfig` is **git-ignored** and was not included in commit `c8b81f0` (only `project.pbxproj` changed). Still rotate if the anon key was ever pasted into chat, screenshots, or shared branches.

## After rotating

1. Update `apps/macos/Secrets.xcconfig` with new `SUPABASE_ANON_KEY` and Google IDs.
2. Update `apps/mobile/.env.local` and `apps/backend/.env` if you use them.
3. Rebuild macOS: `xcodebuild -scheme Hallowed -configuration Debug build`
4. Test Google sign-in and a Themes fetch.
5. If the old anon key was pushed to a **public** remote, consider `git filter-repo` or BFG to purge history (optional; anon keys are public-by-design but rotation limits abuse).

## Never commit

- `Secrets.xcconfig`
- `.env`, `.env.local`
- Full JWT strings in markdown (use `your-anon-key-here` placeholders only)
