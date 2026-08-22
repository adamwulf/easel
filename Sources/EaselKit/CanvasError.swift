import Foundation

/// All errors thrown by EaselKit.
public enum CanvasError: Error, Sendable, Equatable {
    case missingAPIKey
    case missingHost
    case invalidHost(String)
    case invalidURL(String)
    case invalidResponse
    case transport(message: String)
    case unauthorized(message: String?)
    case notFound(message: String?)
    case http(status: Int, message: String?)
    case decoding(type: String, message: String)
}

extension CanvasError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No Canvas API key found. Set \(CanvasConfig.apiKeyName) in the environment "
                + "or in a .env file in this directory or a parent directory."
        case .missingHost:
            return "No Canvas host found. Pass --host, or set \(CanvasConfig.hostKeyName) in the "
                + "environment or in a .env file in this directory or a parent directory."
        case .invalidHost(let host):
            return "The Canvas host \"\(host)\" is not a valid host."
        case .invalidURL(let path):
            return "Could not build a request URL for \"\(path)\"."
        case .invalidResponse:
            return "The server returned a response that is not HTTP."
        case .transport(let message):
            return "Network request failed: \(message)"
        case .unauthorized(let message):
            return "Canvas rejected the API key (401): \(message ?? "no details")"
        case .notFound(let message):
            return "Canvas resource not found (404): \(message ?? "no details")"
        case .http(let status, let message):
            return "Canvas returned HTTP \(status): \(message ?? "no details")"
        case .decoding(let type, let message):
            return "Could not decode \(type) from the Canvas response: \(message)"
        }
    }
}
