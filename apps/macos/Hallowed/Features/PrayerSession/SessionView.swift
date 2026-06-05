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
    let pacesPrayerPoints: Bool
    let onComplete: () -> Void

    @EnvironmentObject var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var lifecycle: PrayerSessionLifecycle

    @State private var scriptures: [UUID: [Scripture]] = [:]
    @State private var scriptureTexts: [UUID: String] = [:]
    @State private var isLoadingScriptures: Bool = true
    @State private var hasReachedTimedConclusion: Bool = false

    init(
        prayer: Prayer,
        topic: PrayerTopic,
        theme: PrayerTheme,
        durationMinutes: Int,
        pacesPrayerPoints: Bool = false,
        lifecycle: PrayerSessionLifecycle? = nil,
        onComplete: @escaping () -> Void
    ) {
        self.prayer = prayer
        self.topic = topic
        self.theme = theme
        self.durationMinutes = durationMinutes
        self.pacesPrayerPoints = pacesPrayerPoints
        _lifecycle = StateObject(wrappedValue: lifecycle ?? PrayerSessionLifecycle())
        self.onComplete = onComplete
    }

    private var strictMode: Bool { SessionPreferences.isStrictModeEnabled }

    private func timerLabel(at date: Date) -> String {
        guard durationMinutes > 0 else { return "Prayer time" }
        let remainingSeconds = remainingSeconds(at: date)
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private var usesPacedPrayerPoints: Bool {
        pacesPrayerPoints && durationMinutes > 0 && prayer.bullets.count > 1
    }

    // Palette: deep warm dark
    private let bgColor = Color(hex: "1C1612")
    private let surfaceColor = Color(hex: "261E18")
    private let accentColor = Color(hex: "C49A6C")
    private let textPrimary = Color(hex: "F5EDE0")
    private let textMuted = Color(hex: "8B7B6E")
    private let dividerColor = Color(hex: "3D302A")
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                bgColor.ignoresSafeArea()
                chimeInspiredChrome

                VStack(spacing: 0) {
                    // Top bar
                    topBar

                    Divider()
                        .background(dividerColor)

                    sessionContent

                    // Bottom action bar
                    bottomBar
                }
                .frame(
                    width: min(proxy.size.width - 72, 780),
                    height: min(proxy.size.height - 72, 720)
                )
                .background(
                    LinearGradient(
                        colors: [Color(hex: "261E18"), Color(hex: "1F1814")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(accentColor.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.34), radius: 34, x: 0, y: 22)
                .shadow(color: accentColor.opacity(0.12), radius: 46, x: 0, y: 0)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        // Scripture loading runs independently — doesn't block the session
        .task { await loadScriptures() }
        // The countdown is derived from lifecycle.startedAt so it survives overlay rebuilds.
        .task(id: lifecycle.id) { await runTimer() }
    }

    // MARK: - Sub-views

    private var chimeInspiredChrome: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(0.36))

            LinearGradient(
                colors: [
                    Color(hex: theme.colorHex).opacity(0.24),
                    accentColor.opacity(0.16),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blur(radius: 90)
            .frame(height: 300)
            .offset(y: -140)

            PulsingPrayerBorder(color: Color(hex: theme.colorHex))
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    TimelineView(.periodic(from: Date(), by: 30)) { context in
                        Text(
                            context.date,
                            format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)
                                .hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits)
                        )
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(textPrimary.opacity(0.68))
                        .padding(.trailing, 32)
                        .padding(.top, 28)
                    }
                }
                Spacer()
            }
        }
    }

    private var topBar: some View {
        ZStack {
            durationIndicator
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 16) {
                topLeadingControl

                Spacer(minLength: 16)

                topTrailingProgress
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(surfaceColor)
    }

    @ViewBuilder
    private var topLeadingControl: some View {
        if hasReachedTimedConclusion {
            Text("Prayer completed")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textMuted)
        } else if strictMode {
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
    }

    private var topTrailingProgress: some View {
        TimelineView(.periodic(from: lifecycle.startedAt, by: 1)) { context in
            let activeIndex = activeBulletIndex(at: context.date)

            if usesPacedPrayerPoints && !hasReachedTimedConclusion {
                Text("Point \(activeIndex + 1)/\(prayer.bullets.count)")
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundColor(accentColor)
            }
        }
        .frame(width: 150, alignment: .trailing)
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

    private var durationIndicator: some View {
        TimelineView(.periodic(from: lifecycle.startedAt, by: 1)) { context in
            let remaining = remainingSeconds(at: context.date)
            if !hasReachedTimedConclusion {
                HStack(spacing: 8) {
                    Image(systemName: durationMinutes > 0 ? "timer" : "clock")
                        .font(.system(size: 13, weight: .semibold))
                    Text(timerLabel(at: context.date))
                        .font(.system(size: 20, weight: .semibold).monospacedDigit())
                }
                .foregroundColor(remaining <= 60 && durationMinutes > 0 ? Color(hex: "E07B5A") : textMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(accentColor.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(accentColor.opacity(0.14), lineWidth: 1)
                )
                .animation(.easeInOut, value: remaining)
            }
        }
    }

    @ViewBuilder
    private var sessionContent: some View {
        if hasReachedTimedConclusion {
            conclusionContent
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            prayerContent
                .transition(.opacity)
        }
    }

    private var prayerContent: some View {
        TimelineView(.periodic(from: lifecycle.startedAt, by: 1)) { context in
            let activeBulletIndex = activeBulletIndex(at: context.date)
            let activeBullet = prayer.bullets.indices.contains(activeBulletIndex) ? prayer.bullets[activeBulletIndex] : prayer.body

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
                    let activeScriptures = scriptures[prayer.id] ?? []
                    if isLoadingScriptures {
                        ProgressView()
                            .controlSize(.small)
                            .tint(accentColor)
                    } else if let activeScripture = activeScripture(from: activeScriptures, at: context.date) {
                        scriptureBlock(for: activeScripture)
                    }

                    // Divider line
                    Rectangle()
                        .fill(dividerColor)
                        .frame(height: 1)

                    // Prayer bullets
                    activeBulletView(activeBullet)

                    // Author
                    if let author = prayer.author {
                        Text("- \(author)")
                            .font(.system(size: 13))
                            .italic()
                            .foregroundColor(textMuted)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 36)
            }
        }
    }

    private var conclusionContent: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 24)

            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(accentColor)
                    .shadow(color: accentColor.opacity(0.28), radius: 18, x: 0, y: 8)

                Text("Prayer time is complete")
                    .font(.system(size: 30, weight: .light, design: .serif))
                    .foregroundColor(textPrimary)

                Text("Take a breath. You showed up, and this moment is sealed with grace.")
                    .font(.system(size: 15))
                    .foregroundColor(textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 460)
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Declaration", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentColor)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(declarationText)
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundColor(textPrimary)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(maxWidth: 560, alignment: .leading)
            .background(accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(accentColor.opacity(0.22), lineWidth: 1)
            )

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scriptureBlock(for scripture: Scripture) -> some View {
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

    private func activeBulletView(_ bullet: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(accentColor)
                .frame(width: 7, height: 7)
                .padding(.top, 13)

            Text(bullet)
                .font(.system(size: 24, weight: .light, design: .serif))
                .foregroundColor(textPrimary.opacity(0.94))
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
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
                        Text(hasReachedTimedConclusion ? "Amen, I receive this" : "Amen")
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
            scriptures = try await appEnv.supabaseService.fetchScriptures(for: [prayer.id])
        } catch {
            scriptures = [:]
            print("[SessionView] Could not load scripture references: \(UserFacingError.message(for: error))")
            isLoadingScriptures = false
            return
        }

        isLoadingScriptures = false
        let translationCode = await preferredTranslationCode()
        let allScriptures = scriptures.values.flatMap { $0 }

        await withTaskGroup(of: (UUID, String?).self) { group in
            for scripture in allScriptures {
                group.addTask {
                    let text = await BibleService.shared.verseText(for: scripture, translationCode: translationCode)
                    return (scripture.id, text)
                }
            }
            for await (id, text) in group {
                if let text { scriptureTexts[id] = text }
            }
        }

        if !allScriptures.isEmpty && scriptureTexts.isEmpty {
            print("[SessionView] Verse text unavailable; showing scripture references only.")
        }
    }

    private func preferredTranslationCode() async -> String {
        guard let userId = appEnv.currentUser?.id else { return "NIV" }
        return await appEnv.supabaseService.fetchPreferredTranslation(for: userId)
    }

    private func runTimer() async {
        guard durationMinutes > 0 else { return }

        while remainingSeconds(at: Date()) > 0 {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                return
            }
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            hasReachedTimedConclusion = true
        }
    }

    private func remainingSeconds(at date: Date) -> Int {
        guard durationMinutes > 0 else { return 0 }
        let durationSeconds = durationMinutes * 60
        let elapsed = max(0, Int(date.timeIntervalSince(lifecycle.startedAt)))
        return max(0, durationSeconds - elapsed)
    }

    private func activeBulletIndex(at date: Date) -> Int {
        guard usesPacedPrayerPoints else { return 0 }

        let durationSeconds = max(1, durationMinutes * 60)
        let elapsed = min(durationSeconds - 1, max(0, Int(date.timeIntervalSince(lifecycle.startedAt))))
        let rawIndex = Int((Double(elapsed) / Double(durationSeconds)) * Double(prayer.bullets.count))
        return min(prayer.bullets.count - 1, max(0, rawIndex))
    }

    private func activeScripture(from scriptures: [Scripture], at date: Date) -> Scripture? {
        guard !scriptures.isEmpty else { return nil }
        return scriptures[activeScriptureIndex(for: scriptures, at: date)]
    }

    private func activeScriptureIndex(for scriptures: [Scripture], at date: Date) -> Int {
        guard pacesPrayerPoints && durationMinutes > 0 && scriptures.count > 1 else { return 0 }

        let durationSeconds = max(1, durationMinutes * 60)
        let elapsed = min(durationSeconds - 1, max(0, Int(date.timeIntervalSince(lifecycle.startedAt))))
        let rawIndex = Int((Double(elapsed) / Double(durationSeconds)) * Double(scriptures.count))
        return min(scriptures.count - 1, max(0, rawIndex))
    }

    private var declarationText: String {
        let focus = declarationFocus
        return "As I go about my day, I receive God's peace over \(focus). I am steady, guarded, and led by grace. Amen."
    }

    private var declarationFocus: String {
        let source = "\(topic.title) \(prayer.title) \(prayer.body)".lowercased()

        if source.contains("anxiety") || source.contains("fear") || source.contains("worry") {
            return "every anxious thought"
        }
        if source.contains("lust") || source.contains("temptation") || source.contains("purity") {
            return "my thoughts, desires, and purity"
        }
        if source.contains("heal") || source.contains("health") || source.contains("sick") {
            return "my body, mind, and healing"
        }
        if source.contains("family") || source.contains("children") || source.contains("marriage") {
            return "my home and relationships"
        }
        if source.contains("work") || source.contains("provision") || source.contains("financ") {
            return "my work, provision, and responsibilities"
        }
        if source.contains("forgive") || source.contains("confess") || source.contains("sin") {
            return "my heart, choices, and renewed obedience"
        }
        if source.contains("thank") || source.contains("gratitude") || source.contains("praise") {
            return "gratitude, worship, and contentment"
        }

        return topic.title.lowercased()
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

private struct PulsingPrayerBorder: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        Rectangle()
            .strokeBorder(
                color,
                lineWidth: isPulsing ? 7 : 3
            )
            .opacity(isPulsing ? 0.48 : 0.22)
            .blur(radius: isPulsing ? 16 : 8)
            .animation(
                .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
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
