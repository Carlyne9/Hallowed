import SwiftUI
import CryptoKit
import UserNotifications
import ServiceManagement

struct HomeView: View {

    @EnvironmentObject var appEnv: AppEnvironment
    @AppStorage("hallowed.appearanceMode") private var appearanceMode = "system"

    @State private var themes: [PrayerTheme] = []
    @State private var periods: [PrayerPeriod] = []
    @State private var themesLoadError: String? = nil
    @State private var periodsLoadError: String? = nil
    @State private var selectedSection: SidebarSection? = .themes
    @State private var isLoadingSession: Bool = false
    @State private var sessionStartError: String? = nil
    @State private var isProfilePopoverPresented: Bool = false
    @State private var sessions: [PrayerSession] = []
    @State private var profileErrorMessage: String? = nil
    @State private var notificationsEnabled: Bool = false
    @State private var isRequestingPermission: Bool = false
    @State private var isSigningOut: Bool = false
    @State private var selectedTranslation: String = "NIV"
    @AppStorage("hallowed.language") private var selectedLanguage: String = "English"
    @State private var isLoadingTranslation: Bool = true
    @State private var isSavingTranslation: Bool = false
    @State private var strictSessionMode: Bool = SessionPreferences.isStrictModeEnabled
    @State private var automaticTakeoverEnabled: Bool = AutomaticTakeoverPreferences.isEnabled
    @State private var launchAtLoginEnabled: Bool = false
    @State private var loginItemMessage: String?
    @State private var isUpdatingLoginItem: Bool = false

    private let languageOptions = [
        "English", "French", "Spanish", "Portuguese", "Italian",
        "German", "Dutch", "Arabic", "Hebrew", "Swahili",
        "Yoruba", "Twi"
    ]
    private let translationOptions = ["NIV", "KJV", "ESV", "NLT", "NKJV", "NASB", "CSB", "AMP", "MSG", "WEB"]

    enum SidebarSection: String, Hashable, CaseIterable {
        case themes = "Themes"
        case periods = "Prayer Periods"
        case history = "History"

        var shortTitle: String {
            switch self {
            case .themes:    return "Themes"
            case .periods:   return "Periods"
            case .history:   return "History"
            }
        }

        var icon: String {
            switch self {
            case .themes:    return "books.vertical.fill"
            case .periods:   return "bell.badge.fill"
            case .history:   return "chart.bar.xaxis"
            }
        }

        var iconTint: Color {
            switch self {
            case .themes:    return Color(hex: "7FA6FF")
            case .periods:   return Color(hex: "F2B35D")
            case .history:   return Color(hex: "79D987")
            }
        }

