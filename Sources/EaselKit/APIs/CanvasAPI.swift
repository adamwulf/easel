import Foundation
import Logging

/// Low-level Canvas REST client. Builds authenticated requests, retries
/// transient failures, maps error statuses to `CanvasError`, decodes JSON, and
/// surfaces one page at a time. Pagination across pages lives in
/// `CanvasClient`, never here.
public struct CanvasAPI: Sendable {
    public let config: CanvasConfig
    let transport: any HTTPTransport
    let maxAttempts: Int
    let retryDelayMilliseconds: Int

    private let logger = Logger(label: "easel.api")
    private static let retryableStatuses: Set<Int> = [429, 500, 502, 503, 504]
    static let defaultPerPage = 100

    public init(
        config: CanvasConfig,
        transport: any HTTPTransport = URLSessionTransport(),
        maxAttempts: Int = 3,
        retryDelayMilliseconds: Int = 500
    ) {
        self.config = config
        self.transport = transport
        self.maxAttempts = maxAttempts
        self.retryDelayMilliseconds = retryDelayMilliseconds
    }

    // MARK: - Requests

    /// Fetches one page of a list endpoint plus the URL of the following page,
    /// if any. Adds `per_page` unless the query already sets it.
    public func getPage<T: Decodable & Sendable>(
        _ path: String,
        query: [URLQueryItem] = []
    ) async throws -> (value: T, nextPage: URL?) {
        var query = query
        if !query.contains(where: { $0.name == "per_page" }) {
            query.append(URLQueryItem(name: "per_page", value: String(Self.defaultPerPage)))
        }
        return try await getPage(url: try makeURL(path: path, query: query))
    }

    /// Fetches one page from an absolute URL (used to follow `Link` headers).
    public func getPage<T: Decodable & Sendable>(url: URL) async throws -> (value: T, nextPage: URL?) {
        let response = try await send(HTTPRequest(method: "GET", url: url, headers: baseHeaders()))
        let value: T = try decode(response.body)
        return (value, LinkHeader.nextPageURL(from: response.header("Link")))
    }

    /// Fetches a single object.
    public func get<T: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        let response = try await send(HTTPRequest(method: "GET", url: try makeURL(path: path, query: query), headers: baseHeaders()))
        return try decode(response.body)
    }

    public func put<T: Decodable & Sendable, Body: Encodable & Sendable>(_ path: String, body: Body) async throws -> T {
        let data = try await sendJSON(method: "PUT", path: path, body: body)
        return try decode(data)
    }

    public func post<T: Decodable & Sendable, Body: Encodable & Sendable>(_ path: String, body: Body) async throws -> T {
        let data = try await sendJSON(method: "POST", path: path, body: body)
        return try decode(data)
    }

    public func delete<T: Decodable & Sendable>(_ path: String) async throws -> T {
        let response = try await send(
            HTTPRequest(method: "DELETE", url: try makeURL(path: path, query: []), headers: baseHeaders())
        )
        return try decode(response.body)
    }

    /// Sends a JSON body and returns the raw response data, for callers that
    /// need custom decoding.
    public func sendJSON<Body: Encodable & Sendable>(method: String, path: String, body: Body) async throws -> Data {
        let encoded: Data
        do {
            encoded = try CanvasJSON.makeEncoder(pretty: false).encode(body)
        } catch {
            throw CanvasError.decoding(type: String(describing: Body.self), message: String(describing: error))
        }
        var headers = baseHeaders()
        headers["Content-Type"] = "application/json"
        let request = HTTPRequest(method: method, url: try makeURL(path: path, query: []), headers: headers, body: encoded)
        let response = try await send(request)
        return response.body
    }

    // MARK: - Core send with retry

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var attempt = 1
        while true {
            logger.debug("request", metadata: [
                "method": "\(request.method)",
                "url": "\(request.url.absoluteString)",
                "attempt": "\(attempt)"
            ])
            let response: HTTPResponse
            do {
                response = try await transport.send(request)
            } catch {
                guard attempt < maxAttempts else {
                    logger.error("transport failed", metadata: [
                        "url": "\(request.url.absoluteString)",
                        "error": "\(String(describing: error))"
                    ])
                    throw CanvasError.transport(message: String(describing: error))
                }
                logger.warning("transport error, retrying", metadata: [
                    "url": "\(request.url.absoluteString)",
                    "attempt": "\(attempt)"
                ])
                try await backoff(attempt: attempt)
                attempt += 1
                continue
            }
            if Self.retryableStatuses.contains(response.status), attempt < maxAttempts {
                logger.warning("retryable status, retrying", metadata: [
                    "status": "\(response.status)",
                    "url": "\(request.url.absoluteString)",
                    "attempt": "\(attempt)"
                ])
                try await backoff(attempt: attempt)
                attempt += 1
                continue
            }
            logger.debug("response", metadata: [
                "status": "\(response.status)",
                "url": "\(request.url.absoluteString)"
            ])
            guard (200..<300).contains(response.status) else {
                throw error(for: response)
            }
            return response
        }
    }

    private func backoff(attempt: Int) async throws {
        let milliseconds = retryDelayMilliseconds * attempt
        guard milliseconds > 0 else {
            return
        }
        try await Task.sleep(for: .milliseconds(milliseconds))
    }

    // MARK: - Helpers

    func makeURL(path: String, query: [URLQueryItem]) throws -> URL {
        let full = config.apiBaseURL.appendingPathComponent(path)
        guard var components = URLComponents(url: full, resolvingAgainstBaseURL: false) else {
            throw CanvasError.invalidURL(path)
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw CanvasError.invalidURL(path)
        }
        return url
    }

    func baseHeaders() -> [String: String] {
        [
            "Authorization": "Bearer \(config.token)",
            "Accept": "application/json",
            "User-Agent": "easel"
        ]
    }

    func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try CanvasJSON.makeDecoder().decode(T.self, from: data)
        } catch {
            throw CanvasError.decoding(type: String(describing: T.self), message: String(describing: error))
        }
    }

    private func error(for response: HTTPResponse) -> CanvasError {
        let message = Self.errorMessage(from: response.body)
        switch response.status {
        case 401:
            return .unauthorized(message: message)
        case 404:
            return .notFound(message: message)
        default:
            return .http(status: response.status, message: message)
        }
    }

    /// Extracts a human-readable message from a Canvas error payload. Canvas
    /// commonly sends `{"errors": [{"message": "..."}]}` or `{"message": "..."}`.
    static func errorMessage(from data: Data) -> String? {
        struct ListEnvelope: Decodable {
            struct Item: Decodable {
                let message: String?
            }

            let errors: [Item]
        }
        struct MessageEnvelope: Decodable {
            let message: String?
        }
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(ListEnvelope.self, from: data) {
            let messages = envelope.errors.compactMap(\.message)
            if !messages.isEmpty {
                return messages.joined(separator: "; ")
            }
        }
        if let envelope = try? decoder.decode(MessageEnvelope.self, from: data), let message = envelope.message {
            return message
        }
        guard !data.isEmpty else {
            return nil
        }
        let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return nil
        }
        return String(text.prefix(300))
    }
}
