import AppKit
import Foundation

/// Fires prayer periods directly while Hallowed is running.
/// System notifications remain the fallback when the app is not available.
@MainActor
final class AutomaticTakeoverScheduler {
    private let onPeriodDue: (UUID) -> Void
    private var periods: [PrayerPeriod] = []
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    init(onPeriodDue: @escaping (UUID) -> Void) {
        self.onPeriodDue = onPeriodDue
        installObservers()
    }

    func schedule(_ periods: [PrayerPeriod]) {
        self.periods = periods.filter(\.isActive)
        reschedule()
    }

    func cancelAll() {
        periods.removeAll()
        timer?.invalidate()
        timer = nil
    }

    private func reschedule() {
        timer?.invalidate()
        timer = nil

        guard AutomaticTakeoverPreferences.isEnabled else { return }
        guard let next = nextPeriod(after: Date()) else { return }

        let timer = Timer(fire: next.date, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.onPeriodDue(next.period.id)
                self.reschedule()
            }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func nextPeriod(after date: Date) -> (period: PrayerPeriod, date: Date)? {
        periods
            .compactMap { period in
                nextOccurrence(of: period, after: date).map { (period, $0) }
            }
            .min { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.id.uuidString < rhs.0.id.uuidString
                }
                return lhs.1 < rhs.1
            }
    }

    private func nextOccurrence(of period: PrayerPeriod, after date: Date) -> Date? {
        let calendar = Calendar.current
        let hour = period.timeComponents.hour ?? 6
        let minute = period.timeComponents.minute ?? 0

        if let scheduledDate = period.scheduledDateValue {
            let startOfScheduledDay = calendar.startOfDay(for: scheduledDate)
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfScheduledDay)
                .flatMap { $0 > date ? $0 : nil }
        }

        let startOfToday = calendar.startOfDay(for: date)
        let allowedWeekdays = weekdays(for: period)

        for dayOffset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday),
                  allowedWeekdays.contains(calendar.component(.weekday, from: day)),
                  let candidate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  candidate > date else {
                continue
            }
            return candidate
        }
        return nil
    }

    private func weekdays(for period: PrayerPeriod) -> Set<Int> {
        switch period.repeatType {
        case .daily?:
            return Set(1...7)
        case .weekdays?:
            return Set(2...6)
        case .weekends?:
            return [1, 7]
        case .custom?:
            return Set((period.customDays ?? []).map { $0 + 1 })
        case nil:
            return []
        }
    }

    private func installObservers() {
        let center = NotificationCenter.default
        let workspaceCenter = NSWorkspace.shared.notificationCenter

        observers.append(
            center.addObserver(
                forName: .NSSystemClockDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reschedule()
            }
        )
        observers.append(
            center.addObserver(
                forName: .NSCalendarDayChanged,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reschedule()
            }
        )
        observers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reschedule()
            }
        )
    }
}
