import Foundation
import Supabase
import Auth
import UserNotifications

@MainActor
final class AppEnvironment: ObservableObject {

    // MARK: - Published State

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: Auth.User? = nil
    @Published var isLoading: Bool = true

    // MARK: - Services

    let supabaseService: SupabaseService
    let notificationScheduler: NotificationScheduler
    let prayerRandomizer: PrayerRandomizer
    private var handledNotificationRequestIDs: Set<String> = []
    private var hasStartedAuthListener = false

    // MARK: - Init

    init() {
        let supabaseService = SupabaseService()
        self.supabaseService = supabaseService
        self.notificationScheduler = NotificationScheduler()
        self.prayerRandomizer = PrayerRandomizer()
    }

    // MARK: - Auth Listener

    func startAuthListener() {
        guard !hasStartedAuthListener else { return }
        hasStartedAuthListener = true

        Task {
            isLoading = true
            for await (event, session) in supabaseService.client.auth.authStateChanges {
                switch event {
                case .initialSession:
                    currentUser = session?.user
                    isAuthenticated = session != nil
                    isLoading = false
                case .signedIn:
                    currentUser = session?.user
                    isAuthenticated = true
                    isLoading = false
                case .signedOut, .userDeleted:
                    currentUser = nil
                    isAuthenticated = false
                    isLoading = false
                case .tokenRefreshed, .userUpdated:
                    currentUser = session?.user
                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            do {
                try await supabaseService.client.auth.signOut()
            } catch {
                print("[AppEnvironment] Sign out error: \(error)")
            }
        }
    }

    // MARK: - Notification Routing

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let request = response.notification.request
        let requestID = request.identifier

        // Avoid double-handling if macOS replays the same response.
        if handledNotificationRequestIDs.contains(requestID) { return }
        handledNotificationRequestIDs.insert(requestID)

        guard let periodIDString = request.content.userInfo["periodId"] as? String,
              let periodID = UUID(uuidString: periodIDString) else {
            return
        }

        Task {
            await launchSessionFromPeriod(periodID: periodID)
        }
    }

    private func launchSessionFromPeriod(periodID: UUID) async {
        guard isAuthenticated else {
            print("[AppEnvironment] Ignoring notification launch while signed out.")
            return
        }

        do {
            guard let period = try await supabaseService.fetchPeriod(id: periodID), period.isActive else {
                return
            }

            guard let session = try await makeRandomSession() else {
                print("[AppEnvironment] No prayer content available for notification launch.")
                return
            }

            ScreenOverlayManager.shared.show(
                prayer: session.prayer,
                topic: session.topic,
                theme: session.theme,
                durationMinutes: period.durationMins,
                appEnv: self
            )
        } catch {
            print("[AppEnvironment] Failed to launch session from notification: \(error)")
        }
    }

    private func makeRandomSession() async throws -> (theme: PrayerTheme, topic: PrayerTopic, prayer: Prayer)? {
        let themes = try await supabaseService.fetchThemes().shuffled()
        for theme in themes {
            let topics = try await supabaseService.fetchTopics(for: theme.id).shuffled()
            for topic in topics {
                let prayers = try await supabaseService.fetchPrayers(for: topic.id)
                if let prayer = prayerRandomizer.pickPrayer(from: prayers) {
                    return (theme: theme, topic: topic, prayer: prayer)
                }
            }
        }
        return nil
    }
}
