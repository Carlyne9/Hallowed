# macOS App

> Last updated: 2026-05-25 — error UI, history titles, strict mode, scripture strategy docs
> Responsible agent: `macos-agent`
> Platform: macOS 14.0 (Sonoma)+
> Tech: Swift 5.9+, SwiftUI, Supabase Swift SDK
> Location: `apps/macos/`

## Setup

### Prerequisites
- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+

### Build & Run
```bash
cd apps/macos
open Hallowed.xcodeproj
# Build target: Hallowed (macOS)
```

To regenerate the Xcode project after editing `project.yml`:
```bash
cd apps/macos
~/homebrew/bin/xcodegen generate
```

### Dependencies (Swift Package Manager)
| Package | Version | Purpose |
|---------|---------|---------|
| [supabase-swift](https://github.com/supabase/supabase-swift) | 2.0.0+ | Auth + DB client |

Deferred (post-MVP):
- **ChimeAlert** — full-screen NSWindow takeover (custom `ScreenOverlayManager` stub used for now)
- **GRDB.swift** — local SQLite cache (direct Supabase fetch for MVP)
- **KeychainAccess** — explicit Keychain wrapper (Supabase SDK handles tokens internally)

---

## Project Structure

```
apps/macos/
├── project.yml                       ← XcodeGen spec
├── Secrets.xcconfig                  ← SUPABASE_URL, ANON_KEY, Google IDs (git-ignored)
├── Secrets.xcconfig.example          ← template for new devs
└── Hallowed/
    ├── HallowedApp.swift             ← @main, WindowGroup, Settings scene, URL handler
    ├── AppEnvironment.swift          ← ObservableObject, auth state, services
    ├── Config/
    │   ├── Secrets.swift             ← reads Info.plist keys from xcconfig
    │   └── Info.plist
    ├── Extensions/
    │   └── Color+Hex.swift           ← Color(hex: "RRGGBB") initializer
    ├── Models/
    │   ├── PrayerTheme.swift
    │   ├── PrayerTopic.swift
    │   ├── Prayer.swift              ← bullets computed from "\n"-joined body
    │   ├── Scripture.swift
    │   ├── PrayerPeriod.swift        ← RepeatType enum, displayTime computed
    │   └── PrayerSession.swift       ← static func new(...) builder
    ├── Services/
    │   ├── SupabaseService.swift     ← all auth + data fetches
    │   ├── NotificationScheduler.swift ← UNUserNotificationCenter per period
    │   ├── PrayerRandomizer.swift    ← random theme/topic/prayer selection
    │   └── ScreenOverlayManager.swift ← NSWindow .screenSaver overlay (stub for ChimeAlert)
    ├── Features/
    │   ├── Auth/
    │   │   └── AuthView.swift        ← Google + magic-link flows
    │   ├── Home/
    │   │   └── HomeView.swift        ← NavigationSplitView, dashboard, stat cards
    │   ├── Library/
    │   │   ├── ThemeListView.swift   ← 2-col lazy grid, hover animation
    │   │   └── TopicDetailView.swift ← nested split, PrayerCard with bullets + scriptures
    │   ├── PrayerPeriod/
    │   │   ├── PeriodListView.swift  ← list with toggle, swipe-to-delete
    │   │   └── PeriodEditorView.swift ← sheet with DatePicker, Stepper, repeat picker
    │   ├── PrayerSession/
    │   │   └── SessionView.swift     ← dark immersive layout, "Amen" action, session logging
    │   └── Settings/
    │       └── SettingsView.swift    ← account info, notification toggle, About
    └── Resources/
        ├── Assets.xcassets
        │   └── AppIcon.appiconset/   ← macOS icon sizes + Contents.json
        └── Hallowed.entitlements     ← sandbox: false, network.client: true
```

---

## Auth Flow

1. `HallowedApp` gates `WindowGroup` content on `AppEnvironment.isAuthenticated`
2. `AppEnvironment.startAuthListener()` iterates `client.auth.authStateChanges`
3. **Google OAuth**: `SupabaseService.signInWithGoogle()` opens browser via `signInWithOAuth(provider: .google, redirectTo: "com.hallowed.macos://auth/callback")`
4. macOS redirects back via URL scheme → `HallowedApp.onOpenURL` → `client.auth.handle(url:)`
5. **Magic Link**: `signInWithMagicLink(email:)` sends OTP email; user clicks link which also deep-links back

URL scheme registered: `com.hallowed.macos` (Info.plist `CFBundleURLTypes`)

---

## Screen Overlay (Prayer Session)

`ScreenOverlayManager` creates one borderless `NSWindow` per connected screen at `.screenSaver` window level. It hosts `SessionView` via `NSHostingView`. This is a functional stub — swap internals for ChimeAlert once its SPM URL is confirmed.

Trigger flow:
```
NotificationScheduler fires UNCalendarNotificationTrigger
  → foreground delivery or user taps notification
  → AppDelegate receives UNUserNotificationCenter delivery/response
  → AppEnvironment resolves periodId and picks random session content
  → ScreenOverlayManager.shared.show(prayer:topic:theme:)
  → NSWindow at .screenSaver covers all displays
  → "Amen" tap → dismiss() + logSession to Supabase
```

When **Start Prayer Automatically** is enabled, `AutomaticTakeoverScheduler` also tracks the next active prayer period while Hallowed is running and launches the same overlay flow directly. **Launch Hallowed at Login** uses `SMAppService.mainApp` to make that behavior available after a Mac login. System notifications remain scheduled as a fallback when Hallowed is quit, unavailable, asleep, or unable to load session content.

---

## Environment & Secrets

`Secrets.xcconfig` (git-ignored) holds `SUPABASE_URL`, `SUPABASE_ANON_KEY`, Google OAuth IDs, and optional `API_BIBLE_KEY`. See `Secrets.xcconfig.example`. If keys were ever exposed, follow [KEY_ROTATION.md](KEY_ROTATION.md).

Values are injected into `Info.plist` as build settings, then read at runtime via `Config.*` in `Secrets.swift`. Scripture fetching: [SCRIPTURE_STRATEGY.md](SCRIPTURE_STRATEGY.md).

---

## Status

- [x] XcodeGen `project.yml` created and project generated (`Hallowed.xcodeproj`)
- [x] `HallowedApp.swift` — `@main`, window gating, URL scheme handler
- [x] Notification delegate wired in app lifecycle (`UNUserNotificationCenterDelegate`)
- [x] `AppEnvironment.swift` — auth state, services, sign-out
- [x] `Config/Secrets.swift` — reads all secrets from `Info.plist`
- [x] `Color+Hex.swift` extension
- [x] All 6 models (PrayerTheme, PrayerTopic, Prayer, Scripture, PrayerPeriod, PrayerSession)
- [x] `SupabaseService.swift` — auth + all data fetch methods
- [x] `NotificationScheduler.swift` — permission request + period scheduling
- [x] `PrayerRandomizer.swift` — random topic/prayer selection
- [x] `ScreenOverlayManager.swift` — NSWindow overlay stub
- [x] `AuthView.swift` — Google + magic-link sign-in
- [x] `HomeView.swift` — sidebar navigation + dashboard
- [x] `ThemeListView.swift` — grid of theme cards
- [x] `TopicDetailView.swift` — topics + prayer cards with scripture pills
- [x] `PeriodListView.swift` — list with toggle + swipe-to-delete
- [x] `PeriodEditorView.swift` — add/edit sheet + custom day selection
- [x] Prayer periods support one-time dates, recurring schedules, theme focus, custom topics, or open prayer
- [x] `SessionView.swift` — dark immersive prayer session
- [x] `SettingsView.swift` — account, notifications, about
- [x] Scripture translation picker in Settings (NIV/KJV/ESV/NLT/MSG) saved to `profiles.preferred_translation`
- [x] App icon (AppIcon.appiconset — all macOS slots wired in Contents.json)
- [x] User-facing errors (Themes, topics, prayers, periods, auth callback, session start)
- [x] Scripture strategy documented; api.bible primary + bible-api.com fallback with translation param
- [x] History shows prayer + topic titles (batch fetch by session IDs)
- [x] Strict session mode (Settings → hides Skip, stronger overlay lock)
- [x] Session completion is idempotent across timer, actions, and multi-monitor overlays; scheduled sessions retain `period_id`
- [x] Active prayer periods rebuild local notifications after restored sessions/sign-in; sign-out clears pending prayer notifications
- [x] Notification takeover queues cold-launch responses until auth restores, supports recurring deliveries, and never replaces an active prayer session
- [x] Opt-in automatic takeover starts due prayer periods while Hallowed is running; Launch at Login improves availability and notifications remain as fallback
- [ ] ChimeAlert SPM dependency (swap ScreenOverlayManager internals)
- [x] Prayer history view (sidebar section + recent sessions list)
- [x] Notification tap → overlay flow wired via periodId payload
- [ ] Notarization + distribution — see [RELEASE_MACOS.md](RELEASE_MACOS.md)
- [ ] Rotate exposed API keys — see [KEY_ROTATION.md](KEY_ROTATION.md) (manual, in dashboards)
