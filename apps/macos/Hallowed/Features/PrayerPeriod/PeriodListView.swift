import SwiftUI

struct PeriodListView: View {

    @EnvironmentObject var appEnv: AppEnvironment

    @State private var periods: [PrayerPeriod] = []
    @State private var isLoading: Bool = false
    @State private var showEditor: Bool = false
    @State private var selectedPeriodForEditing: PrayerPeriod?
    @State private var errorMessage: String? = nil
    @State private var periodPendingDeletion: PrayerPeriod?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "FAF8F5"))
            } else if periods.isEmpty && errorMessage == nil {
                emptyState
            } else if periods.isEmpty, let errorMessage {
                errorEmptyState(message: errorMessage)
            } else {
                list
            }
        }
        .background(Color(hex: "FAF8F5"))
        .navigationTitle("Prayer Periods")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    selectedPeriodForEditing = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .help("Add Prayer Period")
            }
        }
        .sheet(isPresented: $showEditor, onDismiss: {
            selectedPeriodForEditing = nil
            loadPeriods()
        }) {
            PeriodEditorView(period: selectedPeriodForEditing)
        }
        .alert(
            "Delete Prayer Period?",
            isPresented: Binding(
                get: { periodPendingDeletion != nil },
                set: { if !$0 { periodPendingDeletion = nil } }
            ),
            presenting: periodPendingDeletion
        ) { period in
            Button("Delete", role: .destructive) {
                deletePeriod(period)
            }
            Button("Cancel", role: .cancel) {
                periodPendingDeletion = nil
            }
        } message: { period in
            Text("This removes \(period.label ?? "this prayer period") and cancels its future reminders.")
        }
        .task {
            loadPeriods()
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .listRowBackground(Color.clear)
            }

            ForEach(periods) { period in
                PeriodRow(
                    period: period,
                    onToggle: { newValue in
                        togglePeriod(period, isActive: newValue)
                    },
                    onEdit: {
                        editPeriod(period)
                    },
                    onDelete: {
                        periodPendingDeletion = period
                    }
                )
                .listRowBackground(Color.white)
                .listRowSeparatorTint(Color(hex: "EDE5D8"))
                .contextMenu {
                    Button {
                        editPeriod(period)
                    } label: {
                        Label("Edit Prayer Period", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        periodPendingDeletion = period
                    } label: {
                        Label("Delete Prayer Period", systemImage: "trash")
                    }
                }
            }
            .onDelete(perform: deletePeriods)
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private func errorEmptyState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Color(hex: "E07B5A"))
            Text("Could not load prayer periods")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "2D2420"))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Retry", action: loadPeriods)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "8B6F4E"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.plus")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Color(hex: "C4B5A8"))

            VStack(spacing: 6) {
                Text("No prayer periods")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "2D2420"))
                Text("Add a recurring time to be reminded to pray.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8B7B6E"))
            }

            Button {
                selectedPeriodForEditing = nil
                showEditor = true
            } label: {
                Label("Add Period", systemImage: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "8B6F4E"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadPeriods() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                periods = try await appEnv.supabaseService.fetchPeriods()
            } catch {
                periods = []
                errorMessage = UserFacingError.message(for: error)
            }
            isLoading = false
        }
    }

    private func togglePeriod(_ period: PrayerPeriod, isActive: Bool) {
        // Rebuild with flipped isActive
        // PrayerPeriod is a value type; we need to rebuild it via upsert
        Task {
            do {
                // Construct an updated copy using the same fields, replacing isActive
                let updated = PrayerPeriod(
                    id: period.id,
                    userId: period.userId,
                    label: period.label,
                    scheduledDate: period.scheduledDate,
                    timeOfDay: period.timeOfDay,
                    durationMins: period.durationMins,
                    repeatType: period.repeatType,
                    customDays: period.customDays,
                    themeId: period.themeId,
                    customTopics: period.customTopics,
                    isActive: isActive
                )
                try await appEnv.supabaseService.savePeriod(updated)
                // Update local list
                if let idx = periods.firstIndex(where: { $0.id == period.id }) {
                    periods[idx] = updated
                }
                appEnv.applyPrayerSchedules(periods)
            } catch {
                errorMessage = "Failed to update: \(error.localizedDescription)"
            }
        }
    }

    private func editPeriod(_ period: PrayerPeriod) {
        selectedPeriodForEditing = period
        showEditor = true
    }

    private func deletePeriods(at offsets: IndexSet) {
        let toDelete = offsets.map { periods[$0] }
        Task {
            for period in toDelete {
                do {
                    try await appEnv.supabaseService.deletePeriod(id: period.id)
                } catch {
                    errorMessage = "Could not delete period: \(error.localizedDescription)"
                    return
                }
            }
            periods.remove(atOffsets: offsets)
            appEnv.applyPrayerSchedules(periods)
        }
    }

    private func deletePeriod(_ period: PrayerPeriod) {
        periodPendingDeletion = nil
        Task {
            do {
                try await appEnv.supabaseService.deletePeriod(id: period.id)
                periods.removeAll { $0.id == period.id }
                appEnv.applyPrayerSchedules(periods)
            } catch {
                errorMessage = "Could not delete period: \(UserFacingError.message(for: error))"
            }
        }
    }
}

// MARK: - Period Row

private struct PeriodRow: View {
    let period: PrayerPeriod
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isActive: Bool

    init(
        period: PrayerPeriod,
        onToggle: @escaping (Bool) -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.period = period
        self.onToggle = onToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
        _isActive = State(initialValue: period.isActive)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Left accent
            RoundedRectangle(cornerRadius: 3)
                .fill(isActive ? Color(hex: "8B6F4E") : Color(hex: "D4C9BE"))
                .frame(width: 4, height: 44)

            // Info block
            VStack(alignment: .leading, spacing: 4) {
                Text(period.label ?? "Prayer Period")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "2D2420"))

                FlowLayout(spacing: 10) {
                    metadataLabel(period.displayTime, systemImage: "clock")
                    metadataLabel("\(period.durationMins) min", systemImage: "timer")
                    metadataLabel(period.repeatSummary, systemImage: "repeat")
                    metadataLabel(period.focusSummary, systemImage: "scope")
                }
            }

            Spacer()

            Toggle("", isOn: $isActive)
                .toggleStyle(.switch)
                .controlSize(.small)
                .onChange(of: isActive) { _, newValue in
                    onToggle(newValue)
                }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "B94A36"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "B94A36").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .help("Delete prayer period")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .help("Click to edit prayer period")
    }

    private func metadataLabel(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "8B7B6E"))
            .lineLimit(1)
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
    PeriodListView()
        .environmentObject(AppEnvironment())
        .frame(width: 600, height: 500)
}
