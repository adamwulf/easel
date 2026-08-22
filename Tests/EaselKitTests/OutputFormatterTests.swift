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
}
