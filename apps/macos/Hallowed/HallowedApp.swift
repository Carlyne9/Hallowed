import SwiftUI
import AppKit
import UserNotifications

@main
struct HallowedApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appEnv = AppEnvironment()
    @AppStorage("hallowed.appearanceMode") private var appearanceMode = "system"

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
            .preferredColorScheme(preferredColorScheme)
            .frame(minWidth: 640, minHeight: 520)
            .task {
                appDelegate.attach(appEnvironment: appEnv)
                appEnv.startAuthListener()
            }
            .onOpenURL { url in
                Task {
                    do {
                        try await appEnv.supabaseService.client.auth.session(from: url)
                        appEnv.authCallbackError = nil
                    } catch {
                        appEnv.authCallbackError = UserFacingError.message(for: error)
                    }
                }
            }
        }
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
                .environmentObject(appEnv)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
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
        route(notification: notification)
        completionHandler([.banner, .sound, .badge])
    }

    private func route(response: UNNotificationResponse) {
        Task { @MainActor in
            guard let appEnvironment else {
                pendingResponses.append(response)
                return
            }
            appEnvironment.handleNotification(response.notification)
        }
    }

    private func route(notification: UNNotification) {
        Task { @MainActor in
            guard let appEnvironment else { return }
            appEnvironment.handleNotification(notification)
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
