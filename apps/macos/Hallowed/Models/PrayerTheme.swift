import Foundation

struct PrayerTheme: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let description: String? = nil
    let icon: String
    let colorHex: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case icon
        case colorHex = "color_hex"
        case sortOrder = "sort_order"
    }
}
