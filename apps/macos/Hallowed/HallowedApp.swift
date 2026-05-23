import SwiftUI
import AppKit
import UserNotifications

@main
struct HallowedApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appEnv = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            Group {
                if appEnv.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if appEnv.isAuthenticated {
                    HomeView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(appEnv)
            .frame(minWidth: 800, minHeight: 600)
            .task {
                appDelegate.attach(appEnvironment: appEnv)
                appEnv.startAuthListener()
            }
            .onOpenURL { url in
                Task {
                    try? await appEnv.supabaseService.client.auth.session(from: url)
                }
            }
        }
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
                .environmentObject(appEnv)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private weak var appEnvironment: AppEnvironment?
    private var pendingResponses: [UNNotificationResponse] = []

    func applicationWillFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    func attach(appEnvironment: AppEnvironment) {
        Task { @MainActor in
            self.appEnvironment = appEnvironment
            self.flushPendingResponses()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        route(response: response)
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    private func route(response: UNNotificationResponse) {
        Task { @MainActor in
            guard let appEnvironment else {
                pendingResponses.append(response)
                return
            }
            appEnvironment.handleNotificationResponse(response)
        }
    }

    private func flushPendingResponses() {
        Task { @MainActor in
            guard let appEnvironment else { return }
            let responses = pendingResponses
            pendingResponses.removeAll()

            for response in responses {
                appEnvironment.handleNotificationResponse(response)
            }
        }
    }
}
