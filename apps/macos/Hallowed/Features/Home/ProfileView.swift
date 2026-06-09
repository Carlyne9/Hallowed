import SwiftUI
import CryptoKit
import UserNotifications
import ServiceManagement

struct ProfileView: View {
    let periods: [PrayerPeriod]

    @EnvironmentObject private var appEnv: AppEnvironment
    @State private var sessions: [PrayerSession] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var notificationsEnabled: Bool = false
    @State private var isRequestingPermission: Bool = false
    @State private var isSigningOut: Bool = false
    @State private var selectedTranslation: String = "NIV"
    @State private var isLoadingTranslation: Bool = true
    @State private var isSavingTranslation: Bool = false
    @State private var strictSessionMode: Bool = SessionPreferences.isStrictModeEnabled
    @State private var automaticTakeoverEnabled: Bool = AutomaticTakeoverPreferences.isEnabled
    @State private var launchAtLoginEnabled: Bool = false
    @State private var loginItemMessage: String?
    @State private var isUpdatingLoginItem: Bool = false

    private let translationOptions = ["NIV", "KJV", "ESV", "NLT", "MSG"]

    private var displayName: String {
        appEnv.currentUser?.userMetadata["full_name"]?.stringValue
            ?? appEnv.currentUser?.email
            ?? "Hallowed User"
    }

    private var email: String {
        appEnv.currentUser?.email ?? "Signed in"
    }

    private var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    private var lastName: String {
        let parts = displayName.split(separator: " ")
        guard parts.count > 1 else { return "-" }
        return parts.dropFirst().joined(separator: " ")
    }

    private var initials: String {
        let parts = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        let value = String(parts).uppercased()
        return value.isEmpty ? "H" : value
    }

    private var naviiAvatarURL: URL? {
        guard let seed = naviiSeed else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.navii.dev"
        components.path = "/avatar/\(seed).png"
        components.queryItems = [
            URLQueryItem(name: "size", value: "256"),
            URLQueryItem(name: "background", value: "ring"),
            URLQueryItem(name: "mood", value: "happy")
        ]
        return components.url
    }

