import EaselKit
import Foundation
import XCTest

final class ErrorTests: XCTestCase {
    func testUnauthorizedMapsTo401Error() async throws {
        let transport = StubTransport()
        await transport.on("/api/v1/courses", status: 401, json: Fixtures.error401)
        let client = CanvasClient.stubbed(transport)

        do {
            _ = try await client.courses()
            XCTFail("expected an error")
        } catch let error as CanvasError {
            XCTAssertEqual(error, .unauthorized(message: "Invalid access token."))
        }
    }

    func testNotFoundMapsTo404Error() async throws {
        let transport = StubTransport()
        await transport.on("/pages/missing-page", status: 404, json: Fixtures.error404)
        let client = CanvasClient.stubbed(transport)

        do {
            _ = try await client.page(courseID: 101, urlOrID: "missing-page")
            XCTFail("expected an error")
        } catch let error as CanvasError {
            XCTAssertEqual(error, .notFound(message: "The specified resource does not exist."))
        }
    }

    func testRetriesTransientServerErrorThenSucceeds() async throws {
        let transport = StubTransport()
        await transport.onSequence("/api/v1/courses", responses: [
            HTTPResponse(status: 500, body: Data(Fixtures.error500.utf8)),
            HTTPResponse(status: 200, body: Data(Fixtures.coursesPage2.utf8))
        ])
        let client = CanvasClient.stubbed(transport)

        let courses = try await client.courses()

        XCTAssertEqual(courses.count, 1)
        let recordedCount = await transport.recorded.count
        XCTAssertEqual(recordedCount, 2)
    }

    func testGivesUpAfterMaxAttempts() async throws {
        let transport = StubTransport()
        await transport.on("/api/v1/courses", status: 503, json: Fixtures.error500)
        let client = CanvasClient.stubbed(transport)

        do {
            _ = try await client.courses()
            XCTFail("expected an error")
        } catch let error as CanvasError {
            XCTAssertEqual(error, .http(status: 503, message: "An error occurred."))
        }
        let recordedCount = await transport.recorded.count
        XCTAssertEqual(recordedCount, 3, "maxAttempts is 3 in the stubbed client")
    }

    func testDecodingFailureIsTyped() async throws {
        let transport = StubTransport()
        await transport.on("/api/v1/courses", json: "{\"not\": \"a list\"}")
        let client = CanvasClient.stubbed(transport)

        do {
            _ = try await client.courses()
            XCTFail("expected an error")
        } catch let error as CanvasError {
            guard case .decoding = error else {
                XCTFail("expected CanvasError.decoding, got \(error)")
                return
            }
        }
    }
}
