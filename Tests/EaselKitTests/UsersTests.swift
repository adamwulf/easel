import EaselKit
import Foundation
import XCTest

final class UsersTests: XCTestCase {
    func testListUsers() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/users", json: Fixtures.usersList)
        let client = CanvasClient.stubbed(transport)

        let users = try await client.users(courseID: 101)

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, "Alex Rivera")
        XCTAssertEqual(users[0].email, "arivera@example.edu")
        XCTAssertEqual(users[0].pronouns, "they/them")
        XCTAssertEqual(users[0].enrollments?.first?.type, "StudentEnrollment")
        XCTAssertNil(users[1].email)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        let query = try XCTUnwrap(request.url.query)
        XCTAssertTrue(query.contains("email"))
        XCTAssertTrue(query.contains("enrollments"))
    }

    func testEnrollmentTypeAndSearchQuery() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/users", json: Fixtures.usersList)
        let client = CanvasClient.stubbed(transport)

        _ = try await client.users(courseID: 101, enrollmentType: "student", searchTerm: "rivera")

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        let query = try XCTUnwrap(request.url.query)
        XCTAssertTrue(query.contains("student"))
        XCTAssertTrue(query.contains("search_term=rivera"))
    }
}
