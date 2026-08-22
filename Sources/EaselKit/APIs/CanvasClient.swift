import Foundation

/// High-level Canvas facade. Walks pagination, returns whole collections, and
/// exposes one typed method per operation (see the per-resource extensions).
/// This is the only type CLI commands talk to.
public struct CanvasClient: Sendable {
    public let api: CanvasAPI

    public init(api: CanvasAPI) {
        self.api = api
    }

    public init(config: CanvasConfig, transport: any HTTPTransport = URLSessionTransport()) {
        self.init(api: CanvasAPI(config: config, transport: transport))
    }

    /// Fetches every page of a list endpoint by following `Link` headers.
    func fetchAll<T: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = []) async throws -> [T] {
        var (all, next): ([T], URL?) = try await api.getPage(path, query: query)
        while let url = next {
            let (more, following): ([T], URL?) = try await api.getPage(url: url)
            all.append(contentsOf: more)
            next = following
        }
        return all
    }
}