    private var naviiSeed: String? {
        if let userId = appEnv.currentUser?.id {
            return userId.uuidString.lowercased()
        }

        if let email = appEnv.currentUser?.email {
            return Self.sha256Hex(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        }

        let fallback = displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return fallback.isEmpty ? nil : Self.sha256Hex(fallback)
    }

    private var stats: AchievementStats {
        AchievementStats(sessions: sessions, periods: periods)
    }

    private var badges: [AchievementBadge] {
        AchievementBadge.allBadges(stats: stats)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 26) {
                    profileDetailsCard
                    achievementsCard
                    settingsControls
                    signOutBlock

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical, 36)

                Spacer(minLength: 0)
            }
        }
        .background {
            HallowedExperimentalBackground()
        }
        .navigationTitle("Profile")
        .task {
            await loadProfileData()
        }
    }

    private var profileDetailsCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 18) {
                naviiAvatar(size: 84, cornerRadius: 42)

                Text(displayName)
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundColor(HallowedDesign.Experimental.text)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 22) {
                profileInfoRow("First name", value: firstName)
                profileInfoRow("Last name", value: lastName)
                profileInfoRow("Email address", value: email)
            }
        }
        .profileCard()
    }

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Achievements")
            achievementBadgeStrip
        }
        .profileCard()
    }

    private var achievementBadgeStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(badges) { badge in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottomTrailing) {
                            Text(badge.shortCode)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(badge.isUnlocked ? HallowedDesign.Experimental.text : HallowedDesign.Experimental.faint)
                                .frame(width: 76, height: 76)
                                .background(badge.isUnlocked ? HallowedDesign.Experimental.glassStrong : HallowedDesign.Experimental.glass)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(badge.isUnlocked ? HallowedDesign.Experimental.amber.opacity(0.7) : HallowedDesign.Experimental.line, lineWidth: 1.5)
                                )

                            if badge.isUnlocked {
                                Text(badgeCountLabel(for: badge))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(HallowedDesign.Experimental.amber)
                                    .clipShape(Capsule())
                                    .offset(x: 3, y: 3)
                            }
                        }

                        Text(badge.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(badge.isUnlocked ? HallowedDesign.Experimental.text : HallowedDesign.Experimental.faint)
                            .lineLimit(1)
                            .frame(width: 88)
                    }
                }
            }
            .padding(.bottom, 2)
        }
    }

    private var settingsControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Settings")

            ProfileSettingsSection(title: "Notifications", icon: "bell.fill") {
                ProfileSettingsRow(label: "Enable Notifications", icon: "bell") {
                    Toggle("", isOn: $notificationsEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .disabled(isRequestingPermission)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled {
                                requestNotificationPermission()
                            }
                        }
                }
            }

            ProfileSettingsSection(title: "Automatic Takeover", icon: "sparkles.rectangle.stack.fill") {
                VStack(alignment: .leading, spacing: 0) {
                    ProfileSettingsRow(label: "Start Prayer Automatically", icon: "rectangle.inset.filled.and.person.filled") {
                        Toggle("", isOn: $automaticTakeoverEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: automaticTakeoverEnabled) { _, enabled in
                                setAutomaticTakeover(enabled)
                            }
                    }
                    Divider().padding(.leading, 16)
                    ProfileSettingsRow(label: "Launch Hallowed at Login", icon: "power") {
                        Toggle("", isOn: $launchAtLoginEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: launchAtLoginEnabled) { _, enabled in
                                if !isUpdatingLoginItem {
                                    setLaunchAtLogin(enabled)
                                }
                            }
                    }
                    Divider().padding(.leading, 16)
                    Text(loginItemMessage ?? "When Hallowed is running, active prayer periods can begin without requiring a notification tap.")
                        .font(.system(size: 12))
                        .foregroundColor(HallowedDesign.Experimental.muted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
            }

            ProfileSettingsSection(title: "Scripture", icon: "book.closed.fill") {
                VStack(alignment: .leading, spacing: 0) {
                    ProfileSettingsRow(label: "Translation", icon: "text.book.closed") {
                        if isLoadingTranslation {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Picker("Translation", selection: $selectedTranslation) {
                                ForEach(translationOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 110)
                            .onChange(of: selectedTranslation) { _, newValue in
                                savePreferredTranslation(newValue)
                            }
                        }
                    }
                }
            }

            ProfileSettingsSection(title: "Prayer Session", icon: "lock.shield.fill") {
                VStack(alignment: .leading, spacing: 0) {
                    ProfileSettingsRow(label: "Strict mode", icon: "lock.fill") {
                        Toggle("", isOn: $strictSessionMode)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: strictSessionMode) { _, enabled in
                                SessionPreferences.isStrictModeEnabled = enabled
                            }
                    }
                    Divider().padding(.leading, 16)
                    Text("Hides Skip, keeps the overlay on top, and discourages switching away during a session.")
                        .font(.system(size: 12))
                        .foregroundColor(HallowedDesign.Experimental.muted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
            }

            ProfileSettingsSection(title: "About", icon: "info.circle.fill") {
                VStack(alignment: .leading, spacing: 0) {
                    ProfileSettingsRow(label: "App", icon: "hands.and.sparkles.fill") {
                        Text("Hallowed")
                            .font(.system(size: 13))
                            .foregroundColor(HallowedDesign.Experimental.text)
                    }
                    Divider().padding(.leading, 16)
                    ProfileSettingsRow(label: "Version", icon: "tag") {
                        Text("\(appVersion) (\(buildNumber))")
                            .font(.system(size: 13))
                            .foregroundColor(HallowedDesign.Experimental.muted)
                    }
                }
            }
        }
        .profileCard()
    }

    private var signOutBlock: some View {
        Button(action: signOut) {
            HStack(spacing: 12) {
                Text(isSigningOut ? "Signing Out..." : "Sign Out")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()
            }
            .foregroundColor(Color(red: 0.75, green: 0.2, blue: 0.2))
            .padding(18)
            .background(HallowedDesign.Experimental.glass)
            .clipShape(RoundedRectangle(cornerRadius: HallowedDesign.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: HallowedDesign.Radius.lg)
                    .stroke(Color(red: 0.75, green: 0.2, blue: 0.2).opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSigningOut)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 24, weight: .semibold, design: .serif))
            .foregroundColor(HallowedDesign.Experimental.text)
    }

    private func profileInfoRow(_ label: String, value: String, isMonospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HallowedDesign.Experimental.text)
            Text(value)
                .font(.system(size: 15, design: isMonospaced ? .monospaced : .default))
                .foregroundColor(HallowedDesign.Experimental.text)
                .textSelection(.enabled)
        }
    }

    private func naviiAvatar(size: CGFloat, cornerRadius: CGFloat) -> some View {
        AsyncImage(url: naviiAvatarURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .empty, .failure(_):
                initialsAvatar(size: size)
            @unknown default:
                initialsAvatar(size: size)
            }
        }
        .frame(width: size, height: size)
        .background(HallowedDesign.Experimental.glass)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(HallowedDesign.Experimental.lineStrong, lineWidth: 1)
        )
        .accessibilityLabel("Profile avatar")
    }

    private func initialsAvatar(size: CGFloat) -> some View {
        Text(initials)
            .font(.system(size: size * 0.36, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(HallowedDesign.Experimental.amber)
    }

    private func badgeCountLabel(for badge: AchievementBadge) -> String {
        switch badge.id {
        case "first-amen":
            return "x\(max(stats.completedCount, 1))"
        case "three-day-flame", "seven-day-rhythm":
            return "\(stats.bestCompletedDayStreak)d"
        case "perfect-day", "three-perfect-days":
            return "\(stats.perfectDayCount)"
        default:
            return "✓"
        }
    }

    private func loadProfileData() async {
        await loadSessions()
        await checkNotificationStatus()
        await loadPreferredTranslation()
        refreshLoginItemStatus()
    }

    private func signOut() {
        isSigningOut = true
        Task {
            appEnv.signOut()
            isSigningOut = false
        }
    }

    private func requestNotificationPermission() {
        isRequestingPermission = true
        Task {
            let granted = await appEnv.notificationScheduler.requestPermission()
            notificationsEnabled = granted
            isRequestingPermission = false
        }
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized
    }

    private func setAutomaticTakeover(_ enabled: Bool) {
        appEnv.setAutomaticTakeoverEnabled(enabled)
        guard enabled, !launchAtLoginEnabled else { return }

        isUpdatingLoginItem = true
        Task {
            do {
                try SMAppService.mainApp.register()
                refreshLoginItemStatus()
                loginItemMessage = "Automatic takeover is enabled and Hallowed will launch at login."
            } catch {
                refreshLoginItemStatus()
                loginItemMessage = "Automatic takeover works while Hallowed is open, but launch at login could not be enabled."
            }
            isUpdatingLoginItem = false
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        isUpdatingLoginItem = true
        Task {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try await SMAppService.mainApp.unregister()
                }
                refreshLoginItemStatus()
                loginItemMessage = nil
            } catch {
                refreshLoginItemStatus()
                loginItemMessage = enabled
                    ? "Launch at login could not be enabled."
                    : "Launch at login could not be disabled."
            }
            isUpdatingLoginItem = false
        }
    }

    private func refreshLoginItemStatus() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    private func loadPreferredTranslation() async {
        guard let userId = appEnv.currentUser?.id else {
            isLoadingTranslation = false
            return
        }
        let code = await appEnv.supabaseService.fetchPreferredTranslation(for: userId)
        selectedTranslation = translationOptions.contains(code) ? code : "NIV"
        isLoadingTranslation = false
    }

    private func savePreferredTranslation(_ code: String) {
        guard let userId = appEnv.currentUser?.id else { return }
        isSavingTranslation = true

        Task {
            do {
                try await appEnv.supabaseService.updatePreferredTranslation(code, for: userId)
                await MainActor.run {
                    isSavingTranslation = false
                }
            } catch {
                await MainActor.run {
                    isSavingTranslation = false
                }
            }
        }
    }

    private func loadSessions() async {
        isLoading = true
        errorMessage = nil
        do {
            sessions = try await appEnv.supabaseService.fetchRecentSessions(limit: 500)
        } catch {
            sessions = []
            errorMessage = "Could not load achievements: \(UserFacingError.message(for: error))"
        }
        isLoading = false
    }

    private static func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private struct ProfileSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.muted)
                .textCase(.uppercase)
                .tracking(1.1)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .background(HallowedDesign.Experimental.glass)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
            )
        }
    }
}