        var iconBackground: Color {
            switch self {
            case .themes:    return Color(hex: "284169")
            case .periods:   return Color(hex: "5C3A1E")
            case .history:   return Color(hex: "1F4C31")
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .task {
            await loadData()
            await loadProfileData()
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Hallowed")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(HallowedDesign.Experimental.text)
                Circle()
                    .fill(HallowedDesign.Experimental.amber)
                    .frame(width: 6, height: 6)
                    .padding(.bottom, 2)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 26)
            .padding(.bottom, 22)

            Divider()
                .overlay(HallowedDesign.Experimental.line)
                .padding(.bottom, 8)

            VStack(spacing: 7) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    SidebarNavRow(
                        section: section,
                        isSelected: selectedSection == section
                    ) {
                        selectedSection = section
                    }
                    .tag(section)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Spacer()

            if let sessionStartError {
                Text(sessionStartError)
                    .font(.system(size: 11))
                    .foregroundColor(HallowedDesign.Experimental.rose)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            sidebarPrayNowButton
                .padding(.horizontal, HallowedDesign.Spacing.md)
                .padding(.top, HallowedDesign.Spacing.lg)
                .padding(.bottom, HallowedDesign.Spacing.sm)

            Divider()
                .overlay(HallowedDesign.Experimental.line)

            Button {
                isProfilePopoverPresented.toggle()
            } label: {
                HStack(spacing: 10) {
                    NaviiProfileAvatar(
                        url: naviiAvatarURL,
                        initials: initials,
                        size: 36,
                        cornerRadius: 18
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(HallowedDesign.Experimental.text)
                            .lineLimit(1)

                        Text(email)
                            .font(HallowedDesign.Typography.micro)
                            .foregroundColor(HallowedDesign.Experimental.muted)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(spacing: -2) {
                        Image(systemName: "chevron.up")
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(HallowedDesign.Experimental.faint)
                    .frame(width: 20, height: 24)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, HallowedDesign.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(HallowedDesign.Experimental.glass)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isProfilePopoverPresented, arrowEdge: .bottom) {
                profilePopover
                    .environmentObject(appEnv)
                    .frame(width: 620)
            }
            .help("Profile")
            .padding(.horizontal, HallowedDesign.Spacing.md)
            .padding(.top, HallowedDesign.Spacing.md)
            .padding(.bottom, HallowedDesign.Spacing.lg)
        }
        .background(HallowedDesign.Experimental.panel)
        .navigationSplitViewColumnWidth(
            min: HallowedDesign.Layout.sidebarMinWidth,
            ideal: HallowedDesign.Layout.sidebarIdealWidth,
            max: HallowedDesign.Layout.sidebarMaxWidth
        )
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        switch selectedSection {
        case .themes:
            ThemeListView(themes: themes, loadError: themesLoadError)
        case .periods:
            PeriodListView()
        case .history:
            HistoryView()
        case .none:
            dashboard
        }
    }

    private var sidebarPrayNowButton: some View {
        Button(action: startRandomSession) {
            HStack(spacing: 8) {
                if isLoadingSession {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                    Text("Pray Now")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: [HallowedDesign.Experimental.amber, Color(hex: "A15F26")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: HallowedDesign.Experimental.amber.opacity(0.18), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isLoadingSession)
        .help("Pray Now")
        .accessibilityLabel("Pray Now")
    }

    private var profilePopover: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 14) {
                    NaviiProfileAvatar(
                        url: naviiAvatarURL,
                        initials: initials,
                        size: 52,
                        cornerRadius: 26
                    )

                    Text(displayName)
                        .font(HallowedDesign.Typography.sectionTitle)
                        .foregroundColor(HallowedDesign.Experimental.text)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        isProfilePopoverPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(HallowedDesign.Experimental.muted)
                            .frame(width: 34, height: 34)
                            .background(HallowedDesign.Experimental.glass)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close profile settings")
                }

                ProfilePopoverCard(title: "Profile", icon: "person.circle.fill") {
                    VStack(alignment: .leading, spacing: 18) {
                        profileInfoRow("First name", value: firstName)
                        profileInfoRow("Last name", value: lastName)
                        profileInfoRow("Email address", value: email)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ProfilePopoverCard(title: "Achievements", icon: "sparkles") {
                    achievementBadgeStrip
                }

                ProfilePopoverCard(title: "Preferences", icon: "slider.horizontal.3") {
                    VStack(alignment: .leading, spacing: 0) {
                        PopoverSettingsRow(label: "Theme", icon: "circle.lefthalf.filled") {
                            themePreferencePicker
                        }

                        popoverDivider

                        PopoverSettingsRow(label: "Language", icon: "globe") {
                            Picker("Language", selection: $selectedLanguage) {
                                ForEach(languageOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .labelsHidden()
                            .controlSize(.large)
                            .padding(.vertical, 6)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(width: PopoverSettingsRowMetrics.dropdownLaneWidth, alignment: .trailing)
                        }

                        popoverDivider

                        PopoverSettingsRow(label: "Bible Version", icon: "book.closed") {
                            Picker("Bible Version", selection: $selectedTranslation) {
                                ForEach(translationOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .labelsHidden()
                            .controlSize(.large)
                            .padding(.vertical, 6)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(width: PopoverSettingsRowMetrics.dropdownLaneWidth, alignment: .trailing)
                            .disabled(isLoadingTranslation)
                            .onChange(of: selectedTranslation) { _, newValue in
                                savePreferredTranslation(newValue)
                            }
                        }
                    }
                }

                ProfilePopoverCard(title: "Prayer Settings", icon: "hands.sparkles.fill") {
                    VStack(alignment: .leading, spacing: 0) {
                        PopoverSettingsRow(label: "Enable Notifications", icon: "bell") {
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

                        popoverDivider

                        PopoverSettingsRow(label: "Start Prayer Automatically", icon: "rectangle.inset.filled.and.person.filled") {
                            Toggle("", isOn: $automaticTakeoverEnabled)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .onChange(of: automaticTakeoverEnabled) { _, enabled in
                                    setAutomaticTakeover(enabled)
                                }
                        }

                        popoverDivider

                        PopoverSettingsRow(label: "Launch Hallowed at Login", icon: "power") {
                            Toggle("", isOn: $launchAtLoginEnabled)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .onChange(of: launchAtLoginEnabled) { _, enabled in
                                    if !isUpdatingLoginItem {
                                        setLaunchAtLogin(enabled)
                                    }
                                }
                        }

                        popoverDivider

                        PopoverSettingsRow(label: "Strict mode", icon: "lock.fill") {
                            Toggle("", isOn: $strictSessionMode)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .onChange(of: strictSessionMode) { _, enabled in
                                    SessionPreferences.isStrictModeEnabled = enabled
                                }
                        }

                        Text(loginItemMessage ?? "Automatic takeover works while Hallowed is running. Notifications remain as a fallback.")
                            .font(.system(size: 12))
                            .foregroundColor(HallowedDesign.Experimental.muted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                }

                ProfilePopoverCard(title: "About", icon: "info.circle.fill") {
                    VStack(alignment: .leading, spacing: 0) {
                        PopoverSettingsRow(label: "App", icon: "hands.and.sparkles.fill") {
                            Text("Hallowed")
                                .font(.system(size: 13))
                                .foregroundColor(HallowedDesign.Experimental.text)
                        }
                        popoverDivider
                        PopoverSettingsRow(label: "Version", icon: "tag") {
                            Text("\(appVersion) (\(buildNumber))")
                                .font(.system(size: 13))
                                .foregroundColor(HallowedDesign.Experimental.muted)
                        }
                    }
                }

                if let profileErrorMessage {
                    Text(profileErrorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(HallowedDesign.Experimental.rose)
                }

                Button(action: signOut) {
                    HStack(spacing: 12) {
                        Text(isSigningOut ? "Signing Out..." : "Sign Out")
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()
                    }
                    .foregroundColor(HallowedDesign.Experimental.rose)
                    .padding(16)
                    .background(HallowedDesign.Experimental.rose.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: HallowedDesign.Radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: HallowedDesign.Radius.lg)
                            .stroke(HallowedDesign.Experimental.rose.opacity(0.24), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSigningOut)
            }
            .padding(HallowedDesign.Spacing.xxl)
        }
        .background(HallowedExperimentalBackground())
    }

    // MARK: - Dashboard

    private var dashboard: some View {
        ZStack {
            HallowedExperimentalBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 40) {

                    HallowedExperimentalCard(cornerRadius: 30, padding: 28) {
                        HStack(alignment: .center, spacing: 18) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                                    .font(HallowedDesign.Typography.label)
                                    .foregroundColor(HallowedDesign.Experimental.faint)
                                    .textCase(.uppercase)
                                Text("Good \(timeOfDayGreeting)")
                                    .font(.system(size: 38, weight: .semibold, design: .serif))
                                    .foregroundColor(HallowedDesign.Experimental.text)
                            }

                            Spacer()

                            Text("\(activePeriodCount) active")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(HallowedDesign.Experimental.amber)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(HallowedDesign.Experimental.glassStrong)
                                .clipShape(Capsule())
                        }
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) {
                            statCards
                        }
                        VStack(spacing: 16) {
                            statCards
                        }
                    }

                    if let themesLoadError {
                        Text("Theme load error: \(themesLoadError)")
                            .font(HallowedDesign.Typography.caption)
                            .foregroundColor(HallowedDesign.Experimental.rose)
                    }
                    if let periodsLoadError {
                        Text("Periods load error: \(periodsLoadError)")
                            .font(HallowedDesign.Typography.caption)
                            .foregroundColor(HallowedDesign.Experimental.rose)
                    }

                    HallowedExperimentalCard(cornerRadius: 26, padding: 24) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Scripture")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(HallowedDesign.Experimental.faint)
                                .textCase(.uppercase)
                                .tracking(0.8)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("\"Be still and know that I am God.\"")
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundColor(HallowedDesign.Experimental.text)
                                Text("- Psalm 46:10")
                                    .font(HallowedDesign.Typography.label)
                                    .foregroundColor(HallowedDesign.Experimental.muted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: startRandomSession) {
                        HStack(spacing: 10) {
                            if isLoadingSession {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Text("Start Random Prayer")
                                    .font(HallowedDesign.Typography.bodyStrong)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [HallowedDesign.Experimental.amber, Color(hex: "A15F26")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: HallowedDesign.Radius.md))
                        .shadow(color: HallowedDesign.Experimental.amber.opacity(0.24), radius: 18, x: 0, y: 10)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingSession)

                    Spacer()
                }
                .padding(32)
            }
        }
    }

    @ViewBuilder
    private var statCards: some View {
        StatCard(
            icon: "clock.fill",
            value: "\(activePeriodCount)",
            label: activePeriodCount == 1 ? "Active period" : "Active periods"
        )
        StatCard(
            icon: "books.vertical.fill",
            value: "\(themes.count)",
            label: themes.count == 1 ? "Prayer theme" : "Prayer themes"
        )
    }

    // MARK: - Helpers

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

    private var profileStats: ProfilePopoverAchievementStats {
        ProfilePopoverAchievementStats(sessions: sessions, periods: periods)
    }

    private var profileBadges: [ProfilePopoverAchievementBadge] {
        ProfilePopoverAchievementBadge.allBadges(stats: profileStats)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }

    private var achievementBadgeStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4),
            alignment: .leading,
            spacing: 16
        ) {
            ForEach(profileBadges) { badge in
                VStack(spacing: 6) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: badge.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(badge.isUnlocked ? HallowedDesign.Experimental.text : HallowedDesign.Experimental.faint)
                            .frame(width: 68, height: 68)
                            .background(badge.isUnlocked ? HallowedDesign.Experimental.glassStrong : HallowedDesign.Experimental.glass)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(badge.isUnlocked ? HallowedDesign.Experimental.lineStrong : HallowedDesign.Experimental.line, lineWidth: 1.5)
                            )

                        if badge.isUnlocked {
                            Text(badgeCountLabel(for: badge))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(HallowedDesign.Experimental.amber)
                                .clipShape(Capsule())
                                .offset(x: 3, y: 3)
                        }
                    }

                    Text(badge.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(HallowedDesign.Experimental.muted)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var popoverDivider: some View {
        Divider()
            .overlay(HallowedDesign.Experimental.line)
            .padding(.leading, 16)
    }

    private var themePreferencePicker: some View {
        HStack(spacing: 4) {
            themePreferenceButton(title: "Auto", systemImage: "circle.lefthalf.filled", value: "system")
            themePreferenceButton(title: "Light", systemImage: "sun.max", value: "light")
            themePreferenceButton(title: "Dark", systemImage: "moon", value: "dark")
        }
        .padding(4)
        .background(HallowedDesign.Experimental.glass)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
        )
        .frame(width: PopoverSettingsRowMetrics.trailingWidth)
    }

    private func themePreferenceButton(title: String, systemImage: String, value: String) -> some View {
        let isSelected = appearanceMode == value

        return Button {
            appearanceMode = value
        } label: {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : HallowedDesign.Experimental.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? HallowedDesign.Experimental.amber : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(title)
    }

    private func profileInfoRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(HallowedDesign.Experimental.text)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(HallowedDesign.Experimental.muted)
                .textSelection(.enabled)
        }
    }

    private func badgeCountLabel(for badge: ProfilePopoverAchievementBadge) -> String {
        switch badge.id {
        case "first-amen":
            return "x\(max(profileStats.completedCount, 1))"
        case "three-day-flame", "seven-day-rhythm":
            return "\(profileStats.bestCompletedDayStreak)d"
        case "perfect-day", "three-perfect-days":
            return "\(profileStats.perfectDayCount)"
        default:
            return "✓"
        }
    }

    private var activePeriodCount: Int {
        periods.filter(\.isActive).count
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Morning"
        case 12..<17: return "Afternoon"
        default:      return "Evening"
        }
    }

    private func loadData() async {
        themesLoadError = nil
        periodsLoadError = nil

        do {
            themes = try await appEnv.supabaseService.fetchThemes()
        } catch {
            themes = []
            themesLoadError = UserFacingError.message(for: error)
        }

        do {
            periods = try await appEnv.supabaseService.fetchPeriods()
        } catch {
            periods = []
            periodsLoadError = UserFacingError.message(for: error)
        }
    }

    private func loadProfileData() async {
        await loadSessions()
        await checkNotificationStatus()
        await loadPreferredTranslation()
        refreshLoginItemStatus()
    }

    private func loadSessions() async {
        profileErrorMessage = nil
        do {
            sessions = try await appEnv.supabaseService.fetchRecentSessions(limit: 500)
        } catch {
            sessions = []
            profileErrorMessage = "Could not load achievements: \(UserFacingError.message(for: error))"
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

    private func signOut() {
        isSigningOut = true
        Task {
            appEnv.signOut()
            isSigningOut = false
        }
    }

    private func startRandomSession() {
        guard !themes.isEmpty else {
            sessionStartError = "No themes loaded yet."
            return
        }
        isLoadingSession = true
        sessionStartError = nil
        Task {
            do {
                let theme = themes.randomElement()!
                let topics = try await appEnv.supabaseService.fetchTopics(for: theme.id)
                guard let topic = topics.randomElement() else {
                    sessionStartError = "No topics found for this theme."
                    isLoadingSession = false
                    return
                }
                let prayers = try await appEnv.supabaseService.fetchPrayers(for: topic.id)
                guard let prayer = prayers.randomElement() else {
                    sessionStartError = "No prayers found for this topic."
                    isLoadingSession = false
                    return
                }
                ScreenOverlayManager.shared.show(
                    prayer: prayer,
                    topic: topic,
                    theme: theme,
                    durationMinutes: 0,
                    appEnv: appEnv
                )
            } catch {
                sessionStartError = UserFacingError.message(for: error)
            }
            isLoadingSession = false
        }
    }

    private static func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Supporting Views

private struct SidebarNavRow: View {
    let section: HomeView.SidebarSection
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(section.iconBackground)

                    Image(systemName: section.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(section.iconTint)
                }
                .frame(width: 34, height: 34)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(isSelected ? 0.18 : 0.08), lineWidth: 1)
                )

                Text(section.shortTitle)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? HallowedDesign.Experimental.text : HallowedDesign.Experimental.muted)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? HallowedDesign.Experimental.lineStrong : Color.clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(section.rawValue)
    }

    private var rowBackground: Color {
        if isSelected {
            return HallowedDesign.Experimental.glassStrong
        }
        if isHovering {
            return HallowedDesign.Experimental.glass
        }
        return Color.clear
    }
}

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HallowedExperimentalCard(cornerRadius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(value)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(HallowedDesign.Experimental.text)
                Text(label)
                    .font(HallowedDesign.Typography.caption)
                    .foregroundColor(HallowedDesign.Experimental.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct NaviiProfileAvatar: View {
    let url: URL?
    let initials: String
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .empty, .failure(_):
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: size, height: size)
                    .background(HallowedDesign.Experimental.amber)
            @unknown default:
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: size, height: size)
                    .background(HallowedDesign.Experimental.amber)
            }
        }
        .frame(width: size, height: size)
        .background(HallowedDesign.Experimental.glass)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
        )
    }
}

private struct ProfilePopoverCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        HallowedExperimentalCard(cornerRadius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(HallowedDesign.Typography.caption.weight(.semibold))
                    .foregroundColor(HallowedDesign.Experimental.faint)
                    .textCase(.uppercase)
                    .tracking(0.6)

                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PopoverSettingsRow<Trailing: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            leading
                .layoutPriority(1)

            Spacer(minLength: 16)

            trailing
                .frame(width: PopoverSettingsRowMetrics.trailingWidth, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var leading: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HallowedDesign.Experimental.text)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

private enum PopoverSettingsRowMetrics {
    static let trailingWidth: CGFloat = 300
    static let dropdownLaneWidth: CGFloat = 230
}

private struct ProfilePopoverAchievementStats {
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

private struct ProfilePopoverAchievementBadge: Identifiable {
    let id: String
    let title: String
    let icon: String
    let isUnlocked: Bool

    static func allBadges(stats: ProfilePopoverAchievementStats) -> [ProfilePopoverAchievementBadge] {
        [
            ProfilePopoverAchievementBadge(
                id: "first-amen",
                title: "First Amen",
                icon: "hands.sparkles.fill",
                isUnlocked: stats.completedCount > 0
            ),
            ProfilePopoverAchievementBadge(
                id: "three-day-flame",
                title: "Three-Day Flame",
                icon: "flame.fill",
                isUnlocked: stats.bestCompletedDayStreak >= 3
            ),
            ProfilePopoverAchievementBadge(
                id: "seven-day-rhythm",
                title: "Seven-Day Rhythm",
                icon: "calendar.badge.checkmark",
                isUnlocked: stats.bestCompletedDayStreak >= 7
            ),
            ProfilePopoverAchievementBadge(
                id: "full-duration",
                title: "Stayed The Course",
                icon: "timer.circle.fill",
                isUnlocked: stats.hasDurationFinish
            ),
            ProfilePopoverAchievementBadge(
                id: "perfect-day",
                title: "Perfect Day",
                icon: "crown.fill",
                isUnlocked: stats.perfectDayCount > 0
            ),
            ProfilePopoverAchievementBadge(
                id: "three-perfect-days",
                title: "Faithful Flow",
                icon: "sparkles.rectangle.stack.fill",
                isUnlocked: stats.bestPerfectDayStreak >= 3
            )
        ]
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

private struct HistoryView: View {
    @EnvironmentObject var appEnv: AppEnvironment

    @State private var sessions: [PrayerSession] = []
    @State private var prayerTitles: [UUID: String] = [:]
    @State private var topicTitles: [UUID: String] = [:]
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading history…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(HallowedExperimentalBackground())
            } else if sessions.isEmpty {
                VStack(spacing: 14) {
                    Text("No prayer history yet")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(HallowedDesign.Experimental.text)
                    Text("Completed or skipped sessions will appear here.")
                        .font(HallowedDesign.Typography.label)
                        .foregroundColor(HallowedDesign.Experimental.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(HallowedExperimentalBackground())
            } else {
                List {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(HallowedDesign.Experimental.rose)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    }

                    ForEach(sessions) { session in
                        SessionRow(
                            session: session,
                            prayerTitle: session.prayerId.flatMap { prayerTitles[$0] },
                            topicTitle: session.topicId.flatMap { topicTitles[$0] }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    }
                }
                .listStyle(.inset)
                .environment(\.defaultMinListRowHeight, 0)
                .scrollContentBackground(.hidden)
                .background(HallowedExperimentalBackground())
            }
        }
        .task {
            loadHistory()
        }
    }

    private func loadHistory() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetched = try await appEnv.supabaseService.fetchRecentSessions(limit: 200)
                sessions = fetched

                let prayerIds = Array(Set(fetched.compactMap(\.prayerId)))
                let topicIds = Array(Set(fetched.compactMap(\.topicId)))

                async let prayersTask = appEnv.supabaseService.fetchPrayers(ids: prayerIds)
                async let topicsTask = appEnv.supabaseService.fetchTopics(ids: topicIds)

                let prayers = try await prayersTask
                let topics = try await topicsTask
                prayerTitles = Dictionary(uniqueKeysWithValues: prayers.map { ($0.id, $0.title) })
                topicTitles = Dictionary(uniqueKeysWithValues: topics.map { ($0.id, $0.title) })
            } catch {
                sessions = []
                prayerTitles = [:]
                topicTitles = [:]
                errorMessage = "Could not load history: \(UserFacingError.message(for: error))"
            }
            isLoading = false
        }
    }
}

private struct SessionRow: View {
    let session: PrayerSession
    let prayerTitle: String?
    let topicTitle: String?

