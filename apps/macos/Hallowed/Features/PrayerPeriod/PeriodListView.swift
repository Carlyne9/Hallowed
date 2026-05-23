import SwiftUI

struct PeriodListView: View {

    @EnvironmentObject var appEnv: AppEnvironment

    @State private var periods: [PrayerPeriod] = []
    @State private var isLoading: Bool = false
    @State private var showEditor: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "FAF8F5"))
            } else if periods.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Color(hex: "FAF8F5"))
        .navigationTitle("Prayer Periods")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .help("Add Prayer Period")
            }
        }
        .sheet(isPresented: $showEditor, onDismiss: loadPeriods) {
            PeriodEditorView()
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
                PeriodRow(period: period) { newValue in
                    togglePeriod(period, isActive: newValue)
                }
                .listRowBackground(Color.white)
                .listRowSeparatorTint(Color(hex: "EDE5D8"))
            }
            .onDelete(perform: deletePeriods)
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

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
        Task {
            periods = (try? await appEnv.supabaseService.fetchPeriods()) ?? []
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
                    timeOfDay: period.timeOfDay,
                    durationMins: period.durationMins,
                    repeatType: period.repeatType,
                    customDays: period.customDays,
                    isActive: isActive
                )
                try await appEnv.supabaseService.savePeriod(updated)
                // Update local list
                if let idx = periods.firstIndex(where: { $0.id == period.id }) {
                    periods[idx] = updated
                }
                appEnv.notificationScheduler.schedule(periods.filter(\.isActive))
            } catch {
                errorMessage = "Failed to update: \(error.localizedDescription)"
            }
        }
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
            appEnv.notificationScheduler.schedule(periods.filter(\.isActive))
        }
    }
}

// MARK: - Period Row

private struct PeriodRow: View {
    let period: PrayerPeriod
    let onToggle: (Bool) -> Void

    @State private var isActive: Bool

    init(period: PrayerPeriod, onToggle: @escaping (Bool) -> Void) {
        self.period = period
        self.onToggle = onToggle
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

                HStack(spacing: 12) {
                    Label(period.displayTime, systemImage: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8B7B6E"))
                    Label("\(period.durationMins) min", systemImage: "timer")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8B7B6E"))
                    Label(period.repeatType.displayName, systemImage: "repeat")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8B7B6E"))
                }
            }

            Spacer()

            Toggle("", isOn: $isActive)
                .toggleStyle(.switch)
                .controlSize(.small)
                .onChange(of: isActive) { _, newValue in
                    onToggle(newValue)
                }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}

#Preview {
    PeriodListView()
        .environmentObject(AppEnvironment())
        .frame(width: 600, height: 500)
}
