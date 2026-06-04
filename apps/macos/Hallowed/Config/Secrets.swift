import Foundation

enum Config {
    static let supabaseURL = required("SUPABASE_URL")
    static let supabaseAnonKey = required("SUPABASE_ANON_KEY")
    static let googleWebClientID = required("GOOGLE_WEB_CLIENT_ID")
    static let googleMacOSClientID = required("GOOGLE_MACOS_CLIENT_ID")
    static let apiBibleKey = optional("API_BIBLE_KEY")

    static var authCallbackURL: URL {
        guard let bundleId = Bundle.main.bundleIdentifier,
              let url = URL(string: "\(bundleId)://auth/callback") else {
            fatalError("Missing bundle identifier for auth callback URL.")
        }

        return url
    }

    private static func required(_ key: String) -> String {
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = plistValue.trimmingCharacters(in: .whitespacesAndNewlines)
            // Treat unresolved build placeholders like "$(SUPABASE_URL)" as missing.
            if !trimmed.isEmpty && !trimmed.contains("$(") {
                return trimmed
            }
        }

        if let envValue = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !envValue.isEmpty {
            return envValue
        }

        if isRunningInPreviews {
            switch key {
            case "SUPABASE_URL":
                return "https://preview.invalid"
            case "SUPABASE_ANON_KEY":
                return "preview-anon-key"
            case "GOOGLE_WEB_CLIENT_ID":
                return "preview-web-client-id"
            case "GOOGLE_MACOS_CLIENT_ID":
                return "preview-macos-client-id"
            default:
                break
            }
        }

        fatalError("Missing \(key) in Info.plist. Configure it via Secrets.xcconfig.")
    }

    private static func optional(_ key: String) -> String? {
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = plistValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.contains("$(") {
                return trimmed
            }
        }

        if let envValue = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !envValue.isEmpty {
            return envValue
        }

        return nil
    }

    private static var isRunningInPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