private extension View {
    func profileCard() -> some View {
        self
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial.opacity(0.82))
            .background(HallowedDesign.Experimental.glass)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
            )
    }
}

private struct ProfileSettingsRow<Trailing: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                leading
                Spacer()
                trailing
            }

            VStack(alignment: .leading, spacing: 8) {
                leading
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var leading: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(HallowedDesign.Experimental.text)
        }
    }
}
private struct AchievementStats {
    let completedCount: Int
    let bestCompletedDayStreak: Int
    let perfectDayCount: Int
    let bestPerfectDayStreak: Int
    let hasDurationFinish: Bool

    init(sessions: [PrayerSession], periods: [PrayerPeriod]) {
        let calendar = Calendar.current
        let completed = sessions.filter { $0.status == .completed }
        completedCount = completed.count

        let completedDays = Set(completed.map { calendar.startOfDay(for: $0.startedAt) })
        bestCompletedDayStreak = Self.bestStreak(in: completedDays)

        let activePeriods = periods.filter(\.isActive)
        let activePeriodIds = Set(activePeriods.map(\.id))
        let periodById = Dictionary(uniqueKeysWithValues: activePeriods.map { ($0.id, $0) })

        hasDurationFinish = completed.contains { session in
            guard let periodId = session.periodId,
                  let period = periodById[periodId],
                  let duration = session.durationS else {
                return false
            }
            return duration >= period.durationMins * 60
        }

        let candidateDays = Set(completed.map { calendar.startOfDay(for: $0.startedAt) })
        let perfectDays = candidateDays.filter { day in
            let expected = activePeriods
                .filter { $0.occurs(on: day, calendar: calendar) }
                .map(\.id)
            guard !expected.isEmpty else { return false }

            let completedForDay = completed.reduce(into: Set<UUID>()) { result, session in
                guard calendar.isDate(session.startedAt, inSameDayAs: day),
                      let periodId = session.periodId,
                      activePeriodIds.contains(periodId),
                      let period = periodById[periodId],
                      let duration = session.durationS,
                      duration >= period.durationMins * 60 else {
                    return
                }
                result.insert(periodId)
            }

            return Set(expected).isSubset(of: completedForDay)
        }

        perfectDayCount = perfectDays.count
        bestPerfectDayStreak = Self.bestStreak(in: Set(perfectDays))
    }

