import Foundation

struct PrayerPeriod: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let label: String?
    let scheduledDate: String?
    let timeOfDay: String
    let durationMins: Int
    let repeatType: RepeatType?
    let customDays: [Int]?
    let themeId: UUID?
    let customTopics: [String]?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case label
        case scheduledDate = "scheduled_date"
        case timeOfDay = "time_of_day"
        case durationMins = "duration_mins"
        case repeatType = "repeat"
        case customDays = "custom_days"
        case themeId = "theme_id"
        case customTopics = "custom_topics"
        case isActive = "is_active"
    }

    enum RepeatType: String, Codable, CaseIterable {
        case daily, weekdays, weekends, custom

        var displayName: String {
            switch self {
            case .daily: return "Every day"
            case .weekdays: return "Weekdays"
            case .weekends: return "Weekends"
            case .custom: return "Custom"
            }
        }
    }

    var isOneTime: Bool {
        scheduledDate != nil
    }

    var title: String {
        label ?? "Prayer Period"
    }

    var repeatSummary: String {
        if let scheduledDate, let date = Self.dateFormatter.date(from: scheduledDate) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }

        switch repeatType {
        case .daily?:
            return "Every day"
        case .weekdays?:
            return "Weekdays"
        case .weekends?:
            return "Weekends"
        case .custom?:
            let labels = [
                "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat",
            ]
            let days = (customDays ?? [])
                .sorted()
                .compactMap { labels.indices.contains($0) ? labels[$0] : nil }
            return days.isEmpty ? "Custom" : days.joined(separator: ", ")
        case nil:
            return "One time"
        }
    }

    var focusSummary: String {
        if let customTopics, !customTopics.isEmpty {
            return customTopics.joined(separator: ", ")
        }
        if themeId != nil {
            return "Theme focus"
        }
        return "Open prayer"
    }

    var displayTime: String {
        let parts = timeOfDay.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return timeOfDay }
        var comps = DateComponents()
        comps.hour = parts[0]
        comps.minute = parts[1]
        let date = Calendar.current.date(from: comps) ?? Date()
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return fmt.string(from: date)
    }

    var timeComponents: DateComponents {
        let parts = timeOfDay.split(separator: ":").compactMap { Int($0) }
        return DateComponents(hour: parts.first ?? 6, minute: parts.count > 1 ? parts[1] : 0)
    }

    var scheduledDateValue: Date? {
        guard let scheduledDate else { return nil }
        return Self.dateFormatter.date(from: scheduledDate)
    }

    static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
