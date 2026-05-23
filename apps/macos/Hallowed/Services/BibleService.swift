import Foundation

// Fetches verse text from bible-api.com (World English Bible, public domain, no key required).
actor BibleService {
    static let shared = BibleService()

    private var cache: [String: String] = [:]
    private let baseURL = "https://bible-api.com"

    private init() {}

    func verseText(for scripture: Scripture) async -> String? {
        let key = scripture.passageId
        if let cached = cache[key] { return cached }

        let ref = buildReference(scripture)
        guard let encoded = ref.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/\(encoded)")
        else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String
        else { return nil }

        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .replacingOccurrences(of: "Selah.", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        cache[key] = cleaned
        return cleaned
    }

    private func buildReference(_ scripture: Scripture) -> String {
        let book = scripture.book.lowercased().replacingOccurrences(of: " ", with: "+")
        let chapter = scripture.chapter
        let start = scripture.verseStart
        if let end = scripture.verseEnd {
            return "\(book)+\(chapter):\(start)-\(end)"
        }
        return "\(book)+\(chapter):\(start)"
    }
}
