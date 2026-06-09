import SwiftUI

struct ThemeListView: View {

    let themes: [PrayerTheme]
    let loadError: String?

    @EnvironmentObject var appEnv: AppEnvironment

    @State private var topicCounts: [UUID: Int] = [:]
    @State private var topicCountLoadError: String? = nil
    @State private var selectedTheme: PrayerTheme? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                HallowedExperimentalBackground()

                if themes.isEmpty {
                    emptyState
                } else {
                    GeometryReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Prayer library")
                                        .font(.system(size: 38, weight: .semibold, design: .serif))
                                        .foregroundColor(HallowedDesign.Experimental.text)
                                    Text("Choose the room you want to enter. No noise, no rush.")
                                        .font(.system(size: 14))
                                        .foregroundColor(HallowedDesign.Experimental.muted)
                                }

                                if let topicCountLoadError {
                                    Text("Some topic counts could not load: \(topicCountLoadError)")
                                        .font(.system(size: 12))
                                        .foregroundColor(HallowedDesign.Experimental.rose)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                LazyVGrid(columns: columns(for: proxy.size.width), spacing: 18) {
                                    ForEach(Array(themes.enumerated()), id: \.element.id) { index, theme in
                                        ThemeCard(
                                            theme: theme,
                                            topicCount: topicCounts[theme.id],
                                            index: index + 1
                                        )
                                        .onTapGesture {
                                            selectedTheme = theme
                                        }
                                    }
                                }
                            }
                            .padding(32)
                        }
                    }
                }
            }
            .navigationTitle("Themes")
            .navigationDestination(item: $selectedTheme) { theme in
                TopicDetailView(theme: theme)
            }
        }
        .task {
            await loadTopicCounts()
        }
    }

    private func columns(for width: CGFloat) -> [GridItem] {
        let count = width < 520 ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 18), count: count)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No themes yet")
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundColor(HallowedDesign.Experimental.text)
            if let loadError {
                Text("Could not load themes: \(loadError)")
                    .font(.system(size: 13))
                    .foregroundColor(HallowedDesign.Experimental.rose)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            } else {
                Text("Prayer themes will appear here once the library is seeded.")
                    .font(.system(size: 13))
                    .foregroundColor(HallowedDesign.Experimental.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func loadTopicCounts() async {
        topicCountLoadError = nil
        var firstError: Error?

        await withTaskGroup(of: (UUID, Int, Error?).self) { group in
            for theme in themes {
                group.addTask {
                    do {
                        let count = try await appEnv.supabaseService.fetchTopics(for: theme.id).count
                        return (theme.id, count, nil)
                    } catch {
                        return (theme.id, 0, error)
                    }
                }
            }
            for await (id, count, error) in group {
                topicCounts[id] = count
                if firstError == nil, let error { firstError = error }
            }
        }

        if let firstError {
            topicCountLoadError = UserFacingError.message(for: firstError)
        }
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    let theme: PrayerTheme
    let topicCount: Int?
    let index: Int

    @State private var isHovered: Bool = false

    var body: some View {
        HallowedExperimentalCard(cornerRadius: 28, padding: 24) {
            ZStack(alignment: .bottomTrailing) {
                HallowedThemeIllustration(themeName: theme.name, icon: theme.icon)
                    .frame(width: 118, height: 118)
                    .offset(x: 12, y: 12)

                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Text(String(format: "%02d", index))
                            .font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .foregroundColor(HallowedDesign.Experimental.faint)
                        Spacer()
                        Text(topicLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(HallowedDesign.Experimental.muted)
                    }

                    Spacer(minLength: 8)

                    Text(theme.name)
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundColor(HallowedDesign.Experimental.text)
                        .lineLimit(2)
                        .frame(maxWidth: 230, alignment: .leading)

                    Text("Open the collection")
                        .font(.system(size: 12))
                        .foregroundColor(HallowedDesign.Experimental.faint)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .scaleEffect(isHovered ? 1.015 : 1)
        .animation(.easeOut(duration: 0.18), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .contentShape(RoundedRectangle(cornerRadius: 28))
        .cursor(.pointingHand)
    }

    private var topicLabel: String {
        guard let topicCount else { return "Loading" }
        return "\(topicCount) \(topicCount == 1 ? "topic" : "topics")"
    }
}

// MARK: - Cursor helper

private extension View {
    @ViewBuilder
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    ThemeListView(themes: [
        PrayerTheme(id: UUID(), name: "Gratitude", icon: "heart.fill", colorHex: "C49A6C", sortOrder: 1),
        PrayerTheme(id: UUID(), name: "Intercession", icon: "hands.and.sparkles.fill", colorHex: "7B9EA6", sortOrder: 2),
        PrayerTheme(id: UUID(), name: "Confession", icon: "leaf.fill", colorHex: "7A8E5F", sortOrder: 3),
        PrayerTheme(id: UUID(), name: "Praise", icon: "music.note", colorHex: "9B7BB8", sortOrder: 4)
    ], loadError: nil)
    .environmentObject(AppEnvironment())
    .frame(width: 700, height: 500)
}
