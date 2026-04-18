import Foundation

enum SbError: LocalizedError {
    case network(String)
    case authFailed
    case serverError(String)
    case notFound
    case configMissing(String)

    var errorDescription: String? {
        switch self {
        case .network(let msg): "Network error: \(msg)"
        case .authFailed: "Authentication failed"
        case .serverError(let msg): "Server error: \(msg)"
        case .notFound: "Not found"
        case .configMissing(let msg): "Configuration missing: \(msg)"
        }
    }
}