    private static func bestStreak(in days: Set<Date>) -> Int {
        guard !days.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sorted = days.sorted()
        var best = 1
        var current = 1

        for index in sorted.indices.dropFirst() {
            let previous = sorted[sorted.index(before: index)]
            let day = sorted[index]
            if calendar.dateComponents([.day], from: previous, to: day).day == 1 {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
        }

        return best
    }
}

private struct AchievementBadge: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool

    var shortCode: String {
        switch id {
        case "first-amen":
            return "AM"
        case "three-day-flame":
            return "3D"
        case "seven-day-rhythm":
            return "7D"
        case "full-duration":
            return "FD"
        case "perfect-day":
            return "PD"
        case "three-perfect-days":
            return "3P"
        default:
            return "HL"
        }
    }

    static func allBadges(stats: AchievementStats) -> [AchievementBadge] {
        [
            AchievementBadge(
                id: "first-amen",
                title: "First Amen",
                description: "Complete your first prayer session.",
                icon: "hands.sparkles.fill",
                isUnlocked: stats.completedCount > 0
            ),
            AchievementBadge(
                id: "three-day-flame",
                title: "Three-Day Flame",
                description: "Complete prayer on 3 days in a row.",
                icon: "flame.fill",
                isUnlocked: stats.bestCompletedDayStreak >= 3
            ),
            AchievementBadge(
                id: "seven-day-rhythm",
                title: "Seven-Day Rhythm",
                description: "Complete prayer on 7 days in a row.",
                icon: "calendar.badge.checkmark",
                isUnlocked: stats.bestCompletedDayStreak >= 7
            ),
            AchievementBadge(
                id: "full-duration",
                title: "Stayed The Course",
                description: "Finish a scheduled prayer for its full duration.",
                icon: "timer.circle.fill",
                isUnlocked: stats.hasDurationFinish
            ),
            AchievementBadge(
                id: "perfect-day",
                title: "Perfect Prayer Day",
                description: "Complete every scheduled prayer period in a day.",
                icon: "crown.fill",
                isUnlocked: stats.perfectDayCount > 0
            ),
            AchievementBadge(
                id: "three-perfect-days",
                title: "Faithful Flow",
                description: "Complete every scheduled period 3 days in a row.",
                icon: "sparkles.rectangle.stack.fill",
                isUnlocked: stats.bestPerfectDayStreak >= 3
            ),
        ]
    }
}

