import SwiftUI

@MainActor
final class PrayerSessionLifecycle: ObservableObject {
    let id: UUID
    let periodId: UUID?
    let startedAt: Date
    let shouldLogContentIDs: Bool

    private var isFinished = false

    init(
        id: UUID = UUID(),
        periodId: UUID? = nil,
        startedAt: Date = Date(),
        shouldLogContentIDs: Bool = true
    ) {
        self.id = id
        self.periodId = periodId
        self.startedAt = startedAt
        self.shouldLogContentIDs = shouldLogContentIDs
    }

    func beginFinishing() -> Bool {
        guard !isFinished else { return false }
        isFinished = true
        return true
    }
}

struct SessionView: View {

    let prayer: Prayer
    let topic: PrayerTopic
    let theme: PrayerTheme
    let durationMinutes: Int
    let onComplete: () -> Void

    @EnvironmentObject var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var lifecycle: PrayerSessionLifecycle

    @State private var scriptures: [Scripture] = []
    @State private var scriptureTexts: [UUID: String] = [:]
    @State private var isLoadingScriptures: Bool = true
    @State private var remainingSeconds: Int = 0

    init(
        prayer: Prayer,
        topic: PrayerTopic,
        theme: PrayerTheme,
        durationMinutes: Int,
        lifecycle: PrayerSessionLifecycle? = nil,
        onComplete: @escaping () -> Void
    ) {
        self.prayer = prayer
        self.topic = topic
        self.theme = theme
        self.durationMinutes = durationMinutes
        _lifecycle = StateObject(wrappedValue: lifecycle ?? PrayerSessionLifecycle())
        self.onComplete = onComplete
    }

    private var strictMode: Bool { SessionPreferences.isStrictModeEnabled }

    private var timerLabel: String {
        guard durationMinutes > 0 else { return "Prayer time" }
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // Palette: deep warm dark
    private let bgColor = Color(hex: "1C1612")
    private let surfaceColor = Color(hex: "261E18")
    private let accentColor = Color(hex: "C49A6C")
    private let textPrimary = Color(hex: "F5EDE0")
    private let textMuted = Color(hex: "8B7B6E")
    private let dividerColor = Color(hex: "3D302A")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                Divider()
                    .background(dividerColor)

                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 36) {

                        // Theme + topic breadcrumb
                        breadcrumb

                        // Prayer title
                        Text(prayer.title)
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .foregroundColor(textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Scriptures
                        if isLoadingScriptures {
                            ProgressView()
                                .controlSize(.small)
                                .tint(accentColor)
                        } else if !scriptures.isEmpty {
                            scriptureBlock
                        }

                        // Divider line
                        Rectangle()
                            .fill(dividerColor)
                            .frame(height: 1)

                        // Prayer bullets
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(prayer.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: 5, height: 5)
                                        .padding(.top, 7)

                                    Text(bullet)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(textPrimary.opacity(0.9))
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        // Author
                        if let author = prayer.author {
                            Text("— \(author)")
                                .font(.system(size: 13))
                                .italic()
                                .foregroundColor(textMuted)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 48)
                    .padding(.vertical, 36)
                }

                // Bottom action bar
                bottomBar
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        // Scripture loading runs independently — doesn't block the session
        .task { await loadScriptures() }
        // Timer starts immediately when session appears
        .task {
            guard durationMinutes > 0 else { return }
            remainingSeconds = durationMinutes * 60
            while remainingSeconds > 0 {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
                remainingSeconds = max(0, remainingSeconds - 1)
            }
            finishSession(status: .completed)
        }
    }

    // MARK: - Sub-views

    private var topBar: some View {
        HStack {
            if strictMode {
                Text("Prayer session")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textMuted)
            } else {
                Button("Skip") {
                    finishSession(status: .skipped)
                }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(textMuted)
            }

            Spacer()

            // Duration indicator / countdown
            HStack(spacing: 4) {
                Image(systemName: durationMinutes > 0 ? "timer" : "clock")
                    .font(.system(size: 11))
                Text(timerLabel)
                    .font(.system(size: 12).monospacedDigit())
            }
            .foregroundColor(remainingSeconds <= 60 && durationMinutes > 0 ? Color(hex: "E07B5A") : textMuted)
            .animation(.easeInOut, value: remainingSeconds)

            Spacer()

            if strictMode {
                EmptyView()
            } else {
                Text("Skip")
                    .font(.system(size: 13))
                    .foregroundColor(.clear)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(surfaceColor)
    }

    private var breadcrumb: some View {
        HStack(spacing: 6) {
            Image(systemName: theme.icon)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: theme.colorHex))
            Text(theme.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: theme.colorHex))
                .textCase(.uppercase)
                .tracking(0.8)

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(textMuted)

