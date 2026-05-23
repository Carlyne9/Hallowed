import SwiftUI
import UserNotifications

struct SettingsView: View {

    @EnvironmentObject var appEnv: AppEnvironment

    @State private var notificationsEnabled: Bool = false
    @State private var isRequestingPermission: Bool = false
    @State private var isSigningOut: Bool = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
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
                                        .foregroundColor(Color(hex: "2D2420"))
                                }
                                Divider().padding(.leading, 16)
                            }

                            // Email
                            SettingsRow(label: "Email", icon: "envelope") {
                                Text(user.email ?? "—")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "8B7B6E"))
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

                // About section
                SettingsSection(title: "About", icon: "info.circle.fill") {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsRow(label: "App", icon: "hands.and.sparkles.fill") {
                            Text("Hallowed")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "2D2420"))
                        }
                        Divider().padding(.leading, 16)
                        SettingsRow(label: "Version", icon: "tag") {
                            Text("\(appVersion) (\(buildNumber))")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "8B7B6E"))
                        }
                        Divider().padding(.leading, 16)
                        SettingsRow(label: "Bundle", icon: "shippingbox") {
                            Text("com.hallowed.macos")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(hex: "8B7B6E"))
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .background(Color(hex: "FAF8F5"))
        .navigationTitle("Settings")
        .task {
            await checkNotificationStatus()
        }
    }

    // MARK: - Page Header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "hands.and.sparkles.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "8B6F4E"), Color(hex: "C49A6C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Hallowed")
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2D2420"))
            }
            Text("Settings")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8B7B6E"))
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
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "B0A098"))
                .textCase(.uppercase)
                .tracking(0.8)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "E8DDD3"), lineWidth: 1)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8B6F4E"))
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "2D2420"))

            Spacer()

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppEnvironment())
        .frame(width: 600, height: 700)
}
