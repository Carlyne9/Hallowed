import Foundation

struct PrayerSession: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let periodId: UUID?
    let prayerId: UUID?
    let topicId: UUID?
    let startedAt: Date
    let endedAt: Date?
    let durationS: Int?
    let status: SessionStatus
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case periodId = "period_id"
        case prayerId = "prayer_id"
        case topicId = "topic_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationS = "duration_s"
        case status
        case notes
    }

    enum SessionStatus: String, Codable {
        case completed, skipped, partial
    }
}

// New session builder
extension PrayerSession {
    static func new(
        userId: UUID,
        periodId: UUID?,
        prayerId: UUID?,
        topicId: UUID?,
        startedAt: Date = Date()
    ) -> PrayerSession {
        PrayerSession(
            id: UUID(),
            userId: userId,
            periodId: periodId,
            prayerId: prayerId,
            topicId: topicId,
            startedAt: startedAt,
            endedAt: nil,
            durationS: nil,
            status: .partial,
            notes: nil
        )
    }
}
