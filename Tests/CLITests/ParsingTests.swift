import ArgumentParser
import XCTest
@testable import easel

/// Argument-parsing tests only — no command is run, so nothing needs a network
/// or an API key.
final class ParsingTests: XCTestCase {
    func testRootListsAllSubcommands() {
        XCTAssertEqual(Easel.configuration.subcommands.count, 18)
    }

    func testCoursesParses() throws {
        let command = try CoursesCommand.parse(["--enrollment-type", "teacher", "--format", "id"])
        XCTAssertEqual(command.enrollmentType, "teacher")
        XCTAssertEqual(command.options.format, .id)
    }

    func testFormatDefaultsToJSON() throws {
        let command = try CoursesCommand.parse([])
        XCTAssertEqual(command.options.format, .json)
    }

    func testInvalidFormatIsRejected() {
        XCTAssertThrowsError(try CoursesCommand.parse(["--format", "yaml"]))
    }

    func testParsesSmallJSONLFormat() throws {
        let command = try CoursesCommand.parse(["--format", "smalljsonl"])
        XCTAssertEqual(command.options.format, .smalljsonl)
    }

    func testParsesMarkdownFormat() throws {
        let command = try CoursesCommand.parse(["--format", "md"])
        XCTAssertEqual(command.options.format, .md)
    }

    func testPagesRequiresCourseID() {
        XCTAssertThrowsError(try PagesCommand.parse([]))
    }

    func testPageParsesCourseAndSlug() throws {
        let command = try PageCommand.parse(["101", "course-syllabus"])
        XCTAssertEqual(command.courseID, 101)
        XCTAssertEqual(command.urlOrID, "course-syllabus")
    }

    func testCreatePageRequiresTitle() {
        XCTAssertThrowsError(try CreatePageCommand.parse(["101"]))
    }

    func testCreatePageParsesAllFields() throws {
        let command = try CreatePageCommand.parse([
            "101",
            "--title", "Week 2 Materials",
            "--body-file", "week-2.html",
            "--editing-roles", "teachers,students",
            "--notify-of-update", "true",
            "--published", "false",
            "--front-page", "true",
            "--publish-at", "2026-08-31T08:00:00-05:00",
        ])
        XCTAssertEqual(command.courseID, 101)
        XCTAssertEqual(command.title, "Week 2 Materials")
        XCTAssertEqual(command.bodyFile, "week-2.html")
        XCTAssertEqual(command.editingRoles, "teachers,students")
        XCTAssertEqual(command.notifyOfUpdate, true)
        XCTAssertEqual(command.published, false)
        XCTAssertEqual(command.frontPage, true)
        XCTAssertEqual(command.publishAt, "2026-08-31T08:00:00-05:00")
    }

    func testCreatePageRejectsBodyAndBodyFileTogether() {
        XCTAssertThrowsError(
            try CreatePageCommand.parse(["101", "--title", "Week 2", "--body", "<p>x</p>", "--body-file", "x.html"])
        )
    }

    func testCreatePageRejectsDateWithoutTimeZone() {
        XCTAssertThrowsError(
            try CreatePageCommand.parse(["101", "--title", "Week 2", "--publish-at", "2026-08-31T08:00:00"])
        )
    }

    func testDeletePageParsesCourseAndSlug() throws {
        let command = try DeletePageCommand.parse(["101", "week-2-materials"])
        XCTAssertEqual(command.courseID, 101)
        XCTAssertEqual(command.urlOrID, "week-2-materials")
    }

    func testUpdatePageRequiresAChange() {
        XCTAssertThrowsError(try UpdatePageCommand.parse(["101", "home"]))
    }

    func testUpdatePageParsesWithTitle() throws {
        let command = try UpdatePageCommand.parse(["101", "home", "--title", "New Title"])
        XCTAssertEqual(command.courseID, 101)
        XCTAssertEqual(command.urlOrID, "home")
        XCTAssertEqual(command.title, "New Title")
    }

