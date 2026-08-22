import EaselKit
import Foundation
import XCTest

final class CoursesTests: XCTestCase {
    func testListCoursesSinglePage() async throws {
        let transport = StubTransport()
        await transport.on("/api/v1/courses", json: Fixtures.coursesPage1)
        let client = CanvasClient.stubbed(transport)

        let courses = try await client.courses()

        XCTAssertEqual(courses.count, 2)
        XCTAssertEqual(courses[0].id, 101)
        XCTAssertEqual(courses[0].name, "Intro to Drawing")
        XCTAssertEqual(courses[0].courseCode, "ART-101")
        XCTAssertEqual(courses[0].totalStudents, 18)
        XCTAssertEqual(courses[1].workflowState, "unpublished")
        XCTAssertNotNil(courses[0].startAt)

        let recorded = await transport.recorded
        XCTAssertEqual(recorded.count, 1)
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.method, "GET")
        XCTAssertEqual(request.headers["Authorization"], "Bearer test-token")
        XCTAssertEqual(request.url.query?.contains("per_page=100"), true)
    }

    func testFollowsPagination() async throws {
        let transport = StubTransport()
        let nextURL = "https://example.instructure.com/api/v1/courses?page=2&per_page=100"
        await transport.on("page=2", json: Fixtures.coursesPage2)
        await transport.on(
            "/api/v1/courses",
            headers: ["Link": "<\(nextURL)>; rel=\"next\""],
            json: Fixtures.coursesPage1
        )
        let client = CanvasClient.stubbed(transport)

        let courses = try await client.courses()

        XCTAssertEqual(courses.count, 3)
        XCTAssertEqual(courses.map(\.id), [101, 102, 103])
        let recorded = await transport.recorded
        XCTAssertEqual(recorded.count, 2)
        XCTAssertEqual(recorded.last?.url.absoluteString, nextURL)
    }

    func testEnrollmentTypeAndStateQuery() async throws {
        let transport = StubTransport()
        await transport.on("/api/v1/courses", json: Fixtures.coursesPage2)
        let client = CanvasClient.stubbed(transport)

        _ = try await client.courses(enrollmentType: "teacher", state: "available")

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        let query = try XCTUnwrap(request.url.query)
        XCTAssertTrue(query.contains("enrollment_type=teacher"))
        XCTAssertTrue(query.contains("available"))
    }
}
