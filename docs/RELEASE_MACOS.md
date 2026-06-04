# macOS release checklist

## Done

- [x] App icon — all slots in `AppIcon.appiconset`
- [x] Hardened Runtime enabled in `project.yml` (`ENABLE_HARDENED_RUNTIME: YES`)
- [x] Full-screen session overlay (`ScreenOverlayManager`)

## Before distribution

### Code signing

1. Apple Developer account with **Developer ID Application** certificate.
2. In Xcode: target **Hallowed** → Signing & Capabilities → Team + **Developer ID** for Release archives (not only Apple Development).

### Archive & notarize

```bash
cd apps/macos
xcodebuild -scheme Hallowed -configuration Release archive \
  -archivePath build/Hallowed.xcarchive
xcodebuild -exportArchive \
  -archivePath build/Hallowed.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
xcrun notarytool submit build/export/Hallowed.app --wait --keychain-profile "AC_PASSWORD"
xcrun stapler staple build/export/Hallowed.app
```

Create `ExportOptions.plist` with `method: developer-id` and your team ID.

### QA (manual)

- [ ] Sign in: Google OAuth + magic link deep link
- [ ] Themes / topics / prayers load (RLS as authenticated user)
- [ ] Schedule period → notification fires → tap → overlay on **all monitors**
- [ ] Enable automatic takeover → due period opens overlay without a notification tap while Hallowed is running
- [ ] Enable Launch at Login → sign out/in to macOS → Hallowed launches and automatic takeover remains available
- [ ] Change macOS **Space** during overlay → windows reappear
- [ ] Disconnect/reconnect display → overlay rebuilds
- [ ] Strict mode (Settings) → Skip hidden, overlay stays on top
- [ ] History shows topic + prayer titles after sessions
- [ ] Settings: translation saves to `profiles.preferred_translation`

### Distribution options

- Direct download (notarized `.app` in DMG)
- Mac App Store (additional sandbox + review requirements — current entitlements use `com.apple.security.app-sandbox: false`)