    func testUpdatePageRejectsBodyAndBodyFileTogether() {
        XCTAssertThrowsError(
            try UpdatePageCommand.parse(["101", "home", "--body", "<p>x</p>", "--body-file", "x.html"])
        )
    }

    func testUpdateAssignmentRequiresAChange() {
        XCTAssertThrowsError(try UpdateAssignmentCommand.parse(["101", "501"]))
    }

    func testCreateAssignmentRequiresName() {
        XCTAssertThrowsError(try CreateAssignmentCommand.parse(["101"]))
    }

    func testCreateAssignmentParsesContentPointsAndDates() throws {
        let command = try CreateAssignmentCommand.parse([
            "101",
            "--name", "Value Study",
            "--description-file", "value-study.html",
            "--points", "75",
            "--published", "false",
            "--due-at", "2026-09-19T23:59:59-05:00",
            "--unlock-at", "2026-09-01T00:00:00-05:00",
            "--lock-at", "2026-09-21T23:59:59-05:00",
        ])
        XCTAssertEqual(command.courseID, 101)
        XCTAssertEqual(command.name, "Value Study")
        XCTAssertEqual(command.descriptionFile, "value-study.html")
        XCTAssertEqual(command.points, 75)
        XCTAssertEqual(command.published, false)
        XCTAssertEqual(command.dueAt, "2026-09-19T23:59:59-05:00")
        XCTAssertEqual(command.unlockAt, "2026-09-01T00:00:00-05:00")
        XCTAssertEqual(command.lockAt, "2026-09-21T23:59:59-05:00")
    }

    func testCreateAssignmentRejectsDescriptionAndFileTogether() {
        XCTAssertThrowsError(
            try CreateAssignmentCommand.parse([
                "101", "--name", "Value Study", "--description", "<p>x</p>", "--description-file", "x.html",
            ])
        )
    }

    func testCreateAssignmentRejectsDateWithoutTimeZone() {
        XCTAssertThrowsError(
            try CreateAssignmentCommand.parse([
                "101", "--name", "Value Study", "--due-at", "2026-09-19T23:59:59",
            ])
        )
    }

    func testDeleteAssignmentParsesCourseAndID() throws {
        let command = try DeleteAssignmentCommand.parse(["101", "502"])
        XCTAssertEqual(command.courseID, 101)
        XCTAssertEqual(command.assignmentID, 502)
    }

    func testUpdateAssignmentParsesPointsAndDueAt() throws {
        let command = try UpdateAssignmentCommand.parse(
            ["101", "501", "--points", "42.5", "--due-at", "2026-09-05T23:59:00-05:00"]
        )
        XCTAssertEqual(command.points, 42.5)
        XCTAssertEqual(command.dueAt, "2026-09-05T23:59:00-05:00")
    }

    func testUpdateAssignmentParsesAvailabilityDates() throws {
        let command = try UpdateAssignmentCommand.parse(
            ["101", "501", "--unlock-at", "2026-08-24T00:00:00-05:00", "--lock-at", "2026-09-13T23:59:00Z"]
        )
        XCTAssertEqual(command.unlockAt, "2026-08-24T00:00:00-05:00")
        XCTAssertEqual(command.lockAt, "2026-09-13T23:59:00Z")
    }

    func testUpdateAssignmentUnlockAtAloneCountsAsAChange() {
        XCTAssertNoThrow(try UpdateAssignmentCommand.parse(["101", "501", "--unlock-at", "2026-08-24T00:00:00Z"]))
    }

    func testUpdateAssignmentRejectsDateWithoutTimeZone() {
        XCTAssertThrowsError(try UpdateAssignmentCommand.parse(["101", "501", "--due-at", "2026-09-05T23:59:00"]))
    }

