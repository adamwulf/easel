import EaselKit
import Foundation

/// A fake `HTTPTransport` that answers from canned responses, so tests run the
/// full client stack offline. Stubs match when the request URL contains the
/// path fragment (and the method matches, when given); earlier stubs win, so
/// register more specific fragments first. An unmatched request returns HTTP
/// 599 so a test fails loudly instead of silently hitting the network.
actor StubTransport: HTTPTransport {
    struct Stub {
        let pathFragment: String
        let method: String?
        var responses: [HTTPResponse]
    }

    private(set) var recorded: [HTTPRequest] = []
    private var stubs: [Stub] = []

    func on(
        _ pathFragment: String,
        method: String? = nil,
        status: Int = 200,
        headers: [String: String] = [:],
        json: String
    ) {
        let response = HTTPResponse(status: status, headers: headers, body: Data(json.utf8))
        stubs.append(Stub(pathFragment: pathFragment, method: method, responses: [response]))
    }

    /// Registers a sequence of responses for one matcher; the last response
    /// repeats once the sequence is exhausted.
    func onSequence(_ pathFragment: String, method: String? = nil, responses: [HTTPResponse]) {
        stubs.append(Stub(pathFragment: pathFragment, method: method, responses: responses))
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        recorded.append(request)
        for index in stubs.indices {
            let stub = stubs[index]
            guard request.url.absoluteString.contains(stub.pathFragment) else {
                continue
            }
            if let method = stub.method, method != request.method {
                continue
            }
            if stubs[index].responses.count > 1 {
                return stubs[index].responses.removeFirst()
            }
            return stub.responses[0]
        }
        let message = "no stub matched \(request.method) \(request.url.absoluteString)"
        return HTTPResponse(status: 599, headers: [:], body: Data(message.utf8))
    }
}

extension CanvasClient {
    /// A client wired to a stub transport with a fake token and zero retry
    /// delay, for tests.
    static func stubbed(_ transport: StubTransport) -> CanvasClient {
        let config = CanvasConfig(
            baseURL: URL(string: "https://example.instructure.com")!,
            token: "test-token"
        )
        let api = CanvasAPI(
            config: config,
            transport: transport,
            maxAttempts: 3,
            retryDelayMilliseconds: 0
        )
        return CanvasClient(api: api)
    }
}
