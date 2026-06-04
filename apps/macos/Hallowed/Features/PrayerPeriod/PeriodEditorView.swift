import SwiftUI

struct PeriodEditorView: View {

    private enum ScheduleMode: String, CaseIterable {
        case oneTime = "One time"
        case recurring = "Recurring"
    }

    private enum FocusMode: String, CaseIterable {
        case open = "Just pray"
        case theme = "Theme"
        case customTopics = "My topics"
    }

    @EnvironmentObject var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    private let existingPeriod: PrayerPeriod?

    @State private var title: String = ""
    @State private var scheduleMode: ScheduleMode = .oneTime
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = PeriodEditorView.defaultTime(hour: 6, minute: 0)
    @State private var durationMins: Int = 15
    @State private var repeatType: PrayerPeriod.RepeatType = .daily
    @State private var selectedCustomDays: Set<Int> = [1, 2, 3, 4, 5]
    @State private var focusMode: FocusMode = .open
    @State private var themes: [PrayerTheme] = []
    @State private var selectedThemeId: UUID?
    @State private var customTopicsText: String = ""
    @State private var isActive: Bool = true
    @State private var isLoadingThemes: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    init(period: PrayerPeriod? = nil) {
        self.existingPeriod = period

        let isRecurring = period.map { $0.scheduledDate == nil } ?? false
        let hasCustomTopics = !(period?.customTopics ?? []).isEmpty

        _title = State(initialValue: period?.label ?? "")
        _scheduleMode = State(initialValue: isRecurring ? .recurring : .oneTime)
        _selectedDate = State(initialValue: period?.scheduledDateValue ?? Date())
        _selectedTime = State(initialValue: Self.timeDate(from: period?.timeOfDay) ?? Self.defaultTime(hour: 6, minute: 0))
        _durationMins = State(initialValue: period?.durationMins ?? 15)
        _repeatType = State(initialValue: period?.repeatType ?? .daily)
        _selectedCustomDays = State(initialValue: Set(period?.customDays ?? [1, 2, 3, 4, 5]))
        _focusMode = State(initialValue: hasCustomTopics ? .customTopics : (period?.themeId == nil ? .open : .theme))
        _selectedThemeId = State(initialValue: period?.themeId)
        _customTopicsText = State(initialValue: (period?.customTopics ?? []).joined(separator: ", "))
        _isActive = State(initialValue: period?.isActive ?? true)
    }

    private let timePresets: [(label: String, systemImage: String, hour: Int, minute: Int)] = [
        ("Morning", "sunrise.fill", 6, 0),
        ("Noon", "sun.max.fill", 12, 0),
        ("Evening", "sunset.fill", 18, 0),
        ("Bedtime", "moon.stars.fill", 21, 0),
    ]

    private let quickTestOffsets: [(label: String, minutes: Int)] = [
        ("In 1 min", 1),
        ("In 2 min", 2),
    ]

    private let durationPresets = [5, 10, 15, 20, 30, 45, 60]