    func testUpdateAssignmentRejectsNonDate() {
        XCTAssertThrowsError(try UpdateAssignmentCommand.parse(["101", "501", "--lock-at", "next friday"]))
    }

    func testUpdatePagePublishAtAloneCountsAsAChange() {
        XCTAssertNoThrow(try UpdatePageCommand.parse(["101", "home", "--publish-at", "2026-08-24T08:00:00-05:00"]))
    }

    func testUpdatePageRejectsDateWithoutTimeZone() {
        XCTAssertThrowsError(try UpdatePageCommand.parse(["101", "home", "--publish-at", "2026-08-24T08:00:00"]))
    }

    func testSubmissionsParsesAssignmentsAndState() throws {
        let command = try SubmissionsCommand.parse(
            ["101", "--assignment", "501", "--assignment", "502", "--state", "not-submitted"]
        )
        XCTAssertEqual(command.courseID, 101)
        XCTAssertEqual(command.assignment, [501, 502])
        XCTAssertEqual(command.state, .notSubmitted)
    }

    func testSubmissionsParsesEveryStatus() throws {
        let values = ["not-submitted", "needs-grading", "graded", "excused"]
        let parsed = try values.map { try SubmissionsCommand.parse(["101", "--state", $0]).state }
        XCTAssertEqual(parsed, [.notSubmitted, .needsGrading, .graded, .excused])
    }

    func testSubmissionsDefaultsToAllAssignmentsAndStates() throws {
        let command = try SubmissionsCommand.parse(["101"])
        XCTAssertEqual(command.assignment, [])
        XCTAssertNil(command.state)
    }

    func testSubmissionsRejectsUnknownState() {
        // A typo must fail, not silently fall back to every state.
        XCTAssertThrowsError(try SubmissionsCommand.parse(["101", "--state", "not-submited"]))
        // Canvas's raw workflow states aren't easel statuses.
        XCTAssertThrowsError(try SubmissionsCommand.parse(["101", "--state", "unsubmitted"]))
        XCTAssertThrowsError(try SubmissionsCommand.parse(["101", "--state", "pending_review"]))
    }

    func testUsersParsesEnrollmentType() throws {
        let command = try UsersCommand.parse(["101", "--enrollment-type", "student"])
        XCTAssertEqual(command.enrollmentType, "student")
    }

    func testAnonymousFlagOnlyTurnsOn() throws {
        // Absent ⇒ false, so env/.env alone can still turn it on.
        XCTAssertFalse(try UsersCommand.parse(["101"]).options.anonymous)
        XCTAssertTrue(try UsersCommand.parse(["101", "--anonymous"]).options.anonymous)
    }

    func testNoAnonymousFlagIsRejected() {
        // Anonymous mode is one-way; there is no --no-anonymous override.
        XCTAssertThrowsError(try UsersCommand.parse(["101", "--no-anonymous"]))
    }

    func testCreateRubricRequiresAssignmentAndFile() {
        XCTAssertThrowsError(try CreateRubricCommand.parse(["101"]))
    }

    func testCreateRubricParsesGradingFlagInversion() throws {
        let command = try CreateRubricCommand.parse(
            ["101", "--assignment", "501", "--file", "rubric.json", "--no-use-for-grading"]
        )
        XCTAssertEqual(command.assignment, 501)
        XCTAssertEqual(command.file, "rubric.json")
        XCTAssertFalse(command.useForGrading)
    }

    func testUpdateRubricParsesWithoutAssignment() throws {
        let command = try UpdateRubricCommand.parse(["101", "9", "--file", "rubric.json"])
        XCTAssertEqual(command.rubricID, 9)
        XCTAssertNil(command.assignment)
        XCTAssertTrue(command.useForGrading)
    }

    func testDeleteRubricParsesCourseAndID() throws {
        let command = try DeleteRubricCommand.parse(["101", "9"])
        XCTAssertEqual(command.courseID, 101)
        XCTAssertEqual(command.rubricID, 9)
    }
}
