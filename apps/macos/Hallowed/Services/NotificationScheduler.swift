import UserNotifications
import Foundation

class NotificationScheduler {

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
        let center = UNUserNotificationCenter.current()

        // Remove all existing prayer period notifications before rescheduling
        center.getPendingNotificationRequests { requests in
            let prayerPeriodIds = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("prayer.period.") }
            center.removePendingNotificationRequests(withIdentifiers: prayerPeriodIds)

            // Schedule new notifications for each active period
            for period in periods {
                let requests = self.makeRequests(for: period)
                for request in requests {
                    center.add(request) { error in
                        if let error {
                            print("[NotificationScheduler] Failed to schedule \(request.identifier): \(error)")
                        }
                    }
                }
            }
        }
    }

    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let prayerPeriodIds = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("prayer.period.") }
            center.removePendingNotificationRequests(withIdentifiers: prayerPeriodIds)
        }
    }

    // MARK: - Private Helpers

    private func makeRequests(for period: PrayerPeriod) -> [UNNotificationRequest] {
        let content = UNMutableNotificationContent()
        content.title = period.label ?? "Time to Pray"
        content.body = "Your \(period.durationMins) minute prayer period is ready."
        content.sound = .default
        content.userInfo = ["periodId": period.id.uuidString]

        switch period.repeatType {
        case .daily:
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: period.timeComponents,
                repeats: true
            )
            let id = "prayer.period.\(period.id.uuidString)"
            return [UNNotificationRequest(identifier: id, content: content, trigger: trigger)]

        case .weekdays:
            return (2...6).map { weekday in
                var components = period.timeComponents
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "prayer.period.\(period.id.uuidString).wd\(weekday)"
                return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            }

        case .weekends:
            return [1, 7].map { weekday in
                var components = period.timeComponents
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "prayer.period.\(period.id.uuidString).wd\(weekday)"
                return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            }

        case .custom:
            // customDays uses 0=Sunday convention; UNCalendarNotificationTrigger uses weekday 1=Sunday
            return (period.customDays ?? []).map { day in
                let weekday = day + 1
                var components = period.timeComponents
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "prayer.period.\(period.id.uuidString).wd\(weekday)"
                return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            }
        }
    }
}
