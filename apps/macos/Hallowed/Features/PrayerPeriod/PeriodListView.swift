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
                    .background(HallowedExperimentalBackground())
            } else if periods.isEmpty && errorMessage == nil {
                emptyState
            } else if periods.isEmpty, let errorMessage {
                errorEmptyState(message: errorMessage)
            } else {
                list
            }
        }
        .background(HallowedExperimentalBackground())
        .navigationTitle("Prayer Periods")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    selectedPeriodForEditing = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(HallowedDesign.Experimental.text)
                        .frame(width: 34, height: 34)
                        .background(HallowedDesign.Experimental.glass)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Add Prayer Period")
                .accessibilityLabel("Add Prayer Period")
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
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
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
        .environment(\.defaultMinListRowHeight, 0)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Empty State

    private func errorEmptyState(message: String) -> some View {
        VStack(spacing: 16) {
            Text("Could not load prayer periods")
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundColor(HallowedDesign.Experimental.text)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(HallowedDesign.Experimental.rose)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Retry", action: loadPeriods)
                .buttonStyle(.borderedProminent)
                .tint(HallowedDesign.Experimental.amber)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("No prayer periods")
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundColor(HallowedDesign.Experimental.text)
                Text("Set a quiet moment and Hallowed will hold it for you.")
                    .font(HallowedDesign.Typography.label)
                    .foregroundColor(HallowedDesign.Experimental.muted)
            }

            Button {
                selectedPeriodForEditing = nil
                showEditor = true
            } label: {
                Text("Add Period")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(HallowedDesign.Experimental.amber)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
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
                    topicId: period.topicId,
                    prayerId: period.prayerId,
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
            RoundedRectangle(cornerRadius: 3)
                .fill(isActive ? HallowedDesign.Experimental.amber : HallowedDesign.Experimental.lineStrong)
                .frame(width: 3, height: 54)

            VStack(alignment: .leading, spacing: 7) {
                Text(period.label ?? "Prayer Period")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundColor(HallowedDesign.Experimental.text)

                FlowLayout(spacing: 12) {
                    metadataLabel(period.displayTime)
                    metadataLabel("\(period.durationMins) min")
                    metadataLabel(period.repeatSummary)
                    metadataLabel(period.focusSummary)
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
                Text("Delete")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(HallowedDesign.Experimental.rose)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(HallowedDesign.Experimental.rose.opacity(0.09))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Delete prayer period")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(HallowedDesign.Experimental.glass)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .help("Click to edit prayer period")
    }

    private func metadataLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(HallowedDesign.Experimental.muted)
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
