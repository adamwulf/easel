import EaselKit
import Foundation
import XCTest

final class OutputFormatterTests: XCTestCase {
    private func decodeCourses() throws -> [Course] {
        try CanvasJSON.makeDecoder().decode([Course].self, from: Data(Fixtures.coursesPage1.utf8))
    }

    func testIDFormatPrintsOneIDPerLine() throws {
        let courses = try decodeCourses()
        XCTAssertEqual(try OutputFormatter.render(courses, format: .id), "101\n102")
    }

    func testJSONLFormatPrintsOneObjectPerLine() throws {
        let courses = try decodeCourses()
        let lines = try OutputFormatter.render(courses, format: .jsonl).split(separator: "\n")
        XCTAssertEqual(lines.count, 2)
        for line in lines {
            XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(line.utf8)))
        }
    }

    func testJSONFormatKeepsCanvasFieldNames() throws {
        let courses = try decodeCourses()
        let rendered = try OutputFormatter.render(courses, format: .json)
        XCTAssertTrue(rendered.contains("\"course_code\""))
        XCTAssertTrue(rendered.contains("\"workflow_state\""))
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(rendered.utf8)))
    }

    func testSingleItemJSONIsAnObjectNotAList() throws {
        let course = try XCTUnwrap(decodeCourses().first)
        let rendered = try OutputFormatter.render(course, format: .json)
        XCTAssertTrue(rendered.hasPrefix("{"))
        XCTAssertEqual(try OutputFormatter.render(course, format: .id), "101")
    }

    // MARK: - smalljsonl

    func testSmallJSONLPrintsOneValidObjectPerLine() throws {
        let courses = try decodeCourses()
        let lines = try OutputFormatter.render(courses, format: .smalljsonl).split(separator: "\n")
        XCTAssertEqual(lines.count, 2)
        for line in lines {
            XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(line.utf8)))
        }
    }

    func testSmallJSONLKeepsOnlySummaryFields() throws {
        let course = try XCTUnwrap(decodeCourses().first)
        let rendered = try OutputFormatter.render(course, format: .smalljsonl)
        // Kept: id, name, course_code, workflow_state, total_students.
        XCTAssertTrue(rendered.contains("\"course_code\":\"ART-101\""))
        XCTAssertTrue(rendered.contains("\"total_students\":18"))
        // Dropped bloat: not part of the summary set.
        XCTAssertFalse(rendered.contains("account_id"))
        XCTAssertFalse(rendered.contains("enrollment_term_id"))
        XCTAssertFalse(rendered.contains("start_at"))
    }

    func testSmallJSONLDropsNilFields() throws {
        // Course 102 has no total_students, so the key is absent, not null.
        let course = try XCTUnwrap(decodeCourses().last)
        let rendered = try OutputFormatter.render(course, format: .smalljsonl)
        XCTAssertFalse(rendered.contains("total_students"))
        XCTAssertFalse(rendered.contains("null"))
    }

    func testSmallJSONLRendersDatesAsISO8601() throws {
        let assignment = try CanvasJSON.makeDecoder()
            .decode(Assignment.self, from: Data(Fixtures.assignmentShow.utf8))
        let rendered = try OutputFormatter.render(assignment, format: .smalljsonl)
        XCTAssertTrue(rendered.contains("\"due_at\":\"2026-09-05T04:59:59Z\""))
    }

    // MARK: - md

    func testMarkdownHasHeadingAndFields() throws {
        let course = try XCTUnwrap(decodeCourses().first)
        let rendered = try OutputFormatter.render(course, format: .md)
        XCTAssertTrue(rendered.hasPrefix("## Intro to Drawing (#101)"))
        XCTAssertTrue(rendered.contains("- **course_code:** ART-101"))
        XCTAssertTrue(rendered.contains("- **workflow_state:** available"))
    }

    func testMarkdownDropsNilFields() throws {
        // Course 102 has no end_at or total_students.
        let course = try XCTUnwrap(decodeCourses().last)
        let rendered = try OutputFormatter.render(course, format: .md)
        XCTAssertFalse(rendered.contains("**end_at:**"))
        XCTAssertFalse(rendered.contains("**total_students:**"))
    }

    func testMarkdownListSeparatesRecordsWithBlankLine() throws {
        let rendered = try OutputFormatter.render(try decodeCourses(), format: .md)
        XCTAssertTrue(rendered.contains("## Intro to Drawing (#101)"))
        XCTAssertTrue(rendered.contains("\n\n## Advanced Painting (#102)"))
    }

    func testMarkdownEscapesInlineMetacharacters() throws {
        let json = #"{ "id": 1, "name": "A *bold* [x]" }"#
        let course = try CanvasJSON.makeDecoder().decode(Course.self, from: Data(json.utf8))
        let rendered = try OutputFormatter.render(course, format: .md)
        XCTAssertTrue(rendered.hasPrefix(#"## A \*bold\* \[x\] (#1)"#))
    }

    func testMarkdownFallsBackToUntitled() throws {
        let json = #"{ "id": 1 }"#
        let course = try CanvasJSON.makeDecoder().decode(Course.self, from: Data(json.utf8))
        let rendered = try OutputFormatter.render(course, format: .md)
        XCTAssertTrue(rendered.hasPrefix("## Untitled (#1)"))
    }

    func testMarkdownAssignmentRendersDescriptionAndRubricTable() throws {
        let assignment = try CanvasJSON.makeDecoder()
            .decode(Assignment.self, from: Data(Fixtures.assignmentShow.utf8))
        let rendered = try OutputFormatter.render(assignment, format: .md)
        XCTAssertTrue(rendered.contains("- **points_possible:** 100"))
        XCTAssertTrue(rendered.contains("- **html_url:** <https://example.instructure.com/courses/101/assignments/501>"))
        // Description is HTML, passed through verbatim.
        XCTAssertTrue(rendered.contains("<p>Draw yourself in charcoal.</p>"))
        // Rubric criteria table.
        XCTAssertTrue(rendered.contains("### Portrait Rubric (100 pts)"))
        XCTAssertTrue(rendered.contains("| Criterion | Points | Ratings |"))
        XCTAssertTrue(rendered.contains("| Likeness | 60 | Strong (60), Developing (30) |"))
    }

    func testMarkdownPagePassesBodyThrough() throws {
        let page = try CanvasJSON.makeDecoder()
            .decode(Page.self, from: Data(Fixtures.pageShow.utf8))
        let rendered = try OutputFormatter.render(page, format: .md)
        XCTAssertTrue(rendered.hasPrefix("## Course Syllabus (course-syllabus)"))
        XCTAssertTrue(rendered.contains("<h2>Welcome</h2><p>Bring a sketchbook to every class.</p>"))
    }

    func testMarkdownUserRendersEnrollmentsTable() throws {
        let users = try CanvasJSON.makeDecoder()
            .decode([CourseUser].self, from: Data(Fixtures.usersList.utf8))
        let rendered = try OutputFormatter.render(users, format: .md)
        XCTAssertTrue(rendered.contains("## Alex Rivera (#9001)"))
        XCTAssertTrue(rendered.contains("- **email:** arivera@example.edu"))
        XCTAssertTrue(rendered.contains("### Enrollments"))
        XCTAssertTrue(rendered.contains("| StudentEnrollment | StudentEnrollment | active | 42 |"))
    }
}
