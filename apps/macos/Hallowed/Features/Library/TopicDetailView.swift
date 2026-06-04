import SwiftUI

struct TopicDetailView: View {

    let theme: PrayerTheme

    @EnvironmentObject var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var topics: [PrayerTopic] = []
    @State private var selectedTopic: PrayerTopic? = nil
    @State private var prayers: [Prayer] = []
    @State private var scriptures: [UUID: [Scripture]] = [:]
    @State private var isLoadingTopics: Bool = false
    @State private var isLoadingPrayers: Bool = false
    @State private var topicsLoadError: String? = nil
    @State private var prayersLoadError: String? = nil
    @State private var sessionSelection: SessionSelection? = nil
    @State private var selectedDuration: Int = 15

    private struct SessionSelection: Identifiable {
        let topic: PrayerTopic
        let prayer: Prayer
        var id: UUID { prayer.id }
    }

    private struct TopicDetailError: LocalizedError {
        let errorDescription: String?
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 720

            if isCompact {
                compactLayout
            } else {
                HStack(spacing: 0) {
                    topicList
                        .frame(width: min(300, max(220, proxy.size.width * 0.32)))

                    Divider()

                    detailPane
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color(hex: "FAF8F5"))
        .navigationTitle(selectedTopic?.title ?? theme.name)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: returnAction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "5A4A3A"))
                        .frame(width: 30, height: 30)
                        .background(Color(hex: "EFE7DC"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(selectedTopic == nil ? "Back to themes" : "Back to topics")
            }

            ToolbarItem(placement: .navigation) {
                Image(systemName: theme.icon)
                    .foregroundColor(Color(hex: theme.colorHex))
            }
        }
        .task {
            await loadTopics()
        }
        .sheet(item: $sessionSelection) { selection in
            DurationPickerSheet(
                topicTitle: selection.topic.title,
                prayerTitle: selection.prayer.title,
                themeColor: Color(hex: theme.colorHex),
                selectedDuration: $selectedDuration
            ) { duration in
                startSession(duration: duration, selection: selection)
            } onSchedule: { scheduledAt, duration in
                try await scheduleSession(scheduledAt: scheduledAt, duration: duration, selection: selection)
            }
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selectedTopic {
            prayerDetail(for: selectedTopic)
        } else {
            topicPlaceholder
        }
    }

    @ViewBuilder
    private var compactLayout: some View {
        if let selectedTopic {
            VStack(spacing: 0) {
                prayerDetail(for: selectedTopic)
            }
        } else {
            topicList
        }
    }

