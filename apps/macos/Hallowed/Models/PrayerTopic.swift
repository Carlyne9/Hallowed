import Foundation

struct PrayerTopic: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let themeId: UUID
    let title: String
    let description: String?
    let tags: [String]
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case themeId = "theme_id"
        case title
        case description
        case tags
        case sortOrder = "sort_order"
    }
}
