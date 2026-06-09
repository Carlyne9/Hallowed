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
        if let scheduledDate = period.scheduledDateValue {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: scheduledDate)
            components.hour = period.timeComponents.hour
            components.minute = period.timeComponents.minute

            guard let scheduledDateTime = Calendar.current.date(from: components),
                  scheduledDateTime > Date() else {
                return []
            }

            var requests = [
                request(
                    id: "prayer.period.\(period.id.uuidString).once.start",
                    period: period,
                    components: components,
                    repeats: false,
                    kind: .start
                ),
            ]

            if let reminderDate = Calendar.current.date(byAdding: .minute, value: -5, to: scheduledDateTime),
               reminderDate > Date() {
                let reminderComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                requests.append(
                    request(
                        id: "prayer.period.\(period.id.uuidString).once.reminder",
                        period: period,
                        components: reminderComponents,
                        repeats: false,
                        kind: .reminder
                    )
                )
            }

            return requests
        }

        switch period.repeatType {
        case .daily?:
            return repeatingRequests(
                idBase: "prayer.period.\(period.id.uuidString).daily",
                period: period,
                components: period.timeComponents
            )

        case .weekdays?:
            return (2...6).flatMap { weekday in
                var components = period.timeComponents
                components.weekday = weekday
                return repeatingRequests(
                    idBase: "prayer.period.\(period.id.uuidString).wd\(weekday)",
                    period: period,
                    components: components
                )
            }

        case .weekends?:
            return [1, 7].flatMap { weekday in
                var components = period.timeComponents
                components.weekday = weekday
                return repeatingRequests(
                    idBase: "prayer.period.\(period.id.uuidString).wd\(weekday)",
                    period: period,
                    components: components
                )
            }

        case .custom?:
            // customDays uses 0=Sunday convention; UNCalendarNotificationTrigger uses weekday 1=Sunday
            return (period.customDays ?? []).flatMap { day in
                let weekday = day + 1
                var components = period.timeComponents
                components.weekday = weekday
                return repeatingRequests(
                    idBase: "prayer.period.\(period.id.uuidString).wd\(weekday)",
                    period: period,
                    components: components
                )
            }
        case nil:
            return []
        }
    }

    private enum NotificationKind {
        case reminder
        case start
    }

    private func repeatingRequests(
        idBase: String,
        period: PrayerPeriod,
        components: DateComponents
    ) -> [UNNotificationRequest] {
        [
            request(
                id: "\(idBase).reminder",
                period: period,
                components: reminderComponents(from: components),
                repeats: true,
                kind: .reminder
            ),
            request(
                id: "\(idBase).start",
                period: period,
                components: components,
                repeats: true,
                kind: .start
            ),
        ]
    }

    private func request(
        id: String,
        period: PrayerPeriod,
        components: DateComponents,
        repeats: Bool,
        kind: NotificationKind
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = kind == .reminder ? "\(period.title) starts soon" : period.title
        content.body = kind == .reminder ? reminderBody(for: period) : notificationBody(for: period)
        content.sound = .default
        content.userInfo = ["periodId": period.id.uuidString]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    private func reminderComponents(from components: DateComponents) -> DateComponents {
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let originalMinutes = hour * 60 + minute
        let totalMinutes = (originalMinutes - 5 + 24 * 60) % (24 * 60)

        var reminder = components
        reminder.hour = totalMinutes / 60
        reminder.minute = totalMinutes % 60
        if originalMinutes < 5, let weekday = reminder.weekday {
            reminder.weekday = weekday == 1 ? 7 : weekday - 1
        }
        return reminder
    }

    private func reminderBody(for period: PrayerPeriod) -> String {
        "Your \(period.durationMins) minute prayer time begins in 5 minutes."
    }

    private func notificationBody(for period: PrayerPeriod) -> String {
        if let topics = period.customTopics, !topics.isEmpty {
            return "\(period.durationMins) minutes to pray: \(topics.joined(separator: ", "))."
        }
        return "Your \(period.durationMins) minute prayer time is ready."
    }
}
