import ArgumentParser
import XCTest
@testable import easel

/// Argument-parsing tests only — no command is run, so nothing needs a network
/// or an API key.
final class ParsingTests: XCTestCase {
    func testRootListsAllSubcommands() {
        XCTAssertEqual(Easel.configuration.subcommands.count, 12)
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

    func testUsersParsesEnrollmentType() throws {
        let command = try UsersCommand.parse(["101", "--enrollment-type", "student"])
        XCTAssertEqual(command.enrollmentType, "student")
    }

    func testAnonymousFlagIsTriState() throws {
        // Unset ⇒ nil, so resolution can fall back to env/.env.
        XCTAssertNil(try UsersCommand.parse(["101"]).options.anonymous)
        XCTAssertEqual(try UsersCommand.parse(["101", "--anonymous"]).options.anonymous, true)
        XCTAssertEqual(try UsersCommand.parse(["101", "--no-anonymous"]).options.anonymous, false)
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
}
