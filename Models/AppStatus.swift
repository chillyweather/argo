import SwiftUI

enum AppStatus: String, CaseIterable {
    case ready = "Ready"
    case saving = "Saving"
    case saved = "Saved"
    case offline = "Offline"
    case authError = "Auth Error"
    case serverError = "Server Error"
    case configMissing = "Config Missing"

    var color: Color {
        switch self {
        case .offline, .authError, .serverError, .configMissing:
            return .red.opacity(0.7)
        default:
            return .clear
        }
    }

    var text: String {
        switch self {
        case .ready: "Ready"
        case .saving: "Saving..."
        case .saved: "Saved"
        case .offline: "Offline"
        case .authError: "Auth Failed"
        case .serverError: "Server Error"
        case .configMissing: "Config Missing"
        }
    }

    static func parse(error: String) -> AppStatus {
        if error.contains("Network error") { return .offline }
        if error.contains("Auth") || error.contains("Unauthorized") { return .authError }
        if error.contains("Configuration missing") { return .configMissing }
        return .serverError
    }
}