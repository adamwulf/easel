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

    func testUsersParsesEnrollmentType() throws {
        let command = try UsersCommand.parse(["101", "--enrollment-type", "student"])
        XCTAssertEqual(command.enrollmentType, "student")
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
