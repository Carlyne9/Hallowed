# Mobile App (iOS + Android)

> Last updated: 2026-05-08 — initial scaffold
> Responsible agent: `mobile-agent`
> Platforms: iOS 16+, Android 10+ (API 29+)
> Tech: Expo (bare workflow), React Native, TypeScript, Supabase JS, expo-sqlite
> Location: `apps/mobile/`

## Setup

### Prerequisites
- Node 18+
- Expo CLI: `npm install -g expo-cli`
- For iOS: macOS + Xcode 15+
- For Android: Android Studio + SDK

### Install & Run
```bash
cd apps/mobile
npm install
npx expo run:ios      # iOS simulator
npx expo run:android  # Android emulator
```

> **Bare workflow** is required (not Expo Go managed) to support:
> - Custom native module for Android full-screen overlay
> - `USE_FULL_SCREEN_INTENT` permission on Android

---

## Project Structure

```
apps/mobile/
├── app.json                        ← Expo config
├── package.json
├── tsconfig.json
├── .env.local                      ← EXPO_PUBLIC_SUPABASE_URL, etc. (git-ignored)
├── app/                            ← Expo Router (file-based routing)
│   ├── _layout.tsx                 ← root layout, auth gate
│   ├── (auth)/
│   │   ├── sign-in.tsx
│   │   └── _layout.tsx
│   ├── (tabs)/
│   │   ├── _layout.tsx
│   │   ├── index.tsx               ← Home / today's prayer
│   │   ├── library.tsx             ← themes & topics browser
│   │   ├── schedule.tsx            ← prayer periods manager
│   │   └── history.tsx             ← past sessions
│   ├── prayer-session.tsx          ← full-screen modal (screen takeover)
│   └── settings.tsx
├── src/
│   ├── components/
│   │   ├── PrayerCard.tsx
│   │   ├── ScriptureBlock.tsx
│   │   ├── PeriodEditor.tsx
│   │   ├── ThemeGrid.tsx
│   │   └── CountdownTimer.tsx
│   ├── services/
│   │   ├── supabase.ts             ← Supabase client init
│   │   ├── database.ts             ← expo-sqlite local cache
│   │   ├── notifications.ts        ← expo-notifications scheduling
│   │   ├── randomizer.ts           ← topic randomizer logic
│   │   └── sync.ts                 ← remote ↔ local sync
│   ├── stores/
│   │   ├── authStore.ts            ← Zustand auth state
│   │   ├── prayerStore.ts          ← periods, sessions
│   │   └── contentStore.ts         ← themes, topics, prayers cache
│   ├── models/
│   │   ├── PrayerTheme.ts
│   │   ├── PrayerTopic.ts
│   │   ├── Prayer.ts
│   │   ├── Scripture.ts
│   │   ├── PrayerPeriod.ts
│   │   └── PrayerSession.ts
│   └── hooks/
│       ├── useAuth.ts
│       ├── usePrayerPeriods.ts
│       └── useRandomizer.ts
└── modules/
    └── full-screen-overlay/        ← custom native module (Android only)
        ├── android/
        └── index.ts
```

---

## Screen Takeover

### iOS
Apple restricts true background screen takeover. Best achievable UX:

1. Schedule local notification via `expo-notifications`
2. Notification arrives — user taps it
3. App launches directly into `prayer-session.tsx` as a full-screen modal
4. Modal uses `StatusBar hidden`, `navigationBarHidden`, `SafeAreaView`
5. Timer counts down; "Amen" button dismisses
6. If app is already in foreground → modal pushes automatically via notification listener

```typescript
// notifications.ts
Notifications.addNotificationResponseReceivedListener(response => {
  const { periodId } = response.notification.request.content.data;
  router.push({ pathname: '/prayer-session', params: { periodId } });
});
```

### Android
Full-screen intent fires even when device is locked/sleeping:

```json
// app.json — permissions
{
  "android": {
    "permissions": [
      "USE_FULL_SCREEN_INTENT",
      "FOREGROUND_SERVICE",
      "RECEIVE_BOOT_COMPLETED",
      "WAKE_LOCK"
    ]
  }
}
```

In `expo-notifications` config plugin, set `fullScreenIntent: true` for prayer notifications. Combined with the custom `full-screen-overlay` native module, this wakes the device and shows the prayer screen directly.

---

## Local Database (expo-sqlite)

Cache stored in `SQLite/prayer_cache.db`. Schema mirrors Supabase tables. Extra columns:
- `synced_at INTEGER` — Unix timestamp of last sync
- `dirty INTEGER` — 1 if unsaved local change

---

## State Management

**Zustand** for lightweight global state. Three stores:

| Store | Holds |
|-------|-------|
| `authStore` | session, user, sign-in/out actions |
| `prayerStore` | prayer periods, active session, history |
| `contentStore` | themes, topics, prayers (from local cache) |

---

## Navigation

**Expo Router** (file-based). Two route groups:
- `(auth)` — unauthenticated: sign-in screen
- `(tabs)` — authenticated: tab bar with Home, Library, Schedule, History

`prayer-session` route is a full-screen modal that covers the tab bar and status bar.

---

## Notifications

```typescript
// On app start / period sync
async function schedulePrayerPeriod(period: PrayerPeriod) {
  await Notifications.scheduleNotificationAsync({
    content: {
      title: period.label ?? "Time to Pray",
      body: "Your prayer period is starting now.",
      data: { periodId: period.id },
    },
    trigger: {
      type: 'calendar',
      hour: period.timeOfDay.hour,
      minute: period.timeOfDay.minute,
      repeats: true,
    },
  });
}
```

Re-scheduled on: app launch, period create/edit/delete, Supabase sync.

---

## Supabase JS Client

```typescript
// src/services/supabase.ts
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const supabase = createClient(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      storage: AsyncStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  }
);
```

---

## Key Packages

| Package | Purpose |
|---------|---------|
| `expo` (bare) | Core framework |
| `expo-router` | File-based navigation |
| `expo-notifications` | Local notification scheduling |
| `expo-sqlite` | Local SQLite cache |
| `@supabase/supabase-js` | Backend client |
| `@react-native-async-storage/async-storage` | Supabase session persistence |
| `zustand` | State management |
| `react-native-reanimated` | Smooth animations |
| `@expo/vector-icons` | Icons |

---

## Environment

Create `apps/mobile/.env.local` (git-ignored):
```
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

---

## Status

- [ ] Expo bare project initialized
- [ ] Expo Router configured
- [ ] Supabase client + auth (Apple, Google)
- [ ] Local expo-sqlite schema
- [ ] Sync service (remote ↔ local)
- [ ] Notification scheduling
- [ ] Android full-screen overlay native module
- [ ] Home tab (today's prayer, upcoming periods)
- [ ] Library tab (themes/topics)
- [ ] Schedule tab (prayer periods manager)
- [ ] History tab
- [ ] Prayer session full-screen modal
- [ ] Randomizer
- [ ] Settings screen
- [ ] App icons + splash screen
- [ ] EAS Build configured (iOS + Android)
- [ ] TestFlight + Play Store internal testing