            Text(topic.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textMuted)
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }

    private var scriptureBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(scriptures) { scripture in
                VStack(alignment: .leading, spacing: 8) {
                    if let text = scriptureTexts[scripture.id] {
                        Text("\u{201C}\(text)\u{201D}")
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundColor(accentColor.opacity(0.9))
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }
                    Text(scripture.reference)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentColor.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(0.6)
                }
                .padding(14)
                .background(accentColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(dividerColor)

            HStack {
                Spacer()

                Button(action: {
                    finishSession(status: .completed)
                }) {
                    HStack(spacing: 10) {
                        Text("Amen")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "hands.sparkles.fill")
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
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
                .keyboardShortcut(.return, modifiers: .command)

                Spacer()
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 20)
            .background(surfaceColor)
        }
    }

    // MARK: - Data

    private func loadScriptures() async {
        isLoadingScriptures = true

        do {
            let map = try await appEnv.supabaseService.fetchScriptures(for: [prayer.id])
            scriptures = map[prayer.id] ?? []
        } catch {
            scriptures = []
            print("[SessionView] Could not load scripture references: \(UserFacingError.message(for: error))")
            isLoadingScriptures = false
            return
        }

        isLoadingScriptures = false
        let translationCode = await preferredTranslationCode()

        await withTaskGroup(of: (UUID, String?).self) { group in
            for scripture in scriptures {
                group.addTask {
                    let text = await BibleService.shared.verseText(for: scripture, translationCode: translationCode)
                    return (scripture.id, text)
                }
            }
            for await (id, text) in group {
                if let text { scriptureTexts[id] = text }
            }
        }

        if !scriptures.isEmpty && scriptureTexts.isEmpty {
            print("[SessionView] Verse text unavailable; showing scripture references only.")
        }
    }

    private func preferredTranslationCode() async -> String {
        guard let userId = appEnv.currentUser?.id else { return "NIV" }
        return await appEnv.supabaseService.fetchPreferredTranslation(for: userId)
    }

    private func finishSession(status: PrayerSession.SessionStatus) {
        guard lifecycle.beginFinishing() else { return }

        if let userId = appEnv.currentUser?.id {
            let elapsed = Int(Date().timeIntervalSince(lifecycle.startedAt))
            let session = PrayerSession(
                id: lifecycle.id,
                userId: userId,
                periodId: lifecycle.periodId,
                prayerId: lifecycle.shouldLogContentIDs ? prayer.id : nil,
                topicId: lifecycle.shouldLogContentIDs ? topic.id : nil,
                startedAt: lifecycle.startedAt,
                endedAt: Date(),
                durationS: elapsed,
                status: status,
                notes: nil
            )

            Task {
                do {
                    try await appEnv.supabaseService.logSession(session)
                } catch {
                    print("[SessionView] Failed to log session: \(UserFacingError.message(for: error))")
                }
            }
        }

        onComplete()
        dismiss()
    }
}

#Preview {
    let samplePrayer = Prayer(
        id: UUID(),
        topicId: UUID(),
        title: "A Prayer of Gratitude",
        body: "Lord, thank you for this day.\nThank you for your faithfulness.\nThank you for your endless grace.",
        author: "Augustine of Hippo",
        isClassic: true
    )
    let sampleTopic = PrayerTopic(
        id: UUID(),
        themeId: UUID(),
        title: "Daily Gratitude",
        description: nil,
        tags: [],
        sortOrder: 1
    )
    let sampleTheme = PrayerTheme(
        id: UUID(),
        name: "Gratitude",
        icon: "heart.fill",
        colorHex: "C49A6C",
        sortOrder: 1
    )
    return SessionView(
        prayer: samplePrayer,
        topic: sampleTopic,
        theme: sampleTheme,
        durationMinutes: 15,
        onComplete: {}
    )
    .environmentObject(AppEnvironment())
    .frame(width: 700, height: 600)
}
