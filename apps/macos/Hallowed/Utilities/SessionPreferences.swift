import Foundation

/// Local session UX preferences (not synced to Supabase yet).
enum SessionPreferences {
    private static let strictModeKey = "sessionStrictMode"

    static var isStrictModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: strictModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: strictModeKey) }
    }
}

/// Local automatic takeover preference (not synced to Supabase).
enum AutomaticTakeoverPreferences {
    private static let enabledKey = "automaticPrayerTakeoverEnabled"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }
}
