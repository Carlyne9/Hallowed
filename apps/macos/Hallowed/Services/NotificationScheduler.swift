import UserNotifications
import Foundation

@MainActor
class NotificationScheduler {
    private var scheduleRevision = 0
    private var schedulingTask: Task<Void, Never>?

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    func schedule(_ periods: [PrayerPeriod]) {
        scheduleRevision += 1
        let revision = scheduleRevision
        let center = UNUserNotificationCenter.current()
        let previousTask = schedulingTask
        previousTask?.cancel()

        schedulingTask = Task {
            await previousTask?.value
            guard !Task.isCancelled, revision == scheduleRevision else { return }

            // Remove all existing prayer period notifications before rescheduling.
            let requests = await center.pendingNotificationRequests()
            guard !Task.isCancelled, revision == scheduleRevision else { return }

            let prayerPeriodIds = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("prayer.period.") }
            center.removePendingNotificationRequests(withIdentifiers: prayerPeriodIds)

            guard !Task.isCancelled, revision == scheduleRevision else { return }

            // Schedule new notifications for each active period.
            for period in periods {
                for request in makeRequests(for: period) {
                    guard !Task.isCancelled, revision == scheduleRevision else { return }
                    do {
                        try await center.add(request)
                    } catch {
                        print("[NotificationScheduler] Failed to schedule \(request.identifier): \(error)")
                    }
                }
            }
        }
    }

    func cancelAll() {
        scheduleRevision += 1
        let revision = scheduleRevision
        let center = UNUserNotificationCenter.current()
        let previousTask = schedulingTask
        previousTask?.cancel()

        schedulingTask = Task {
            await previousTask?.value
            guard !Task.isCancelled, revision == scheduleRevision else { return }

            let requests = await center.pendingNotificationRequests()
            guard !Task.isCancelled, revision == scheduleRevision else { return }

            let prayerPeriodIds = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("prayer.period.") }
            center.removePendingNotificationRequests(withIdentifiers: prayerPeriodIds)
        }
    }

    // MARK: - Private Helpers

    private func makeRequests(for period: PrayerPeriod) -> [UNNotificationRequest] {
        let content = UNMutableNotificationContent()
        content.title = period.title
        content.body = notificationBody(for: period)
        content.sound = .default
        content.userInfo = ["periodId": period.id.uuidString]

        if let scheduledDate = period.scheduledDateValue {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: scheduledDate)
            components.hour = period.timeComponents.hour
            components.minute = period.timeComponents.minute

            guard let scheduledDateTime = Calendar.current.date(from: components),
                  scheduledDateTime > Date() else {
                return []
            }

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "prayer.period.\(period.id.uuidString).once"
            return [UNNotificationRequest(identifier: id, content: content, trigger: trigger)]
        }

        switch period.repeatType {
        case .daily?:
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: period.timeComponents,
                repeats: true
            )
            let id = "prayer.period.\(period.id.uuidString)"
            return [UNNotificationRequest(identifier: id, content: content, trigger: trigger)]

        case .weekdays?:
            return (2...6).map { weekday in
                var components = period.timeComponents
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "prayer.period.\(period.id.uuidString).wd\(weekday)"
                return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            }

        case .weekends?:
            return [1, 7].map { weekday in
                var components = period.timeComponents
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "prayer.period.\(period.id.uuidString).wd\(weekday)"
                return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            }

        case .custom?:
            // customDays uses 0=Sunday convention; UNCalendarNotificationTrigger uses weekday 1=Sunday
            return (period.customDays ?? []).map { day in
                let weekday = day + 1
                var components = period.timeComponents
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "prayer.period.\(period.id.uuidString).wd\(weekday)"
                return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            }
        case nil:
            return []
        }
    }

    private func notificationBody(for period: PrayerPeriod) -> String {
        if let topics = period.customTopics, !topics.isEmpty {
            return "\(period.durationMins) minutes to pray: \(topics.joined(separator: ", "))."
        }
        return "Your \(period.durationMins) minute prayer time is ready."
    }
}
