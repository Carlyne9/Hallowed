import Foundation
import Supabase
import Auth
import UserNotifications

@MainActor
final class AppEnvironment: ObservableObject {
    private struct NotificationLaunch {
        let periodID: UUID
    }

    // MARK: - Published State

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: Auth.User? = nil
    @Published var isLoading: Bool = true
    @Published var authCallbackError: String? = nil

    // MARK: - Services

    let supabaseService: SupabaseService
    let notificationScheduler: NotificationScheduler
    let prayerRandomizer: PrayerRandomizer
    lazy var automaticTakeoverScheduler = AutomaticTakeoverScheduler { [weak self] periodID in
        self?.handleAutomaticTakeover(periodID: periodID)
    }
    private var handledNotificationResponseKeys: Set<String> = []
    private var handledNotificationResponseKeyOrder: [String] = []
    private var pendingNotificationLaunches: [NotificationLaunch] = []
    private var notificationLaunchTask: Task<Void, Never>?
    private var notificationLaunchRevision = 0
    private var hasStartedAuthListener = false
    private var notificationScheduleRefreshTask: Task<Void, Never>?

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
                    if let userId = session?.user.id {
                        refreshNotificationSchedule(for: userId)
                        startPendingNotificationLaunchesIfNeeded()
                    } else {
                        clearNotificationSchedule()
                        clearPendingNotificationLaunches()
                    }
                case .signedIn:
                    currentUser = session?.user
                    isAuthenticated = session != nil
                    isLoading = false
                    if let userId = session?.user.id {
                        refreshNotificationSchedule(for: userId)
                        startPendingNotificationLaunchesIfNeeded()
                    } else {
                        clearNotificationSchedule()
                        clearPendingNotificationLaunches()
                    }
                case .signedOut, .userDeleted:
                    currentUser = nil
                    isAuthenticated = false
                    isLoading = false
                    clearNotificationSchedule()
                    clearPendingNotificationLaunches()
                case .tokenRefreshed, .userUpdated:
                    currentUser = session?.user
                default:
                    break
                }
            }
        }
    }

    // MARK: - Notification Scheduling

    private func refreshNotificationSchedule(for userId: UUID) {
        notificationScheduleRefreshTask?.cancel()
        notificationScheduleRefreshTask = Task {
            do {
                let periods = try await supabaseService.fetchPeriods()
                try Task.checkCancellation()

                guard currentUser?.id == userId, isAuthenticated else { return }
                applyPrayerSchedules(periods)
            } catch is CancellationError {
                return
            } catch {
                print("[AppEnvironment] Failed to refresh notification schedule: \(UserFacingError.message(for: error))")
            }
        }
    }

    private func clearNotificationSchedule() {
        notificationScheduleRefreshTask?.cancel()
        notificationScheduleRefreshTask = nil
        notificationScheduler.cancelAll()
        automaticTakeoverScheduler.cancelAll()
    }

    func applyPrayerSchedules(_ periods: [PrayerPeriod]) {
        let activePeriods = periods.filter(\.isActive)
        notificationScheduler.schedule(activePeriods)
        automaticTakeoverScheduler.schedule(activePeriods)
    }

    func setAutomaticTakeoverEnabled(_ enabled: Bool) {
        AutomaticTakeoverPreferences.isEnabled = enabled
        if enabled {
            guard let userId = currentUser?.id, isAuthenticated else { return }
            refreshNotificationSchedule(for: userId)
        } else {
            automaticTakeoverScheduler.cancelAll()
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

    private func handleAutomaticTakeover(periodID: UUID) {
        guard isAuthenticated else { return }
        guard !ScreenOverlayManager.shared.isPresentingSession else {
            print("[AppEnvironment] Ignoring automatic takeover while a prayer session is already active.")
            return
        }

        pendingNotificationLaunches.append(NotificationLaunch(periodID: periodID))
        startPendingNotificationLaunchesIfNeeded()
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        handleNotification(response.notification)
    }

    func handleNotification(_ notification: UNNotification) {
        let request = notification.request
        guard request.identifier.hasPrefix("prayer.period.") else { return }

        // Recurring notifications reuse request identifiers, so include the delivery
        // date when deduplicating a foreground delivery and a later user response.
        let responseKey = "\(request.identifier)|\(notification.date.timeIntervalSinceReferenceDate)"
        guard rememberNotificationResponseKey(responseKey) else { return }

        guard let periodIDString = request.content.userInfo["periodId"] as? String,
              let periodID = UUID(uuidString: periodIDString) else {
            print("[AppEnvironment] Ignoring prayer notification with an invalid periodId.")
            return
        }

        guard isLoading || isAuthenticated else {
            print("[AppEnvironment] Ignoring notification launch while signed out.")
            return
        }

        pendingNotificationLaunches.append(
            NotificationLaunch(periodID: periodID)
        )

        // During a cold launch, wait for the initial auth session before deciding
        // whether the notification is allowed to start a prayer session.
        guard !isLoading else { return }
        startPendingNotificationLaunchesIfNeeded()
    }

    private func rememberNotificationResponseKey(_ key: String) -> Bool {
        guard handledNotificationResponseKeys.insert(key).inserted else { return false }

        handledNotificationResponseKeyOrder.append(key)
        if handledNotificationResponseKeyOrder.count > 128 {
            let expiredKey = handledNotificationResponseKeyOrder.removeFirst()
            handledNotificationResponseKeys.remove(expiredKey)
        }
        return true
    }

    private func startPendingNotificationLaunchesIfNeeded() {
        guard isAuthenticated, notificationLaunchTask == nil, !pendingNotificationLaunches.isEmpty else {
            return
        }

        notificationLaunchRevision += 1
        let revision = notificationLaunchRevision
        notificationLaunchTask = Task {
            while !Task.isCancelled, isAuthenticated, !pendingNotificationLaunches.isEmpty {
                let launch = pendingNotificationLaunches.removeFirst()

                guard !ScreenOverlayManager.shared.isPresentingSession else {
                    print("[AppEnvironment] Ignoring notification launch while a prayer session is already active.")
                    continue
                }

                await launchSessionFromPeriod(periodID: launch.periodID)
            }
            if revision == notificationLaunchRevision {
                notificationLaunchTask = nil
            }
        }
    }

    private func clearPendingNotificationLaunches() {
        notificationLaunchRevision += 1
        notificationLaunchTask?.cancel()
        notificationLaunchTask = nil
        pendingNotificationLaunches.removeAll()
    }

    private func launchSessionFromPeriod(periodID: UUID) async {
        guard let userID = currentUser?.id, isAuthenticated else { return }

        do {
            guard let period = try await supabaseService.fetchPeriod(id: periodID), period.isActive else {
                print("[AppEnvironment] Ignoring notification for a missing or inactive prayer period.")
                return
            }

            try Task.checkCancellation()
            guard currentUser?.id == userID, isAuthenticated else { return }

            guard let session = try await makeSession(for: period) else {
                print("[AppEnvironment] No prayer content available for notification launch.")
                return
            }

            try Task.checkCancellation()
            guard currentUser?.id == userID, isAuthenticated else { return }
            guard !ScreenOverlayManager.shared.isPresentingSession else {
                print("[AppEnvironment] Ignoring notification launch while a prayer session is already active.")
                return
            }

            ScreenOverlayManager.shared.show(
                prayer: session.prayer,
                topic: session.topic,
                theme: session.theme,
                durationMinutes: period.durationMins,
                periodId: period.id,
                shouldLogContentIDs: session.shouldLogContentIDs,
                appEnv: self
            )
        } catch is CancellationError {
            return
        } catch {
            print("[AppEnvironment] Failed to launch session from notification: \(UserFacingError.message(for: error))")
        }
    }

    private func makeSession(
        for period: PrayerPeriod
    ) async throws -> (theme: PrayerTheme, topic: PrayerTopic, prayer: Prayer, shouldLogContentIDs: Bool)? {
        if let customTopics = period.customTopics, !customTopics.isEmpty {
            return makeCustomSession(period: period, topics: customTopics)
        }

        if period.themeId == nil, period.customTopics == nil {
            return makeOpenPrayerSession(period: period)
        }

        return try await makeRandomSession(themeId: period.themeId).map {
            (theme: $0.theme, topic: $0.topic, prayer: $0.prayer, shouldLogContentIDs: true)
        }
    }

    private func makeRandomSession(
        themeId: UUID? = nil
    ) async throws -> (theme: PrayerTheme, topic: PrayerTopic, prayer: Prayer)? {
        let themes = try await supabaseService.fetchThemes().shuffled()
        let candidateThemes = themeId.flatMap { id in themes.first { $0.id == id } }.map { [$0] } ?? themes

        for theme in candidateThemes {
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

    private func makeOpenPrayerSession(
        period: PrayerPeriod
    ) -> (theme: PrayerTheme, topic: PrayerTopic, prayer: Prayer, shouldLogContentIDs: Bool) {
        let topicTitle = period.title
        let theme = PrayerTheme(
            id: UUID(),
            name: "Open Prayer",
            icon: "hands.sparkles.fill",
            colorHex: "C49A6C",
            sortOrder: 0
        )
        let topic = PrayerTopic(
            id: UUID(),
            themeId: theme.id,
            title: topicTitle,
            description: "A prayer period without assigned prayer points.",
            tags: [],
            sortOrder: 0
        )
        let prayer = Prayer(
            id: UUID(),
            topicId: topic.id,
            title: topicTitle,
            body: "Settle your heart before God.\nPray as the Spirit leads.\nUse this time for worship, listening, confession, intercession, or quiet surrender.",
            author: nil,
            isClassic: false
        )
        return (theme, topic, prayer, false)
    }

    private func makeCustomSession(
        period: PrayerPeriod,
        topics: [String]
    ) -> (theme: PrayerTheme, topic: PrayerTopic, prayer: Prayer, shouldLogContentIDs: Bool) {
        let theme = PrayerTheme(
            id: UUID(),
            name: "Prayer Focus",
            icon: "target",
            colorHex: "C49A6C",
            sortOrder: 0
        )
        let topic = PrayerTopic(
            id: UUID(),
            themeId: theme.id,
            title: period.title,
            description: topics.joined(separator: ", "),
            tags: topics,
            sortOrder: 0
        )
        let prayer = Prayer(
            id: UUID(),
            topicId: topic.id,
            title: period.title,
            body: topics.map { "Pray over \($0)." }.joined(separator: "\n"),
            author: nil,
            isClassic: false
        )
        return (theme, topic, prayer, false)
    }
}
