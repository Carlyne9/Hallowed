import SwiftUI

struct TopicDetailView: View {

    let theme: PrayerTheme

    @EnvironmentObject var appEnv: AppEnvironment

    @State private var topics: [PrayerTopic] = []
    @State private var selectedTopic: PrayerTopic? = nil
    @State private var prayers: [Prayer] = []
    @State private var scriptures: [UUID: [Scripture]] = [:]
    @State private var isLoadingTopics: Bool = false
    @State private var isLoadingPrayers: Bool = false
    @State private var showDurationPicker: Bool = false
    @State private var selectedDuration: Int = 15

    var body: some View {
        NavigationSplitView {
            topicList
        } detail: {
            if let selectedTopic {
                prayerDetail(for: selectedTopic)
            } else {
                topicPlaceholder
            }
        }
        .navigationTitle(theme.name)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Image(systemName: theme.icon)
                    .foregroundColor(Color(hex: theme.colorHex))
            }
        }
        .task {
            await loadTopics()
        }
    }

    // MARK: - Topic List

    private var topicList: some View {
        Group {
            if isLoadingTopics {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if topics.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(Color(hex: "C4B5A8"))
                    Text("No topics")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8B7B6E"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(topics, selection: $selectedTopic) { topic in
                    TopicRow(topic: topic, theme: theme)
                        .tag(topic)
                }
                .listStyle(.sidebar)
            }
        }
        .background(Color(hex: "F5F1EB"))
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        .onChange(of: selectedTopic) { _, newTopic in
            guard let newTopic else { return }
            Task { await loadPrayers(for: newTopic) }
        }
    }

    // MARK: - Prayer Detail

    @ViewBuilder
    private func prayerDetail(for topic: PrayerTopic) -> some View {
        if isLoadingPrayers {
            ProgressView("Loading prayers…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "FAF8F5"))
        } else if prayers.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color(hex: "C4B5A8"))
                Text("No prayers for this topic yet")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8B7B6E"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "FAF8F5"))
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Pray Now button
                    Button(action: { showDurationPicker = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "hands.sparkles.fill")
                            Text("Pray Now")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: theme.colorHex))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showDurationPicker) {
                        DurationPickerSheet(
                            topicTitle: topic.title,
                            themeColor: Color(hex: theme.colorHex),
                            selectedDuration: $selectedDuration
                        ) { duration in
                            showDurationPicker = false
                            startSession(duration: duration)
                        }
                    }

                    // Topic header
                    VStack(alignment: .leading, spacing: 6) {
                        Label(theme.name, systemImage: theme.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: theme.colorHex))
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text(topic.title)
                            .font(.system(size: 24, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "2D2420"))

                        if let description = topic.description {
                            Text(description)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "8B7B6E"))
                        }
                    }

                    // Prayer cards — show up to 2 prayers
                    ForEach(prayers.prefix(2)) { prayer in
                        PrayerCard(
                            prayer: prayer,
                            scriptures: scriptures[prayer.id] ?? []
                        )
                    }
                }
                .padding(32)
            }
            .background(Color(hex: "FAF8F5"))
        }
    }

    private var topicPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: theme.icon)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Color(hex: theme.colorHex).opacity(0.4))
            Text("Select a topic")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "8B7B6E"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "FAF8F5"))
    }

    // MARK: - Data Loading

    private func loadTopics() async {
        isLoadingTopics = true
        topics = (try? await appEnv.supabaseService.fetchTopics(for: theme.id)) ?? []
        isLoadingTopics = false
    }

    private func startSession(duration: Int) {
        guard let topic = selectedTopic, let prayer = prayers.randomElement() else { return }
        ScreenOverlayManager.shared.show(
            prayer: prayer,
            topic: topic,
            theme: theme,
            durationMinutes: duration,
            appEnv: appEnv
        )
    }

    private func loadPrayers(for topic: PrayerTopic) async {
        isLoadingPrayers = true
        prayers = []
        scriptures = [:]
        let fetchedPrayers = (try? await appEnv.supabaseService.fetchPrayers(for: topic.id)) ?? []
        prayers = fetchedPrayers
        if !fetchedPrayers.isEmpty {
            let ids = fetchedPrayers.map(\.id)
            scriptures = (try? await appEnv.supabaseService.fetchScriptures(for: ids)) ?? [:]
        }
        isLoadingPrayers = false
    }
}

// MARK: - Duration Picker Sheet

private struct DurationPickerSheet: View {
    let topicTitle: String
    let themeColor: Color
    @Binding var selectedDuration: Int
    let onBegin: (Int) -> Void

    private let presets = [5, 10, 15, 20, 30]

    var body: some View {
        VStack(spacing: 28) {
            // Header
            VStack(spacing: 6) {
                Text("How long would you like to pray?")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2D2420"))
                Text(topicTitle)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8B7B6E"))
            }

            // Preset buttons
            HStack(spacing: 10) {
                ForEach(presets, id: \.self) { minutes in
                    Button(action: { selectedDuration = minutes }) {
                        Text("\(minutes)m")
                            .font(.system(size: 14, weight: selectedDuration == minutes ? .semibold : .regular))
                            .frame(width: 52, height: 44)
                            .background(selectedDuration == minutes ? themeColor : Color(hex: "F0EAE1"))
                            .foregroundColor(selectedDuration == minutes ? .white : Color(hex: "5A4A3A"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom stepper
            HStack(spacing: 12) {
                Text("Custom:")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8B7B6E"))
                Stepper("\(selectedDuration) min", value: $selectedDuration, in: 1...120)
                    .font(.system(size: 13))
                    .frame(width: 160)
            }

            // Begin button
            Button(action: { onBegin(selectedDuration) }) {
                HStack(spacing: 8) {
                    Image(systemName: "hands.sparkles.fill")
                    Text("Begin \(selectedDuration)-minute prayer")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(themeColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(width: 380)
    }
}

// MARK: - Topic Row

private struct TopicRow: View {
    let topic: PrayerTopic
    let theme: PrayerTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(topic.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "2D2420"))
            if let description = topic.description {
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8B7B6E"))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Prayer Card

private struct PrayerCard: View {
    let prayer: Prayer
    let scriptures: [Scripture]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text(prayer.title)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "2D2420"))

                if let author = prayer.author {
                    Text("— \(author)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "8B7B6E"))
                        .italic()
                }
            }

            Divider()
                .background(Color(hex: "E8DDD3"))

            // Body / bullets
            VStack(alignment: .leading, spacing: 10) {
                ForEach(prayer.bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundColor(Color(hex: "C49A6C"))
                            .padding(.top, 5)
                        Text(bullet)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "3D3028"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // Scriptures
            if !scriptures.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Scriptures", systemImage: "book.closed.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "B0A098"))
                        .textCase(.uppercase)
                        .tracking(0.6)
                    ForEach(scriptures) { scripture in
                        Text(scripture.reference)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8B6F4E"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "F5EDE0"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "E8DDD3"), lineWidth: 1)
        )
    }
}

#Preview {
    TopicDetailView(
        theme: PrayerTheme(id: UUID(), name: "Gratitude", icon: "heart.fill", colorHex: "C49A6C", sortOrder: 1)
    )
    .environmentObject(AppEnvironment())
    .frame(width: 800, height: 600)
}