    private func returnAction() {
        if selectedTopic != nil {
            selectedTopic = nil
        } else {
            dismiss()
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
                    if let topicsLoadError {
                        Text("Could not load topics")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "2D2420"))
                        Text(topicsLoadError)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                    } else {
                        Text("No topics")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8B7B6E"))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(topics) { topic in
                            TopicRow(
                                topic: topic,
                                theme: theme,
                                isSelected: selectedTopic?.id == topic.id
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                selectedTopic = topic
                            }
                        }
                    }
                    .padding(16)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color(hex: "F5F1EB"))
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
                if let prayersLoadError {
                    Text("Could not load prayers")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "2D2420"))
                    Text(prayersLoadError)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                } else {
                    Text("No prayers for this topic yet")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8B7B6E"))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "FAF8F5"))
        } else {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: proxy.size.width < 460 ? 22 : 32) {
                        // Topic header
                        VStack(alignment: .leading, spacing: 6) {
                            Label(theme.name, systemImage: theme.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: theme.colorHex))
                                .textCase(.uppercase)
                                .tracking(0.8)

                            Text(topic.title)
                                .font(.system(size: proxy.size.width < 460 ? 21 : 24, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "2D2420"))
                                .fixedSize(horizontal: false, vertical: true)

                            if let description = topic.description {
                                Text(description)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "8B7B6E"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Text("Choose the prayer point you want to pray right now.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "8B7B6E"))

                        // Prayer cards — user can choose a specific point to pray.
                        ForEach(prayers) { prayer in
                            PrayerCard(
                                prayer: prayer,
                                scriptures: scriptures[prayer.id] ?? [],
                                themeColor: Color(hex: theme.colorHex),
                                isCompact: proxy.size.width < 460,
                                onPray: {
                                    sessionSelection = SessionSelection(topic: topic, prayer: prayer)
                                }
                            )
                        }
                    }
                    .padding(proxy.size.width < 460 ? 18 : 32)
                }
                .background(Color(hex: "FAF8F5"))
            }
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
        topicsLoadError = nil
        do {
            topics = try await appEnv.supabaseService.fetchTopics(for: theme.id)
        } catch {
            topics = []
            topicsLoadError = UserFacingError.message(for: error)
        }
        isLoadingTopics = false
    }

    private func startSession(duration: Int, selection: SessionSelection) {
        ScreenOverlayManager.shared.show(
            prayer: selection.prayer,
            topic: selection.topic,
            theme: theme,
            durationMinutes: duration,
            appEnv: appEnv
        )
        sessionSelection = nil
    }

    private func scheduleSession(scheduledAt: Date, duration: Int, selection: SessionSelection) async throws {
        guard let userId = appEnv.currentUser?.id else {
            throw TopicDetailError(errorDescription: "Not signed in.")
        }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduledAt)
        let minute = calendar.component(.minute, from: scheduledAt)
        let timeString = String(format: "%02d:%02d:00", hour, minute)

        let period = PrayerPeriod(
            id: UUID(),
            userId: userId,
            label: selection.topic.title,
            scheduledDate: PrayerPeriod.dateString(from: scheduledAt),
            timeOfDay: timeString,
            durationMins: duration,
            repeatType: nil,
            customDays: nil,
            themeId: theme.id,
            customTopics: [selection.prayer.title],
            isActive: true
        )

        try await appEnv.supabaseService.savePeriod(period)
        let allPeriods = (try? await appEnv.supabaseService.fetchPeriods()) ?? [period]
        appEnv.applyPrayerSchedules(allPeriods)
        sessionSelection = nil
    }

    private func loadPrayers(for topic: PrayerTopic) async {
        isLoadingPrayers = true
        prayersLoadError = nil
        prayers = []
        scriptures = [:]
        do {
            let fetchedPrayers = try await appEnv.supabaseService.fetchPrayers(for: topic.id)
            prayers = fetchedPrayers
            if !fetchedPrayers.isEmpty {
                let ids = fetchedPrayers.map(\.id)
                scriptures = try await appEnv.supabaseService.fetchScriptures(for: ids)
            }
        } catch {
            prayers = []
            scriptures = [:]
            prayersLoadError = UserFacingError.message(for: error)
        }
        isLoadingPrayers = false
    }
}

// MARK: - Duration Picker Sheet

private struct DurationPickerSheet: View {
    private enum ActionMode: String, CaseIterable {
        case now = "Pray now"
        case later = "Schedule"
    }

    @Environment(\.dismiss) private var dismiss

    let topicTitle: String
    let prayerTitle: String
    let themeColor: Color
    @Binding var selectedDuration: Int
    let onBegin: (Int) -> Void
    let onSchedule: (Date, Int) async throws -> Void

    private let presets = [5, 10, 15, 20, 30]

