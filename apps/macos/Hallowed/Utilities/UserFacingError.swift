import Foundation

/// Maps network, auth, and Supabase errors into copy suitable for in-app UI.
enum UserFacingError {
    static func message(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "No internet connection. Check your network and try again."
            case .timedOut:
                return "The request timed out. Try again in a moment."
            case .cannotFindHost, .cannotConnectToHost:
                return "Could not reach the server. Check your connection."
            default:
                break
            }
        }

        let description = error.localizedDescription.lowercased()

        if description.contains("jwt") || description.contains("session") && description.contains("expired")
            || description.contains("not authenticated") || description.contains("401") {
            return "Your session expired. Sign out and sign in again."
        }

        if description.contains("42501") || description.contains("row-level security")
            || description.contains("permission denied") || description.contains("rls") {
            return "You don't have permission for this data. Sign in again or check your account."
        }

        if description.contains("invalid api key") || description.contains("apikey") {
            return "Server configuration error. Contact support if this continues."
        }

        return error.localizedDescription
    }
}
