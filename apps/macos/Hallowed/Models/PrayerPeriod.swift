import Foundation

struct PrayerPeriod: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let label: String?
    let timeOfDay: String
    let durationMins: Int
    let repeatType: RepeatType
    let customDays: [Int]?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case label
        case timeOfDay = "time_of_day"
        case durationMins = "duration_mins"
        case repeatType = "repeat"
        case customDays = "custom_days"
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

    // Convenience
    var displayTime: String {
        // Parse "HH:mm:ss" and format as "6:00 AM"
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
}