    @State private var actionMode: ActionMode = .now
    @State private var scheduledAt: Date = Date().addingTimeInterval(3600)
    @State private var isScheduling: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 6) {
                    Text(actionMode == .now ? "How long would you like to pray?" : "When should Hallowed remind you?")
                        .font(.system(size: 18, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "2D2420"))
                        .multilineTextAlignment(.center)
                    Text(topicTitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8B7B6E"))
                        .multilineTextAlignment(.center)
                    Text(prayerTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "8B6F4E"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "5A4A3A"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "EFE7DC"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Cancel")
            }

            Picker("Action", selection: $actionMode) {
                ForEach(ActionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Preset buttons
            FlowLayout(spacing: 10) {
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

            if actionMode == .later {
                VStack(alignment: .leading, spacing: 10) {
                    DatePicker(
                        "Date and time",
                        selection: $scheduledAt,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.field)

                    Text("This creates a one-time reminder for this prayer point.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8B7B6E"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(hex: "FDF9F5"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "E8DDD3"), lineWidth: 1)
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "B94A36"))
                    .multilineTextAlignment(.center)
            }

            // Begin button
            Button(action: primaryAction) {
                HStack(spacing: 8) {
                    if isScheduling {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: actionMode == .now ? "hands.sparkles.fill" : "calendar.badge.clock")
                    }
                    Text(actionMode == .now ? "Begin \(selectedDuration)-minute prayer" : "Schedule prayer")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(themeColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(isScheduling)

            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(Color(hex: "5A4A3A"))
        }
        .padding(32)
        .frame(minWidth: 300, idealWidth: 380, maxWidth: 440)
    }

    private func primaryAction() {
        errorMessage = nil

        switch actionMode {
        case .now:
            onBegin(selectedDuration)
        case .later:
            isScheduling = true
            Task {
                do {
                    try await onSchedule(scheduledAt, selectedDuration)
                    dismiss()
                } catch {
                    errorMessage = UserFacingError.message(for: error)
                }
                isScheduling = false
            }
        }
    }
}

// MARK: - Topic Row

private struct TopicRow: View {
    let topic: PrayerTopic
    let theme: PrayerTheme
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isSelected ? Color(hex: theme.colorHex) : Color.clear)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(topic.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "2D2420"))
                    .lineLimit(2)

                if let description = topic.description {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8B7B6E"))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(isSelected ? Color.white : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(hex: "E8DDD3") : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Prayer Card

private struct PrayerCard: View {
    let prayer: Prayer
    let scriptures: [Scripture]
    let themeColor: Color
    let isCompact: Bool
    let onPray: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 14 : 16) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text(prayer.title)
                    .font(.system(size: isCompact ? 16 : 18, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "2D2420"))
                    .fixedSize(horizontal: false, vertical: true)

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
                    FlowLayout(spacing: 6) {
                        ForEach(scriptures) { scripture in
                            Text(scripture.reference)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "8B6F4E"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "F5EDE0"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.top, 4)
            }

            Button(action: onPray) {
                HStack(spacing: 8) {
                    Image(systemName: "hands.sparkles.fill")
                    Text("Pray This Point")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(themeColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(isCompact ? 16 : 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "E8DDD3"), lineWidth: 1)
        )
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(in: proposal.width ?? 0, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for item in result.items {
            subviews[item.index].place(
                at: CGPoint(x: bounds.minX + item.frame.minX, y: bounds.minY + item.frame.minY),
                proposal: ProposedViewSize(item.frame.size)
            )
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (items: [(index: Int, frame: CGRect)], size: CGSize) {
        var items: [(index: Int, frame: CGRect)] = []
        var cursor = CGPoint.zero
        var rowHeight: CGFloat = 0
        let availableWidth = max(width, 1)

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if cursor.x > 0, cursor.x + size.width > availableWidth {
                cursor.x = 0
                cursor.y += rowHeight + spacing
                rowHeight = 0
            }

            items.append((index, CGRect(origin: cursor, size: size)))
            cursor.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (items, CGSize(width: availableWidth, height: cursor.y + rowHeight))
    }
}

#Preview {
    TopicDetailView(
        theme: PrayerTheme(id: UUID(), name: "Gratitude", icon: "heart.fill", colorHex: "C49A6C", sortOrder: 1)
    )
    .environmentObject(AppEnvironment())
    .frame(width: 800, height: 600)
}
