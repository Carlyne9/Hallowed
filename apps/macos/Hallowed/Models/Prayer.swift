import Foundation

struct Prayer: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let topicId: UUID
    let title: String
    let body: String
    let author: String?
    let isClassic: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case topicId = "topic_id"
        case title
        case body
        case author
        case isClassic = "is_classic"
    }

    // Convenience: split body into array of bullet strings
    var bullets: [String] { body.components(separatedBy: "\n").filter { !$0.isEmpty } }
}
