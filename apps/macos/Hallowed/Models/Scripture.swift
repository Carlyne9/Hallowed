import Foundation

struct Scripture: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let book: String
    let bookCode: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int?
    let reference: String

    enum CodingKeys: String, CodingKey {
        case id
        case book
        case bookCode = "book_code"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case reference
    }

    // api.bible passage identifier, e.g. "PSA.4.4" or "EPH.4.26-EPH.4.27"
    var passageId: String {
        let base = "\(bookCode).\(chapter).\(verseStart)"
        if let end = verseEnd { return "\(base)-\(bookCode).\(chapter).\(end)" }
        return base
    }
}
