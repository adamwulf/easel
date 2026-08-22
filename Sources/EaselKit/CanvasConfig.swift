import Foundation

/// The two values every Canvas call needs: which instance to talk to and the
/// access token to use. Resolution order for each value: explicit argument,
/// then process environment, then the nearest `.env` file (walking up from the
/// current directory).
public struct CanvasConfig: Sendable, Equatable {
    public static let apiKeyName = "CANVAS_API_KEY"
    public static let hostKeyName = "CANVAS_HOST"

    /// The instance root, like `https://school.instructure.com`.
    public let baseURL: URL
    public let token: String

    public init(baseURL: URL, token: String) {
        self.baseURL = baseURL
        self.token = token
    }

    public var apiBaseURL: URL {
        baseURL.appendingPathComponent("api/v1")
    }

    public static func resolve(
        host: String? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        startingIn directory: URL? = nil
    ) throws -> CanvasConfig {
        guard let token = value(forKey: apiKeyName, environment: environment, startingIn: directory) else {
            throw CanvasError.missingAPIKey
        }
        guard let rawHost = host ?? value(forKey: hostKeyName, environment: environment, startingIn: directory) else {
            throw CanvasError.missingHost
        }
        return CanvasConfig(baseURL: try normalizeHost(rawHost), token: token)
    }

    static func value(forKey key: String, environment: [String: String], startingIn directory: URL?) -> String? {
        if let value = environment[key], !value.isEmpty {
            return value
        }
        return DotEnv.loadValue(forKey: key, startingIn: directory)
    }

    /// Accepts `school.instructure.com` or a full `https://school.instructure.com`
    /// URL and normalizes to a scheme-qualified base URL without a trailing slash.
    static func normalizeHost(_ raw: String) throws -> URL {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") {
            trimmed = String(trimmed.dropLast())
        }
        if !trimmed.contains("://") {
            trimmed = "https://" + trimmed
        }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil else {
            throw CanvasError.invalidHost(raw)
        }
        return url
    }
}
