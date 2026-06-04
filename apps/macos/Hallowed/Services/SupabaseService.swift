import Supabase
import Foundation

@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    // MARK: - Auth

    func signInWithGoogle() async throws {
        try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: Config.authCallbackURL
        )
    }

    func signInWithMagicLink(email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: Config.authCallbackURL
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        client.auth.authStateChanges
    }

    // MARK: - Content Fetch

    func fetchThemes() async throws -> [PrayerTheme] {
        try await client
            .from("prayer_themes")
            .select()
            .order("sort_order")
            .execute()
            .value
    }

    func fetchTopics(for themeId: UUID) async throws -> [PrayerTopic] {
        try await client
            .from("prayer_topics")
            .select()
            .eq("theme_id", value: themeId.uuidString)
            .order("sort_order")
            .execute()
            .value
    }

    func fetchPrayers(for topicId: UUID) async throws -> [Prayer] {
        try await client
            .from("prayers")
            .select()
            .eq("topic_id", value: topicId.uuidString)
            .order("created_at")
            .execute()
            .value
    }

    /// Fetches scriptures for multiple prayers, keyed by prayer ID.
    /// Queries `prayer_scripture_links` joined with `scriptures`.
    func fetchScriptures(for prayerIds: [UUID]) async throws -> [UUID: [Scripture]] {
        struct PrayerScriptureLink: Decodable {
            let prayer_id: UUID
            let scriptures: Scripture
        }

        let links: [PrayerScriptureLink] = try await client
            .from("prayer_scripture_links")
            .select("prayer_id, scriptures(*)")
            .in("prayer_id", values: prayerIds.map(\.uuidString))
            .execute()
            .value

        var result: [UUID: [Scripture]] = [:]
        for link in links {
            result[link.prayer_id, default: []].append(link.scriptures)
        }
        return result
    }

    // MARK: - User Data

    func fetchPeriods() async throws -> [PrayerPeriod] {
        try await client
            .from("prayer_periods")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchPeriod(id: UUID) async throws -> PrayerPeriod? {
        let periods: [PrayerPeriod] = try await client
            .from("prayer_periods")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return periods.first
    }

    func savePeriod(_ period: PrayerPeriod) async throws {
        try await client
            .from("prayer_periods")
            .upsert(period)
            .execute()
    }

    func deletePeriod(id: UUID) async throws {
        try await client
            .from("prayer_periods")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func logSession(_ session: PrayerSession) async throws {
        try await client
            .from("prayer_sessions")
            .insert(session)
            .execute()
    }

    func fetchRecentSessions(limit: Int) async throws -> [PrayerSession] {
        try await client
            .from("prayer_sessions")
            .select()
            .order("started_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func fetchPrayers(ids: [UUID]) async throws -> [Prayer] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("prayers")
            .select()
            .in("id", values: ids.map(\.uuidString))
            .execute()
            .value
    }

    func fetchTopics(ids: [UUID]) async throws -> [PrayerTopic] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("prayer_topics")
            .select()
            .in("id", values: ids.map(\.uuidString))
            .execute()
            .value
    }

    func fetchPreferredTranslation(for userId: UUID) async -> String {
        struct ProfileRow: Decodable {
            let preferred_translation: String?
        }

        do {
            let rows: [ProfileRow] = try await client
                .from("profiles")
                .select("preferred_translation")
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            return normalizedTranslationCode(rows.first?.preferred_translation)
        } catch {
            return "NIV"
        }
    }

    func updatePreferredTranslation(_ code: String, for userId: UUID) async throws {
        struct ProfileUpdate: Encodable {
            let id: UUID
            let preferred_translation: String
        }

        let normalized = normalizedTranslationCode(code)
        let payload = ProfileUpdate(id: userId, preferred_translation: normalized)

        try await client
            .from("profiles")
            .upsert(payload)
            .execute()
    }

    private func normalizedTranslationCode(_ code: String?) -> String {
        let normalized = code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        switch normalized {
        case "NIV", "KJV", "ESV", "NLT", "MSG":
            return normalized
        default:
            return "NIV"
        }
    }
}
