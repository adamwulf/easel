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
        XCTAssertNotNil(assignment.unlockAt)
        XCTAssertNotNil(assignment.lockAt)
        let criterion = try XCTUnwrap(assignment.rubric?.first)
        XCTAssertEqual(criterion.id, "_10")
        XCTAssertEqual(criterion.points, 60.0)
        XCTAssertEqual(criterion.ratings?.count, 2)
        XCTAssertEqual(assignment.rubricSettings?.id, 9)
        XCTAssertEqual(assignment.rubricSettings?.title, "Portrait Rubric")
    }

    func testCreateAssignmentSendsAllProvidedFieldsAndDecodesResponse() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/assignments", method: "POST", json: Fixtures.assignmentCreated)
        let client = CanvasClient.stubbed(transport)

        let draft = AssignmentCreate(
            name: "Value Study",
            description: "<p>Paint a grayscale still life.</p>",
            published: false,
            pointsPossible: 75.0,
            dueAt: "2026-09-19T23:59:59-05:00",
            unlockAt: "2026-09-01T00:00:00-05:00",
            lockAt: "2026-09-21T23:59:59-05:00"
        )
        let assignment = try await client.createAssignment(courseID: 101, assignment: draft)

        XCTAssertEqual(assignment.id, 503)
        XCTAssertEqual(assignment.name, "Value Study")
        XCTAssertEqual(assignment.pointsPossible, 75.0)
        XCTAssertEqual(assignment.courseID, 101)
        XCTAssertNotNil(assignment.dueAt)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.url.path, "/api/v1/courses/101/assignments")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        let payload = try XCTUnwrap(object["assignment"] as? [String: Any])
        XCTAssertEqual(payload["name"] as? String, "Value Study")
        XCTAssertEqual(payload["description"] as? String, "<p>Paint a grayscale still life.</p>")
        XCTAssertEqual(payload["published"] as? Bool, false)
        XCTAssertEqual(payload["points_possible"] as? Double, 75.0)
        XCTAssertEqual(payload["due_at"] as? String, "2026-09-19T23:59:59-05:00")
        XCTAssertEqual(payload["unlock_at"] as? String, "2026-09-01T00:00:00-05:00")
        XCTAssertEqual(payload["lock_at"] as? String, "2026-09-21T23:59:59-05:00")
    }

    func testCreateAssignmentOmitsOptionalFields() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/assignments", method: "POST", json: Fixtures.assignmentCreated)
        let client = CanvasClient.stubbed(transport)

        _ = try await client.createAssignment(
            courseID: 101,
            assignment: AssignmentCreate(name: "Value Study")
        )

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        let payload = try XCTUnwrap(object["assignment"] as? [String: Any])
        XCTAssertEqual(payload.count, 1)
        XCTAssertEqual(payload["name"] as? String, "Value Study")
        XCTAssertNil(payload["description"])
        XCTAssertNil(payload["published"])
        XCTAssertNil(payload["points_possible"])
        XCTAssertNil(payload["due_at"])
        XCTAssertNil(payload["unlock_at"])
        XCTAssertNil(payload["lock_at"])
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
        XCTAssertNil(payload["unlock_at"])
        XCTAssertNil(payload["lock_at"])
    }

    func testUpdateAssignmentSendsDueAndAvailabilityDates() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/assignments/501", method: "PUT", json: Fixtures.assignmentUpdated)
        let client = CanvasClient.stubbed(transport)

        let update = AssignmentUpdate(
            dueAt: "2026-09-12T23:59:00-05:00",
            unlockAt: "2026-08-24T00:00:00-05:00",
            lockAt: "2026-09-13T23:59:00-05:00"
        )
        _ = try await client.updateAssignment(courseID: 101, id: 501, update: update)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        let payload = try XCTUnwrap(object["assignment"] as? [String: Any])
        XCTAssertEqual(payload["due_at"] as? String, "2026-09-12T23:59:00-05:00")
        XCTAssertEqual(payload["unlock_at"] as? String, "2026-08-24T00:00:00-05:00")
        XCTAssertEqual(payload["lock_at"] as? String, "2026-09-13T23:59:00-05:00")
        XCTAssertNil(payload["name"])
    }

    func testDeleteAssignmentUsesDeleteWithoutBodyAndDecodesResponse() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/assignments/502", method: "DELETE", json: Fixtures.assignmentDeleted)
        let client = CanvasClient.stubbed(transport)

        let assignment = try await client.deleteAssignment(courseID: 101, id: 502)

        XCTAssertEqual(assignment.id, 502)
        XCTAssertEqual(assignment.name, "Gesture Studies")
        XCTAssertEqual(assignment.description, "<p>Complete ten gesture drawings.</p>")
        XCTAssertEqual(assignment.published, false)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.method, "DELETE")
        XCTAssertEqual(request.url.path, "/api/v1/courses/101/assignments/502")
        XCTAssertNil(request.body)
    }
}
