import EaselKit
import Foundation
import XCTest

final class SubmissionsTests: XCTestCase {
    private func queryItems(_ request: HTTPRequest) throws -> [URLQueryItem] {
        let components = try XCTUnwrap(URLComponents(url: request.url, resolvingAgainstBaseURL: false))
        return components.queryItems ?? []
    }

    private func decodeSubmissions() throws -> [Submission] {
        try CanvasJSON.makeDecoder().decode([Submission].self, from: Data(Fixtures.submissionsList.utf8))
    }

    func testListSubmissions() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/students/submissions", json: Fixtures.submissionsList)
        let client = CanvasClient.stubbed(transport)

        let submissions = try await client.submissions(courseID: 101)

        XCTAssertEqual(submissions.count, 3)
        let graded = submissions[0]
        XCTAssertEqual(graded.id, 7001)
        XCTAssertEqual(graded.userID, 9001)
        XCTAssertEqual(graded.assignmentID, 501)
        XCTAssertEqual(graded.workflowState, "graded")
        XCTAssertEqual(graded.submissionType, "online_upload")
        XCTAssertEqual(graded.score, 92)
        XCTAssertEqual(graded.grade, "92")
        XCTAssertEqual(graded.gradeMatchesCurrentSubmission, true)
        XCTAssertNotNil(graded.submittedAt)
        XCTAssertEqual(graded.graderID, 9002)
        XCTAssertEqual(graded.user?.name, "Alex Rivera")

        let missing = submissions[1]
        XCTAssertEqual(missing.workflowState, "unsubmitted")
        XCTAssertEqual(missing.missing, true)
        XCTAssertNil(missing.submittedAt)
        XCTAssertNil(missing.score)

        let excused = submissions[2]
        XCTAssertEqual(excused.workflowState, "unsubmitted")
        XCTAssertEqual(excused.excused, true)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.url.path, "/api/v1/courses/101/students/submissions")
        let items = try queryItems(request)
        XCTAssertTrue(items.contains(URLQueryItem(name: "student_ids[]", value: "all")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "enrollment_state", value: "active")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "include[]", value: "user")))
        // No filters by default: every assignment, every state.
        XCTAssertFalse(items.contains { $0.name == "assignment_ids[]" })
        XCTAssertFalse(items.contains { $0.name == "workflow_state" })
    }

    func testAssignmentAndStateQuery() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/students/submissions", json: Fixtures.submissionsList)
        let client = CanvasClient.stubbed(transport)

        _ = try await client.submissions(courseID: 101, assignmentIDs: [501, 502], state: .pendingReview)

        let recorded = await transport.recorded
        let items = try queryItems(try XCTUnwrap(recorded.first))
        XCTAssertEqual(items.filter { $0.name == "assignment_ids[]" }.map(\.value), ["501", "502"])
        XCTAssertTrue(items.contains(URLQueryItem(name: "workflow_state", value: "pending_review")))
    }

    // MARK: - Output formats

    func testIDFormatListsStudentUserIDs() throws {
        let rendered = try OutputFormatter.render(decodeSubmissions(), format: .id)
        XCTAssertEqual(rendered, "9001\n9003\n9004")
    }

    func testSmallJSONLCarriesGradingFields() throws {
        let submissions = try decodeSubmissions()
        let graded = try OutputFormatter.render(submissions[0], format: .smalljsonl)
        XCTAssertTrue(graded.contains("\"name\":\"Alex Rivera\""))
        XCTAssertTrue(graded.contains("\"workflow_state\":\"graded\""))
        XCTAssertTrue(graded.contains("\"score\":92"))
        XCTAssertTrue(graded.contains("\"grade_matches_current_submission\":true"))

        let excused = try OutputFormatter.render(submissions[2], format: .smalljsonl)
        XCTAssertTrue(excused.contains("\"excused\":true"))
        XCTAssertTrue(excused.contains("\"workflow_state\":\"unsubmitted\""))
        // Nil fields drop out.
        XCTAssertFalse(excused.contains("submitted_at"))
    }

    func testMarkdownHeadingUsesStudentName() throws {
        let rendered = try OutputFormatter.render(decodeSubmissions(), format: .md)
        XCTAssertTrue(rendered.contains("## Alex Rivera (#9001)"))
        XCTAssertTrue(rendered.contains("- **workflow_state:** graded"))
        XCTAssertTrue(rendered.contains("- **excused:** true"))
    }

    func testMarkdownHeadingFallsBackToUserID() throws {
        let submission = try CanvasJSON.makeDecoder().decode(
            Submission.self,
            from: Data(#"{ "id": 1, "user_id": 9005, "assignment_id": 501 }"#.utf8)
        )
        XCTAssertTrue(submission.markdownRow.hasPrefix("## User 9005 (#9005)"))
    }

    // MARK: - Anonymous mode

    func testAnonymizedRedactsEmbeddedUser() throws {
        let redacted = try decodeSubmissions().map { $0.anonymized() }

        XCTAssertEqual(redacted[0].user?.name, "Ale R")
        XCTAssertEqual(redacted[0].user?.sortableName, "R, Ale")
        XCTAssertNil(redacted[0].user?.loginID)
        // Submission fields carry no identity and are kept.
        XCTAssertEqual(redacted[0].userID, 9001)
        XCTAssertEqual(redacted[0].score, 92)
        XCTAssertEqual(redacted[2].excused, true)

        let rendered = try OutputFormatter.render(redacted, format: .json)
        XCTAssertFalse(rendered.contains("Rivera"))
        XCTAssertFalse(rendered.contains("Patel"))
        XCTAssertFalse(rendered.contains("\"arivera\""))
        XCTAssertTrue(rendered.contains("Jor L"))
    }
}
