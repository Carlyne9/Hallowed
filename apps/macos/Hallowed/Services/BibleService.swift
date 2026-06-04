import Foundation

// Scripture strategy: api.bible (preferred translation) when API_BIBLE_KEY is set;
// bible-api.com fallback only if api.bible fails. See docs/SCRIPTURE_STRATEGY.md.
actor BibleService {
    static let shared = BibleService()

    private var cache: [String: String] = [:]
    private let apiBibleBaseURL = "https://api.scripture.api.bible/v1"
    private let fallbackBaseURL = "https://bible-api.com"

    private init() {}

    func verseText(for scripture: Scripture, translationCode: String = "NIV") async -> String? {
        let normalizedTranslation = normalizedTranslationCode(translationCode)
        let key = "\(normalizedTranslation)::\(scripture.passageId)"
        if let cached = cache[key] { return cached }

        if let apiBibleText = await fetchFromAPIBible(scripture: scripture, translationCode: normalizedTranslation) {
            let cleaned = clean(apiBibleText)
            if !cleaned.isEmpty {
                cache[key] = cleaned
                return cleaned
            }
        }

        if let fallbackText = await fetchFromFallback(scripture: scripture, translationCode: normalizedTranslation) {
            let cleaned = clean(fallbackText)
            if !cleaned.isEmpty {
                cache[key] = cleaned
                return cleaned
            }
        }

        return nil
    }

    private func fetchFromAPIBible(scripture: Scripture, translationCode: String) async -> String? {
        guard let apiKey = Config.apiBibleKey,
              let bibleID = bibleID(for: translationCode)
        else { return nil }

        var components = URLComponents(string: "\(apiBibleBaseURL)/bibles/\(bibleID)/passages/\(scripture.passageId)")
        components?.queryItems = [
            URLQueryItem(name: "content-type", value: "text"),
            URLQueryItem(name: "include-notes", value: "false"),
            URLQueryItem(name: "include-titles", value: "false"),
            URLQueryItem(name: "include-chapter-numbers", value: "false"),
            URLQueryItem(name: "include-verse-numbers", value: "false")
        ]

        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let decoded = try? JSONDecoder().decode(APIBiblePassageResponse.self, from: data)
        else { return nil }

        return decoded.data.content
    }

    private func fetchFromFallback(scripture: Scripture, translationCode: String) async -> String? {
        let ref = buildFallbackReference(scripture)
        guard let encoded = ref.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }

        var components = URLComponents(string: "\(fallbackBaseURL)/\(encoded)")
        if let translation = fallbackTranslationQuery(translationCode) {
            components?.queryItems = [URLQueryItem(name: "translation", value: translation)]
        }
        guard let url = components?.url else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String
        else { return nil }

        return text
    }

    private func clean(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .replacingOccurrences(of: "Selah.", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func bibleID(for translationCode: String) -> String? {
        switch translationCode {
        case "NIV":
            return "78a9f6124f344018-01"
        case "KJV":
            return "de4e12af7f28f599-02"
        case "ESV":
            return "f421fe261da7624f-01"
        case "NLT":
            return "65eec8e0b60e656b-01"
        case "MSG":
            return "65eec8e0b60e656b-02"
        default:
            return nil
        }
    }

    private func normalizedTranslationCode(_ code: String) -> String {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch normalized {
        case "NIV", "KJV", "ESV", "NLT", "MSG":
            return normalized
        default:
            return "NIV"
        }
    }

    private func fallbackTranslationQuery(_ code: String) -> String? {
        switch code {
        case "KJV": return "kjv"
        default: return nil
        }
    }

    private func buildFallbackReference(_ scripture: Scripture) -> String {
        let book = scripture.book.lowercased().replacingOccurrences(of: " ", with: "+")
        let chapter = scripture.chapter
        let start = scripture.verseStart
        if let end = scripture.verseEnd {
            return "\(book)+\(chapter):\(start)-\(end)"
        }
        return "\(book)+\(chapter):\(start)"
    }
}

private struct APIBiblePassageResponse: Decodable {
    struct Payload: Decodable {
        let content: String
    }
    let data: Payload
}