    private var statusColor: Color {
        switch session.status {
        case .completed: return Color(hex: "10B981")
        case .skipped: return Color(hex: "F59E0B")
        case .partial: return Color(hex: "60A5FA")
        }
    }

    private var statusLabel: String {
        switch session.status {
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        case .partial: return "Partial"
        }
    }

    private var durationLabel: String {
        guard let seconds = session.durationS else { return "—" }
        let m = seconds / 60
        let s = seconds % 60
        return "\(m)m \(s)s"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.startedAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HallowedDesign.Experimental.text)

                Spacer()

                Text(statusLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }

            if let prayerTitle {
                Text(prayerTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(HallowedDesign.Experimental.text)
                    .lineLimit(2)
            }

            if let topicTitle {
                Text(topicTitle)
                    .font(.system(size: 12))
                    .foregroundColor(HallowedDesign.Experimental.muted)
                    .lineLimit(1)
            }

            HStack(spacing: 14) {
                Text(durationLabel)
                    .font(.system(size: 12))
                    .foregroundColor(HallowedDesign.Experimental.muted)

                if let endedAt = session.endedAt {
                    HStack(spacing: 4) {
                        Text(endedAt, format: .dateTime.hour().minute())
                    }
                        .font(.system(size: 12))
                        .foregroundColor(HallowedDesign.Experimental.muted)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(HallowedDesign.Experimental.glass)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment())
        .frame(width: 900, height: 650)
}
