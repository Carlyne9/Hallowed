import SwiftUI

struct PeriodEditorView: View {

    @EnvironmentObject var appEnv: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var label: String = ""
    @State private var selectedTime: Date = {
        var components = DateComponents()
        components.hour = 6
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var durationMins: Int = 15
    @State private var repeatType: PrayerPeriod.RepeatType = .daily
    @State private var selectedCustomDays: Set<Int> = [1, 2, 3, 4, 5] // Mon-Fri default

    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    private let weekdayOptions: [(index: Int, shortLabel: String)] = [
        (0, "Sun"), (1, "Mon"), (2, "Tue"), (3, "Wed"), (4, "Thu"), (5, "Fri"), (6, "Sat"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Text("New Prayer Period")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "2D2420"))

                Spacer()

                Button(action: save) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isSaving)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Divider()

            // Form
            Form {
                Section {
                    TextField("Morning Prayer", text: $label)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Label (optional)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "B0A098"))
                        .textCase(.uppercase)
                        .tracking(0.6)
                }

                Section {
                    DatePicker(
                        "Time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                } header: {
                    Text("Time of Day")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "B0A098"))
                        .textCase(.uppercase)
                        .tracking(0.6)
                }

                Section {
                    Stepper(
                        value: $durationMins,
                        in: 5...120,
                        step: 5
                    ) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(Color(hex: "8B6F4E"))
                            Text("\(durationMins) minutes")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "2D2420"))
                        }
                    }
                } header: {
                    Text("Duration")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "B0A098"))
                        .textCase(.uppercase)
                        .tracking(0.6)
                }

                Section {
                    Picker("Repeat", selection: $repeatType) {
                        Text(PrayerPeriod.RepeatType.daily.displayName)
                            .tag(PrayerPeriod.RepeatType.daily)
                        Text(PrayerPeriod.RepeatType.weekdays.displayName)
                            .tag(PrayerPeriod.RepeatType.weekdays)
                        Text(PrayerPeriod.RepeatType.weekends.displayName)
                            .tag(PrayerPeriod.RepeatType.weekends)
                        Text(PrayerPeriod.RepeatType.custom.displayName)
                            .tag(PrayerPeriod.RepeatType.custom)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                } header: {
                    Text("Repeat")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "B0A098"))
                        .textCase(.uppercase)
                        .tracking(0.6)
                }

                if repeatType == .custom {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                ForEach(weekdayOptions, id: \.index) { day in
                                    let isSelected = selectedCustomDays.contains(day.index)
                                    Button {
                                        if isSelected {
                                            selectedCustomDays.remove(day.index)
                                        } else {
                                            selectedCustomDays.insert(day.index)
                                        }
                                    } label: {
                                        Text(day.shortLabel)
                                            .font(.system(size: 12, weight: .semibold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 7)
                                            .background(
                                                isSelected ? Color(hex: "8B6F4E") : Color(hex: "EFE7DC")
                                            )
                                            .foregroundColor(isSelected ? .white : Color(hex: "5A4A3A"))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Text("Choose at least one day.")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "8B7B6E"))
                        }
                    } header: {
                        Text("Custom Days")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "B0A098"))
                            .textCase(.uppercase)
                            .tracking(0.6)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "FAF8F5"))
            .onChange(of: repeatType) { _, newValue in
                // Keep custom mode usable out of the box.
                if newValue == .custom, selectedCustomDays.isEmpty {
                    selectedCustomDays = [1, 2, 3, 4, 5]
                }
            }

            // Error
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }

            // Save button (full-width at bottom)
            Button(action: save) {
                Group {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                            Text("Save Prayer Period")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
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
            .disabled(isSaving)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(hex: "FAF8F5"))
        .frame(width: 380, height: 560)
    }

    // MARK: - Save

    private func save() {
        guard let userId = appEnv.currentUser?.id else {
            errorMessage = "Not signed in."
            return
        }

        isSaving = true
        errorMessage = nil

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedTime)
        let minute = calendar.component(.minute, from: selectedTime)
        let timeString = String(format: "%02d:%02d:00", hour, minute)
        let customDays = repeatType == .custom ? Array(selectedCustomDays).sorted() : nil

        if repeatType == .custom && (customDays?.isEmpty ?? true) {
            errorMessage = "Select at least one custom day."
            return
        }

        let period = PrayerPeriod(
            id: UUID(),
            userId: userId,
            label: label.trimmingCharacters(in: .whitespaces).isEmpty ? nil : label.trimmingCharacters(in: .whitespaces),
            timeOfDay: timeString,
            durationMins: durationMins,
            repeatType: repeatType,
            customDays: customDays,
            isActive: true
        )

        Task {
            do {
                try await appEnv.supabaseService.savePeriod(period)
                let allPeriods = (try? await appEnv.supabaseService.fetchPeriods()) ?? [period]
                appEnv.notificationScheduler.schedule(allPeriods.filter(\.isActive))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

#Preview {
    PeriodEditorView()
        .environmentObject(AppEnvironment())
}
