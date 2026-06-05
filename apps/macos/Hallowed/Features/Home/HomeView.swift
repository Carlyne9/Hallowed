import SwiftUI

struct HomeView: View {

    @EnvironmentObject var appEnv: AppEnvironment

    @State private var themes: [PrayerTheme] = []
    @State private var periods: [PrayerPeriod] = []
    @State private var themesLoadError: String? = nil
    @State private var periodsLoadError: String? = nil
    @State private var selectedSection: SidebarSection? = .themes
    @State private var isLoadingSession: Bool = false
    @State private var sessionStartError: String? = nil

    enum SidebarSection: String, Hashable, CaseIterable {
        case themes = "Themes"
        case periods = "Prayer Periods"
        case history = "History"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .themes:    return "books.vertical.fill"
            case .periods:   return "clock.fill"
            case .history:   return "calendar.badge.clock"
            case .settings:  return "gearshape.fill"
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
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        VStack(spacing: 0) {
            // Wordmark
            HStack {
                Image(systemName: "hands.and.sparkles.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "8B6F4E"), Color(hex: "C49A6C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Hallowed")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(Color(hex: "2D2420"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)

            Divider()
                .padding(.bottom, 8)

            // Navigation links
            List(SidebarSection.allCases, id: \.self, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "2D2420"))
                    .tag(section)
            }
            .listStyle(.sidebar)

            Spacer()
            Divider()

            // Pray Now button
            Button(action: startRandomSession) {
                HStack(spacing: 8) {
                    if isLoadingSession {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                        Text("Pray Now")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "8B6F4E"), Color(hex: "7A5F3E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(isLoadingSession)
            .padding(16)

            if let sessionStartError {
                Text(sessionStartError)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .background(Color(hex: "F5F1EB"))
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
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
        case .settings:
            SettingsView()
        case .none:
            dashboard
        }
    }

    // MARK: - Dashboard

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {

                // Date header
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "B0A098"))
                        .textCase(.uppercase)
                    Text("Good \(timeOfDayGreeting)")
                        .font(.system(size: 28, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "2D2420"))
                }

                // Stats row
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
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                if let periodsLoadError {
                    Text("Periods load error: \(periodsLoadError)")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }

                // Scripture card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Scripture", systemImage: "book.closed.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "B0A098"))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\"Be still and know that I am God.\"")
                            .font(.system(size: 17, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "2D2420"))
                            .italic()
                        Text("— Psalm 46:10")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8B7B6E"))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "FDF9F5"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "E8DDD3"), lineWidth: 1)
                    )
                }

                // Start prayer button
                Button(action: startRandomSession) {
                    HStack(spacing: 10) {
                        if isLoadingSession {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                            Text("Start Random Prayer")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "8B6F4E"), Color(hex: "7A5F3E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(isLoadingSession)

                Spacer()
            }
            .padding(32)
        }
        .background(Color(hex: "FAF8F5"))
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
}

// MARK: - Supporting Views

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "8B6F4E"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "EDE5D8"))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "2D2420"))
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8B7B6E"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "E8DDD3"), lineWidth: 1)
        )
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
                    .background(Color(hex: "FAF8F5"))
            } else if sessions.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 34, weight: .light))
                        .foregroundColor(Color(hex: "C4B5A8"))
                    Text("No prayer history yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "2D2420"))
                    Text("Completed or skipped sessions will appear here.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8B7B6E"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "FAF8F5"))
            } else {
                List {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .listRowBackground(Color.clear)
                    }

                    ForEach(sessions) { session in
                        SessionRow(
                            session: session,
                            prayerTitle: session.prayerId.flatMap { prayerTitles[$0] },
                            topicTitle: session.topicId.flatMap { topicTitles[$0] }
                        )
                        .listRowBackground(Color.white)
                        .listRowSeparatorTint(Color(hex: "EDE5D8"))
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                .background(Color(hex: "FAF8F5"))
            }
        }
        .navigationTitle("Prayer History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    loadHistory()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
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
                    .foregroundColor(Color(hex: "2D2420"))

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
                    .foregroundColor(Color(hex: "2D2420"))
                    .lineLimit(2)
            }

            if let topicTitle {
                Text(topicTitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8B7B6E"))
                    .lineLimit(1)
            }

            HStack(spacing: 14) {
                Label(durationLabel, systemImage: "timer")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8B7B6E"))

                if let endedAt = session.endedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.checkered")
                        Text(endedAt, format: .dateTime.hour().minute())
                    }
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8B7B6E"))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment())
        .frame(width: 900, height: 650)
}