private struct AchievementBadgeCard: View {
    let badge: AchievementBadge

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(badge.shortCode)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(badge.isUnlocked ? HallowedDesign.Experimental.text : HallowedDesign.Experimental.faint)
                    .frame(width: 48, height: 48)
                    .background(badge.isUnlocked ? HallowedDesign.Experimental.glassStrong : HallowedDesign.Experimental.glass)
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                Spacer()

                Text(badge.isUnlocked ? "Unlocked" : "Locked")
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundColor(badge.isUnlocked ? HallowedDesign.Experimental.amber : HallowedDesign.Experimental.faint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HallowedDesign.Experimental.glass)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(badge.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(HallowedDesign.Experimental.text)
                Text(badge.description)
                    .font(.system(size: 12))
                    .foregroundColor(HallowedDesign.Experimental.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(.ultraThinMaterial.opacity(0.82))
        .background(HallowedDesign.Experimental.glass)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(badge.isUnlocked ? HallowedDesign.Experimental.amber.opacity(0.45) : HallowedDesign.Experimental.line, lineWidth: 1)
        )
        .opacity(badge.isUnlocked ? 1 : 0.72)
    }
}

private extension PrayerPeriod {
    func occurs(on day: Date, calendar: Calendar) -> Bool {
        if let scheduledDateValue {
            return calendar.isDate(scheduledDateValue, inSameDayAs: day)
        }

        let weekday = calendar.component(.weekday, from: day)
        let zeroBasedWeekday = weekday - 1

        switch repeatType {
        case .daily?:
            return true
        case .weekdays?:
            return (2...6).contains(weekday)
        case .weekends?:
            return weekday == 1 || weekday == 7
        case .custom?:
            return customDays?.contains(zeroBasedWeekday) == true
        case nil:
            return false
        }
    }
}

#Preview {
    ProfileView(periods: [])
        .environmentObject(AppEnvironment())
        .frame(width: 900, height: 700)
}
