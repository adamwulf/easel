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

        XCTAssertEqual(submissions.count, 5)
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

        // Canvas marks an excused submission graded, with no score.
        let excused = submissions[2]
        XCTAssertEqual(excused.workflowState, "graded")
        XCTAssertEqual(excused.excused, true)
        XCTAssertNil(excused.score)

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

    func testAssignmentQueryAndStatusFilter() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/students/submissions", json: Fixtures.submissionsList)
        let client = CanvasClient.stubbed(transport)

        let submissions = try await client.submissions(courseID: 101, assignmentIDs: [501, 502], status: .notSubmitted)

        // The placeholder and the graded-0 missing work, but not the excused row.
        XCTAssertEqual(submissions.map(\.userID), [9003, 9005])
        let recorded = await transport.recorded
        let items = try queryItems(try XCTUnwrap(recorded.first))
        XCTAssertEqual(items.filter { $0.name == "assignment_ids[]" }.map(\.value), ["501", "502"])
        // The status filter runs on the client; Canvas is asked for every state.
        XCTAssertFalse(items.contains { $0.name == "workflow_state" })
    }

    func testStatusFilterSelectsEachStatus() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/students/submissions", json: Fixtures.submissionsList)
        let client = CanvasClient.stubbed(transport)

        let expected: [(SubmissionStatus, [Int])] = [
            (.notSubmitted, [9003, 9005]),
            (.needsGrading, [9006]),
            (.graded, [9001]),
            (.excused, [9004]),
        ]
        for (status, userIDs) in expected {
            let submissions = try await client.submissions(courseID: 101, status: status)
            XCTAssertEqual(submissions.map(\.userID), userIDs, "\(status)")
        }
    }

    // MARK: - Status

    func testStatusOfEachFixtureRow() throws {
        let statuses = try decodeSubmissions().map(\.status)
        XCTAssertEqual(statuses, [
            .graded,        // scored, grade matches the current attempt
            .notSubmitted,  // unsubmitted placeholder
            .excused,       // Canvas marks it graded, with no score
            .notSubmitted,  // missing work a teacher scored 0: graded, never submitted
            .needsGrading,  // resubmitted after grading: old score, grade doesn't match
        ])
    }

    func testStatusRulesBeyondTheFixture() throws {
        func status(_ json: String) throws -> SubmissionStatus {
            try CanvasJSON.makeDecoder().decode(Submission.self, from: Data(json.utf8)).status
        }
        let base = #""id": 1, "user_id": 2, "assignment_id": 3, "submitted_at": "2026-09-04T22:15:00Z""#
        // First submission, no score yet.
        XCTAssertEqual(
            try status(#"{ \#(base), "workflow_state": "submitted", "submission_type": "online_upload" }"#),
            .needsGrading
        )
        // A quiz waiting on manual review, even with a provisional score.
        XCTAssertEqual(
            try status(#"{ \#(base), "workflow_state": "pending_review", "submission_type": "online_quiz", "score": 4 }"#),
            .needsGrading
        )
        // A teacher cleared the grade: still graded, but no score.
        XCTAssertEqual(
            try status(#"{ \#(base), "workflow_state": "graded", "submission_type": "online_upload" }"#),
            .needsGrading
        )
        // Excused wins over a submission.
        XCTAssertEqual(
            try status(#"{ \#(base), "workflow_state": "graded", "submission_type": "online_upload", "excused": true }"#),
            .excused
        )
    }

    // MARK: - Output formats

    func testIDFormatListsStudentUserIDs() throws {
        let rendered = try OutputFormatter.render(decodeSubmissions(), format: .id)
        XCTAssertEqual(rendered, "9001\n9003\n9004\n9005\n9006")
    }

    func testEveryFormatShowsStatus() throws {
        let submissions = try decodeSubmissions()
        // Graded missing work: Canvas says graded, easel says not submitted.
        let gradedZero = submissions[3]
        XCTAssertEqual(gradedZero.workflowState, "graded")
        XCTAssertTrue(try OutputFormatter.render(gradedZero, format: .jsonl).contains("\"status\":\"not-submitted\""))
        XCTAssertTrue(try OutputFormatter.render(gradedZero, format: .smalljsonl).contains("\"status\":\"not-submitted\""))
        XCTAssertTrue(try OutputFormatter.render(gradedZero, format: .md).contains("- **status:** not-submitted"))
        XCTAssertTrue(try OutputFormatter.render(submissions[2], format: .jsonl).contains("\"status\":\"excused\""))
    }

    func testJSONRoundTripsCanvasFields() throws {
        // The hand-written encode must keep every Canvas field; decoding
        // ignores the extra status key.
        let submissions = try decodeSubmissions()
        let json = try OutputFormatter.render(submissions, format: .json)
        let decoded = try CanvasJSON.makeDecoder().decode([Submission].self, from: Data(json.utf8))
        XCTAssertEqual(decoded, submissions)
        // Every Canvas field the encoder writes has a non-nil value in some
        // row, so a dropped or mis-keyed line fails the round trip above.
        XCTAssertEqual(decoded[4].latePolicyStatus, "late")
        XCTAssertEqual(decoded[4].secondsLate, 86400)
        // Nil fields stay omitted, as synthesized encoding does.
        let placeholder = try OutputFormatter.render(submissions[1], format: .jsonl)
        XCTAssertFalse(placeholder.contains("submitted_at"))
        XCTAssertFalse(placeholder.contains("null"))
    }

    func testSmallJSONLCarriesGradingFields() throws {
        let submissions = try decodeSubmissions()
        let graded = try OutputFormatter.render(submissions[0], format: .smalljsonl)
        XCTAssertTrue(graded.contains("\"name\":\"Alex Rivera\""))
        XCTAssertTrue(graded.contains("\"workflow_state\":\"graded\""))
        XCTAssertTrue(graded.contains("\"user_id\":9001"))
        XCTAssertTrue(graded.contains("\"assignment_id\":501"))
        XCTAssertTrue(graded.contains("\"submitted_at\":\"2026-09-04T22:15:00Z\""))
        XCTAssertTrue(graded.contains("\"submission_type\":\"online_upload\""))
        XCTAssertTrue(graded.contains("\"score\":92"))
        XCTAssertTrue(graded.contains("\"grade_matches_current_submission\":true"))

        let excused = try OutputFormatter.render(submissions[2], format: .smalljsonl)
        XCTAssertTrue(excused.contains("\"excused\":true"))
        XCTAssertTrue(excused.contains("\"workflow_state\":\"graded\""))
        // Nil fields drop out.
        XCTAssertFalse(excused.contains("submitted_at"))
        XCTAssertFalse(excused.contains("submission_type"))
        XCTAssertFalse(excused.contains("score"))
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

        XCTAssertNil(redacted[0].user?.email)

        // Every format renders from the redacted model; md and smalljsonl read
        // the name through their own paths, so check each one.
        for format in [OutputFormat.json, .jsonl, .smalljsonl, .md] {
            let rendered = try OutputFormatter.render(redacted, format: format)
            XCTAssertFalse(rendered.contains("Rivera"), "\(format)")
            XCTAssertFalse(rendered.contains("Patel"), "\(format)")
            XCTAssertFalse(rendered.contains("arivera"), "\(format)")
            XCTAssertTrue(rendered.contains("Jor L"), "\(format)")
        }
        let markdown = try OutputFormatter.render(redacted, format: .md)
        XCTAssertTrue(markdown.contains("## Ale R (#9001)"))
        let summary = try OutputFormatter.render(redacted[0], format: .smalljsonl)
        XCTAssertTrue(summary.contains("\"name\":\"Ale R\""))
    }
}
