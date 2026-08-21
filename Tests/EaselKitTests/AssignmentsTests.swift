import EaselKit
import Foundation
import XCTest

final class AssignmentsTests: XCTestCase {
    func testListAssignments() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/assignments", json: Fixtures.assignmentsList)
        let client = CanvasClient.stubbed(transport)

        let assignments = try await client.assignments(courseID: 101)

        XCTAssertEqual(assignments.count, 2)
        XCTAssertEqual(assignments[0].id, 501)
        XCTAssertEqual(assignments[0].pointsPossible, 100.0)
        XCTAssertEqual(assignments[1].published, false)
        XCTAssertNil(assignments[1].dueAt)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.url.query?.contains("order_by=position"), true)
    }

    func testShowAssignmentDecodesRubric() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/assignments/501", json: Fixtures.assignmentShow)
        let client = CanvasClient.stubbed(transport)

        let assignment = try await client.assignment(courseID: 101, id: 501)

        XCTAssertEqual(assignment.description, "<p>Draw yourself in charcoal.</p>")
        let criterion = try XCTUnwrap(assignment.rubric?.first)
        XCTAssertEqual(criterion.id, "_10")
        XCTAssertEqual(criterion.points, 60.0)
        XCTAssertEqual(criterion.ratings?.count, 2)
        XCTAssertEqual(assignment.rubricSettings?.id, 9)
        XCTAssertEqual(assignment.rubricSettings?.title, "Portrait Rubric")
    }

    func testUpdateAssignmentSendsOnlyProvidedFields() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/assignments/501", method: "PUT", json: Fixtures.assignmentUpdated)
        let client = CanvasClient.stubbed(transport)

        let update = AssignmentUpdate(name: "Self Portrait (Revised)", pointsPossible: 120.0)
        let assignment = try await client.updateAssignment(courseID: 101, id: 501, update: update)

        XCTAssertEqual(assignment.name, "Self Portrait (Revised)")
        XCTAssertEqual(assignment.pointsPossible, 120.0)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.method, "PUT")
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        let payload = try XCTUnwrap(object["assignment"] as? [String: Any])
        XCTAssertEqual(payload["name"] as? String, "Self Portrait (Revised)")
        XCTAssertEqual(payload["points_possible"] as? Double, 120.0)
        XCTAssertNil(payload["description"])
        XCTAssertNil(payload["due_at"])
    }
}