    private let weekdayOptions: [(index: Int, shortLabel: String, longLabel: String)] = [
        (0, "S", "Sun"),
        (1, "M", "Mon"),
        (2, "T", "Tue"),
        (3, "W", "Wed"),
        (4, "T", "Thu"),
        (5, "F", "Fri"),
        (6, "S", "Sat"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    sectionCard("Prayer Title", systemImage: "text.quote") {
                        TextField("Healing for Mum, Morning devotion, Quiet prayer...", text: $title)
                            .textFieldStyle(.roundedBorder)
                        helperText("This is the name shown in the list, notification, and prayer session.")
                    }

                    sectionCard("Time", systemImage: "clock.fill") {
                        quickTimeGrid
                        Divider()
                        HStack {
                            Text("Specific time")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "5A4A3A"))
                            Spacer()
                            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.field)
                                .labelsHidden()
                                .frame(width: 120)
                        }
                        quickTestRow
                    }

                    sectionCard("Day", systemImage: "calendar") {
                        choiceRow(ScheduleMode.allCases, selection: $scheduleMode) { $0.rawValue }

                        if scheduleMode == .oneTime {
                            HStack {
                                Text("Prayer date")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "5A4A3A"))
                                Spacer()
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(.field)
                                    .labelsHidden()
                                    .frame(width: 130)
                            }
                            helperText("One-time prayers are for this date only. No recurrence is added unless you choose Recurring.")
                        } else {
                            repeatPicker
                            if repeatType == .custom {
                                dayPicker
                            }
                        }
                    }

                    sectionCard("Prayer Focus", systemImage: "scope") {
                        choiceRow(FocusMode.allCases, selection: $focusMode) { $0.rawValue }

                        focusBody
                    }

                    sectionCard("Duration", systemImage: "timer") {
                        durationChips
                        Stepper(value: $durationMins, in: 1...180, step: 1) {
                            Text("\(durationMins) minutes")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "2D2420"))
                        }
                    }

                    sectionCard("Preview", systemImage: "checkmark.seal.fill") {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: isActive ? "bell.and.waves.left.and.right.fill" : "bell.slash")
                                .foregroundColor(Color(hex: "8B6F4E"))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(summaryTitle)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "2D2420"))
                                Text(summarySubtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "8B7B6E"))
                            }
                            Spacer()
                            Toggle("Active", isOn: $isActive)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "B94A36"))
                    }
                }
                .padding(24)
                .padding(.bottom, 6)
            }
            .scrollIndicators(.visible)

            Divider()
            footer
        }
        .background(Color(hex: "FAF8F5"))
        .frame(minWidth: 420, idealWidth: 560, maxWidth: 640, minHeight: 560, idealHeight: 700, maxHeight: 760)
        .task { await loadThemes() }
        .onChange(of: repeatType) { _, newValue in
            if newValue == .custom, selectedCustomDays.isEmpty {
                selectedCustomDays = [1, 2, 3, 4, 5]
            }
        }
        .onChange(of: focusMode) { _, newValue in
            if newValue == .theme, selectedThemeId == nil {
                selectedThemeId = themes.first?.id
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "8B6F4E").opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: existingPeriod == nil ? "calendar.badge.plus" : "pencil")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "8B6F4E"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(existingPeriod == nil ? "New Prayer Period" : "Edit Prayer Period")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Color(hex: "2D2420"))
                Text(existingPeriod == nil ? "Set a prayer title, day, time, and optional focus." : "Change the title, day, time, duration, or focus.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8B7B6E"))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "5A4A3A"))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "EFE7DC"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Close")
            .accessibilityLabel("Close new prayer period form")
                .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var quickTimeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(timePresets, id: \.label) { preset in
                Button {
                    selectedTime = Self.defaultTime(hour: preset.hour, minute: preset.minute)
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: preset.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(preset.label)
                                .font(.system(size: 13, weight: .semibold))
                            Text(Self.timeLabel(hour: preset.hour, minute: preset.minute))
                                .font(.system(size: 11))
                                .opacity(0.75)
                        }
                        Spacer()
                    }
                    .padding(11)
                    .background(isTimeSelected(hour: preset.hour, minute: preset.minute) ? Color(hex: "8B6F4E") : Color(hex: "EFE7DC"))
                    .foregroundColor(isTimeSelected(hour: preset.hour, minute: preset.minute) ? .white : Color(hex: "5A4A3A"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var quickTestRow: some View {
        HStack(spacing: 8) {
            Text("Test")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "B0A098"))
                .textCase(.uppercase)
                .tracking(0.6)
            ForEach(quickTestOffsets, id: \.label) { preset in
                Button(preset.label) {
                    let date = Date().addingTimeInterval(TimeInterval(preset.minutes * 60))
                    selectedDate = date
                    selectedTime = date
                    scheduleMode = .oneTime
                    durationMins = min(durationMins, 5)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            Spacer()
        }
    }

    private var repeatPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            choiceRow(PrayerPeriod.RepeatType.allCases, selection: $repeatType) { $0.displayName }

            Text(repeatDescription)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8B7B6E"))
        }
    }

    @ViewBuilder
    private var focusBody: some View {
        switch focusMode {
        case .open:
            helperText("No prayer points will be assigned. Hallowed will simply open prayer time at the scheduled moment.")
        case .theme:
            if isLoadingThemes {
                ProgressView()
                    .controlSize(.small)
            } else if themes.isEmpty {
                helperText("No themes loaded yet. You can still save this as open prayer.")
            } else {
                Picker("Theme", selection: Binding(
                    get: { selectedThemeId ?? themes.first?.id },
                    set: { selectedThemeId = $0 }
                )) {
                    ForEach(themes) { theme in
                        Label(theme.name, systemImage: theme.icon).tag(Optional(theme.id))
                    }
                }
                .labelsHidden()
                helperText("At prayer time, Hallowed will choose from this theme.")
            }
        case .customTopics:
            TextField("Finances, my children, healing, exams...", text: $customTopicsText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            helperText("Separate topics with commas or new lines. These become your prayer prompts for this period.")
        }
    }

    private var dayPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(weekdayOptions, id: \.index) { day in
                    let isSelected = selectedCustomDays.contains(day.index)
                    Button {
                        toggleDay(day.index)
                    } label: {
                        VStack(spacing: 2) {
                            Text(day.shortLabel)
                                .font(.system(size: 14, weight: .bold))
                            Text(day.longLabel)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isSelected ? Color(hex: "8B6F4E") : Color(hex: "EFE7DC"))
                        .foregroundColor(isSelected ? .white : Color(hex: "5A4A3A"))
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Button("Weekdays") { selectedCustomDays = [1, 2, 3, 4, 5] }
                Button("Weekends") { selectedCustomDays = [0, 6] }
                Button("Clear") { selectedCustomDays.removeAll() }
                Spacer()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var durationChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(durationPresets, id: \.self) { minutes in
                Button {
                    durationMins = minutes
                } label: {
                    Text("\(minutes)m")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(durationMins == minutes ? Color(hex: "8B6F4E") : Color(hex: "EFE7DC"))
                        .foregroundColor(durationMins == minutes ? .white : Color(hex: "5A4A3A"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(Color(hex: "5A4A3A"))

            Spacer()

            Button(action: save) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                        .frame(width: 120)
                } else {
                    Label(existingPeriod == nil ? "Save Period" : "Update Period", systemImage: "checkmark")
                        .frame(width: 120)
                }
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(isSaving)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "8B6F4E"))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(hex: "FAF8F5"))
    }

    private func sectionCard<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "B0A098"))
                .textCase(.uppercase)
                .tracking(0.8)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "E8DDD3"), lineWidth: 1)
            )
        }
    }

    private func helperText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "8B7B6E"))
    }

    private func choiceRow<Option: Hashable>(
        _ options: [Option],
        selection: Binding<Option>,
        title: @escaping (Option) -> String
    ) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection.wrappedValue == option
                Button {
                    selection.wrappedValue = option
                } label: {
                    Text(title(option))
                        .font(.system(size: 12, weight: .semibold))
                        .frame(minWidth: 86)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 10)
                        .background(isSelected ? Color(hex: "8B6F4E") : Color(hex: "EFE7DC"))
                        .foregroundColor(isSelected ? .white : Color(hex: "5A4A3A"))
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var summaryTitle: String {
        "\(displayTime(selectedTime)) • \(durationMins) min"
    }

    private var summarySubtitle: String {
        "\(periodTitle) • \(scheduleSummary) • \(focusSummary)"
    }

    private var periodTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Prayer Time" : trimmed
    }

    private var scheduleSummary: String {
        if scheduleMode == .oneTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: selectedDate)
        }
        return repeatSummary
    }

    private var repeatDescription: String {
        switch repeatType {
        case .daily:
            return "Every day at \(displayTime(selectedTime))."
        case .weekdays:
            return "Monday through Friday at \(displayTime(selectedTime))."
        case .weekends:
            return "Saturday and Sunday at \(displayTime(selectedTime))."
        case .custom:
            return selectedCustomDays.isEmpty
                ? "Choose at least one day."
                : "\(customDaySummary) at \(displayTime(selectedTime))."
        }
    }

    private var repeatSummary: String {
        switch repeatType {
        case .daily:
            return "Every day"
        case .weekdays:
            return "Weekdays"
        case .weekends:
            return "Weekends"
        case .custom:
            return selectedCustomDays.isEmpty ? "Custom days" : customDaySummary
        }
    }

    private var customDaySummary: String {
        weekdayOptions
            .filter { selectedCustomDays.contains($0.index) }
            .map(\.longLabel)
            .joined(separator: ", ")
    }

    private var focusSummary: String {
        switch focusMode {
        case .open:
            return "No specific prayer points"
        case .theme:
            return selectedThemeName.map { "Theme: \($0)" } ?? "Theme focus"
        case .customTopics:
            let topics = parsedCustomTopics
            return topics.isEmpty ? "Custom topics" : topics.joined(separator: ", ")
        }
    }

    private var selectedThemeName: String? {
        guard let selectedThemeId else { return nil }
        return themes.first { $0.id == selectedThemeId }?.name
    }

    private var parsedCustomTopics: [String] {
        customTopicsText
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func toggleDay(_ index: Int) {
        if selectedCustomDays.contains(index) {
            selectedCustomDays.remove(index)
        } else {
            selectedCustomDays.insert(index)
        }
    }

    private func isTimeSelected(hour: Int, minute: Int) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.hour, from: selectedTime) == hour
            && calendar.component(.minute, from: selectedTime) == minute
    }

    private func save() {
        guard let userId = appEnv.currentUser?.id else {
            errorMessage = "Not signed in."
            return
        }

        if scheduleMode == .recurring, repeatType == .custom, selectedCustomDays.isEmpty {
            errorMessage = "Select at least one custom day."
            return
        }

        if focusMode == .customTopics, parsedCustomTopics.isEmpty {
            errorMessage = "Enter at least one prayer topic."
            return
        }

        isSaving = true
        errorMessage = nil

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedTime)
        let minute = calendar.component(.minute, from: selectedTime)
        let timeString = String(format: "%02d:%02d:00", hour, minute)

        let period = PrayerPeriod(
            id: existingPeriod?.id ?? UUID(),
            userId: existingPeriod?.userId ?? userId,
            label: periodTitle,
            scheduledDate: scheduleMode == .oneTime ? PrayerPeriod.dateString(from: selectedDate) : nil,
            timeOfDay: timeString,
            durationMins: durationMins,
            repeatType: scheduleMode == .recurring ? repeatType : nil,
            customDays: scheduleMode == .recurring && repeatType == .custom ? Array(selectedCustomDays).sorted() : nil,
            themeId: focusMode == .theme ? selectedThemeId : nil,
            customTopics: focusMode == .customTopics ? parsedCustomTopics : nil,
            isActive: isActive
        )

        Task {
            do {
                try await appEnv.supabaseService.savePeriod(period)
                let allPeriods = (try? await appEnv.supabaseService.fetchPeriods()) ?? [period]
                appEnv.applyPrayerSchedules(allPeriods)
                dismiss()
            } catch {
                errorMessage = UserFacingError.message(for: error)
            }
            isSaving = false
        }
    }

    private func loadThemes() async {
        isLoadingThemes = true
        defer { isLoadingThemes = false }

        do {
            themes = try await appEnv.supabaseService.fetchThemes()
            if selectedThemeId == nil {
                selectedThemeId = themes.first?.id
            }
        } catch {
            themes = []
        }
    }

    private func displayTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private static func defaultTime(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func timeLabel(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: defaultTime(hour: hour, minute: minute))
    }

    private static func timeDate(from timeOfDay: String?) -> Date? {
        guard let timeOfDay else { return nil }
        let parts = timeOfDay.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        return defaultTime(hour: parts[0], minute: parts[1])
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
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
    PeriodEditorView()
        .environmentObject(AppEnvironment())
}
