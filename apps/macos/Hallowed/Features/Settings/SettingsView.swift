import SwiftUI
import UserNotifications
import ServiceManagement

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment

    let showsCancelButton: Bool

    @State private var notificationsEnabled: Bool = false
    @State private var isRequestingPermission: Bool = false
    @State private var isSigningOut: Bool = false
    @State private var selectedTranslation: String = "NIV"
    @State private var isLoadingTranslation: Bool = true
    @State private var isSavingTranslation: Bool = false
    @State private var strictSessionMode: Bool = SessionPreferences.isStrictModeEnabled
    @State private var automaticTakeoverEnabled: Bool = AutomaticTakeoverPreferences.isEnabled
    @State private var launchAtLoginEnabled: Bool = false
    @State private var loginItemMessage: String?
    @State private var isUpdatingLoginItem: Bool = false

    private let translationOptions = ["NIV", "KJV", "ESV", "NLT", "MSG"]

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    init(showsCancelButton: Bool = false) {
        self.showsCancelButton = showsCancelButton
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                pageHeader

                // Account section
                SettingsSection(title: "Account", icon: "person.circle.fill") {
                    VStack(alignment: .leading, spacing: 0) {
                        if let user = appEnv.currentUser {
                            // Display name
                            if let name = user.userMetadata["full_name"]?.stringValue {
                                SettingsRow(label: "Name", icon: "person") {
                                    Text(name)
                                        .font(.system(size: 13))
                                        .foregroundColor(HallowedDesign.Experimental.text)
                                }
                                Divider().padding(.leading, 16)
                            }

                            // Email
                            SettingsRow(label: "Email", icon: "envelope") {
                                Text(user.email ?? "—")
                                    .font(.system(size: 13))
                                    .foregroundColor(HallowedDesign.Experimental.muted)
                            }
                        }

                        Divider().padding(.leading, 16)

                        // Sign out
                        SettingsRow(label: "Sign Out", icon: "rectangle.portrait.and.arrow.right") {
                            Button(action: signOut) {
                                if isSigningOut {
                                    ProgressView()
                                        .controlSize(.mini)
                                } else {
                                    Text("Sign Out")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(red: 0.75, green: 0.2, blue: 0.2))
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isSigningOut)
                        }
                    }
                }

                // Notifications section
                SettingsSection(title: "Notifications", icon: "bell.fill") {
                    SettingsRow(label: "Enable Notifications", icon: "bell") {
                        Toggle("", isOn: $notificationsEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: notificationsEnabled) { _, enabled in
                                if enabled {
                                    requestNotificationPermission()
                                }
                            }
                    }
                }

                // Automatic takeover section
                SettingsSection(title: "Automatic Takeover", icon: "sparkles.rectangle.stack.fill") {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsRow(label: "Start Prayer Automatically", icon: "rectangle.inset.filled.and.person.filled") {
                            Toggle("", isOn: $automaticTakeoverEnabled)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .onChange(of: automaticTakeoverEnabled) { _, enabled in
                                    setAutomaticTakeover(enabled)
                                }
                        }
                        Divider().padding(.leading, 16)
                        SettingsRow(label: "Launch Hallowed at Login", icon: "power") {
                            Toggle("", isOn: $launchAtLoginEnabled)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .onChange(of: launchAtLoginEnabled) { _, enabled in
                                    if !isUpdatingLoginItem {
                                        setLaunchAtLogin(enabled)
                                    }
                                }
                        }
                        Divider().padding(.leading, 16)
                        Text(loginItemMessage ?? "When Hallowed is running, active prayer periods can begin without requiring a notification tap. Notifications remain as a fallback.")
                            .font(.system(size: 12))
                            .foregroundColor(HallowedDesign.Experimental.muted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                }

                // Scripture section
                SettingsSection(title: "Scripture", icon: "book.closed.fill") {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsRow(label: "Translation", icon: "text.book.closed") {
                            if isLoadingTranslation {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Picker("Translation", selection: $selectedTranslation) {
                                    ForEach(translationOptions, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 110)
                                .onChange(of: selectedTranslation) { _, newValue in
                                    savePreferredTranslation(newValue)
                                }
                            }
                        }
                    }
                }

                // Prayer session section
                SettingsSection(title: "Prayer Session", icon: "lock.shield.fill") {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsRow(label: "Strict mode", icon: "lock.fill") {
                            Toggle("", isOn: $strictSessionMode)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .onChange(of: strictSessionMode) { _, enabled in
                                    SessionPreferences.isStrictModeEnabled = enabled
                                }
                        }
                        Divider().padding(.leading, 16)
                        Text("Hides Skip, keeps the overlay on top, and discourages switching away during a session.")
                            .font(.system(size: 12))
                            .foregroundColor(HallowedDesign.Experimental.muted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                }

                // About section
                SettingsSection(title: "About", icon: "info.circle.fill") {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsRow(label: "App", icon: "hands.and.sparkles.fill") {
                            Text("Hallowed")
                                .font(.system(size: 13))
                                .foregroundColor(HallowedDesign.Experimental.text)
                        }
                        Divider().padding(.leading, 16)
                        SettingsRow(label: "Version", icon: "tag") {
                            Text("\(appVersion) (\(buildNumber))")
                                .font(.system(size: 13))
                                .foregroundColor(HallowedDesign.Experimental.muted)
                        }
                        Divider().padding(.leading, 16)
                        SettingsRow(label: "Bundle", icon: "shippingbox") {
                            Text("com.hallowed.macos")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(HallowedDesign.Experimental.muted)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .background {
            HallowedExperimentalBackground()
        }
        .navigationTitle("Settings")
        .task {
            await checkNotificationStatus()
            await loadPreferredTranslation()
            refreshLoginItemStatus()
        }
    }

    // MARK: - Page Header

    private var pageHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings")
                    .font(.system(size: 42, weight: .semibold, design: .serif))
                    .foregroundColor(HallowedDesign.Experimental.text)
                Text("Tune the quiet machinery behind prayer time.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(HallowedDesign.Experimental.muted)
            }

            Spacer()

            if showsCancelButton {
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(HallowedDesign.Experimental.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(HallowedDesign.Experimental.glass)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel settings")
            }
        }
    }

    // MARK: - Actions

    private func signOut() {
        isSigningOut = true
        Task {
            appEnv.signOut()
            isSigningOut = false
        }
    }

    private func requestNotificationPermission() {
        isRequestingPermission = true
        Task {
            let granted = await appEnv.notificationScheduler.requestPermission()
            notificationsEnabled = granted
            isRequestingPermission = false
        }
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized
    }

    private func setAutomaticTakeover(_ enabled: Bool) {
        appEnv.setAutomaticTakeoverEnabled(enabled)
        guard enabled, !launchAtLoginEnabled else { return }

        isUpdatingLoginItem = true
        Task {
            do {
                try SMAppService.mainApp.register()
                refreshLoginItemStatus()
                loginItemMessage = "Automatic takeover is enabled and Hallowed will launch at login."
            } catch {
                refreshLoginItemStatus()
                loginItemMessage = "Automatic takeover works while Hallowed is open, but launch at login could not be enabled."
            }
            isUpdatingLoginItem = false
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        isUpdatingLoginItem = true
        Task {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try await SMAppService.mainApp.unregister()
                }
                refreshLoginItemStatus()
                loginItemMessage = nil
            } catch {
                refreshLoginItemStatus()
                loginItemMessage = enabled
                    ? "Launch at login could not be enabled."
                    : "Launch at login could not be disabled."
            }
            isUpdatingLoginItem = false
        }
    }

    private func refreshLoginItemStatus() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    private func loadPreferredTranslation() async {
        guard let userId = appEnv.currentUser?.id else {
            isLoadingTranslation = false
            return
        }
        let code = await appEnv.supabaseService.fetchPreferredTranslation(for: userId)
        selectedTranslation = translationOptions.contains(code) ? code : "NIV"
        isLoadingTranslation = false
    }

    private func savePreferredTranslation(_ code: String) {
        guard let userId = appEnv.currentUser?.id else { return }
        isSavingTranslation = true

        Task {
            do {
                try await appEnv.supabaseService.updatePreferredTranslation(code, for: userId)
                await MainActor.run {
                    isSavingTranslation = false
                }
            } catch {
                await MainActor.run {
                    isSavingTranslation = false
                }
            }
        }
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.muted)
                .textCase(.uppercase)
                .tracking(1.1)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .background(.ultraThinMaterial.opacity(0.82))
            .background(HallowedDesign.Experimental.glass)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
            )
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow<Trailing: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                leading
                Spacer()
                trailing
            }

            VStack(alignment: .leading, spacing: 8) {
                leading
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var leading: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(HallowedDesign.Experimental.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppEnvironment())
        .frame(width: 600, height: 700)
}
