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
            Group {
                if themes.isEmpty {
                    emptyState
                } else {
                    GeometryReader { proxy in
                        ScrollView {
                            if let topicCountLoadError {
                                Text("Some topic counts could not load: \(topicCountLoadError)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 16)
                            }
                            LazyVGrid(columns: columns(for: proxy.size.width), spacing: 16) {
                                ForEach(themes) { theme in
                                    ThemeCard(
                                        theme: theme,
                                        topicCount: topicCounts[theme.id]
                                    )
                                    .onTapGesture {
                                        selectedTheme = theme
                                    }
                                }
                            }
                            .padding(24)
                        }
                    }
                }
            }
            .background(Color(hex: "FAF8F5"))
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
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Color(hex: "C4B5A8"))
            Text("No themes yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "2D2420"))
            if let loadError {
                Text("Could not load themes: \(loadError)")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            } else {
                Text("Prayer themes will appear here once the library is seeded.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8B7B6E"))
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

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Icon
            Image(systemName: theme.icon)
                .font(.system(size: 26, weight: .light))
                .foregroundColor(Color(hex: theme.colorHex))
                .frame(width: 50, height: 50)
                .background(Color(hex: theme.colorHex).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            // Name + count
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "2D2420"))
                    .lineLimit(2)

                if let count = topicCount {
                    Text("\(count) \(count == 1 ? "topic" : "topics")")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8B7B6E"))
                } else {
                    Text("Loading…")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "B0A098"))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(isHovered ? Color(hex: "F0EAE1") : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isHovered ? Color(hex: theme.colorHex).opacity(0.35) : Color(hex: "E8DDD3"),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: Color(hex: "2D2420").opacity(isHovered ? 0.08 : 0.04),
            radius: isHovered ? 10 : 4,
            x: 0,
            y: isHovered ? 4 : 2
        )
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .cursor(.pointingHand)
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
