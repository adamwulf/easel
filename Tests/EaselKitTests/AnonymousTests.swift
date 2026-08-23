import Foundation
import XCTest
@testable import EaselKit

/// Proves anonymous mode redacts user-identifying data in every output format,
/// and that the default (non-anonymous) path is untouched. Fully offline.
final class AnonymousTests: XCTestCase {
    private func decodeUsers() throws -> [CourseUser] {
        try CanvasJSON.makeDecoder().decode([CourseUser].self, from: Data(Fixtures.usersList.utf8))
    }

    private func decodeUser(_ json: String) throws -> CourseUser {
        try CanvasJSON.makeDecoder().decode(CourseUser.self, from: Data(json.utf8))
    }

    // MARK: - Field-level redaction

    func testAnonymizedRedactsNamesAndDropsContact() throws {
        let user = try XCTUnwrap(decodeUsers().first)
        let redacted = user.anonymized()

        // The id is a stable handle, not a name — kept.
        XCTAssertEqual(redacted.id, 9001)
        // Names reduced to first-three-letters + surname initial.
        XCTAssertEqual(redacted.name, "Ale R")
        XCTAssertEqual(redacted.sortableName, "R, Ale")
        XCTAssertEqual(redacted.shortName, "Ale")
        // Contact info dropped entirely.
        XCTAssertNil(redacted.email)
        XCTAssertNil(redacted.loginID)
        // Non-name metadata kept.
        XCTAssertEqual(redacted.pronouns, "they/them")
        XCTAssertEqual(redacted.sisUserID, "S0001")
        XCTAssertEqual(redacted.enrollments?.first?.type, "StudentEnrollment")
    }

    func testAnonymizedTeacherWithoutEmailOrShortName() throws {
        let user = try XCTUnwrap(decodeUsers().last)
        let redacted = user.anonymized()
        XCTAssertEqual(redacted.name, "Sam C")
        XCTAssertEqual(redacted.sortableName, "C, Sam")
        XCTAssertNil(redacted.shortName)
        XCTAssertNil(redacted.loginID)
        XCTAssertNil(redacted.email)
    }

    func testAnonymizedLeavesNilNameFieldsNil() throws {
        let user = try decodeUser(#"{ "id": 1 }"#)
        let redacted = user.anonymized()
        XCTAssertNil(redacted.name)
        XCTAssertNil(redacted.sortableName)
        XCTAssertNil(redacted.shortName)
    }

    // MARK: - Name-redaction helpers

    func testRedactName() {
        // First three letters of the given name + surname initial.
        XCTAssertEqual(CourseUser.redactName("Adam Wulf"), "Ada W")
        XCTAssertEqual(CourseUser.redactName("Alex Rivera"), "Ale R")
        // Middle names drop; only the final token's initial is used.
        XCTAssertEqual(CourseUser.redactName("Mary Jane Watson"), "Mar W")
        // Extra whitespace between tokens collapses cleanly.
        XCTAssertEqual(CourseUser.redactName("Alex   Rivera"), "Ale R")
        // A first name shorter than three letters contributes what it has.
        XCTAssertEqual(CourseUser.redactName("Jo Smith"), "Jo S")
        XCTAssertEqual(CourseUser.redactName("Al Green"), "Al G")
        // A single token has no surname — just its first three letters.
        XCTAssertEqual(CourseUser.redactName("Prince"), "Pri")
        XCTAssertEqual(CourseUser.redactName("Bo"), "Bo")
        XCTAssertEqual(CourseUser.redactName(""), "")
    }

    func testRedactSortableName() {
        XCTAssertEqual(CourseUser.redactSortableName("Wulf, Adam"), "W, Ada")
        XCTAssertEqual(CourseUser.redactSortableName("Rivera, Alex"), "R, Ale")
        XCTAssertEqual(CourseUser.redactSortableName("Watson, Mary Jane"), "W, Mar")
        // Lowercase surname particles keep their real initial.
        XCTAssertEqual(CourseUser.redactSortableName("van Gogh, Vincent"), "v, Vin")
        // No comma ⇒ treated like a plain name.
        XCTAssertEqual(CourseUser.redactSortableName("Cher"), "Che")
    }

    // MARK: - Output formats hide the redacted data

    func testJSONOutputHidesLastNamesAndContact() throws {
        let redacted = try decodeUsers().map { $0.anonymized() }
        let rendered = try OutputFormatter.render(redacted, format: .json)

        // Last names, emails, and login ids are gone.
        XCTAssertFalse(rendered.contains("Rivera"))
        XCTAssertFalse(rendered.contains("Chen"))
        XCTAssertFalse(rendered.contains("arivera@example.edu"))
        XCTAssertFalse(rendered.contains("\"arivera\""))
        XCTAssertFalse(rendered.contains("\"schen\""))
        // Redacted stubs, initials, and ids remain usable.
        XCTAssertTrue(rendered.contains("Ale R"))
        XCTAssertTrue(rendered.contains("Sam C"))
        XCTAssertTrue(rendered.contains("9001"))
    }

    func testMarkdownOutputHidesLastNamesAndContact() throws {
        let redacted = try decodeUsers().map { $0.anonymized() }
        let rendered = try OutputFormatter.render(redacted, format: .md)

        XCTAssertTrue(rendered.contains("## Ale R (#9001)"))
        XCTAssertFalse(rendered.contains("Rivera"))
        XCTAssertFalse(rendered.contains("**email:**"))
        XCTAssertFalse(rendered.contains("**login_id:**"))
        // Enrollments (no name data) still render.
        XCTAssertTrue(rendered.contains("### Enrollments"))
    }

    func testSmallJSONLOutputDropsContactKeys() throws {
        let redacted = try XCTUnwrap(decodeUsers().first).anonymized()
        let rendered = try OutputFormatter.render(redacted, format: .smalljsonl)

        XCTAssertTrue(rendered.contains("\"name\":\"Ale R\""))
        XCTAssertTrue(rendered.contains("\"pronouns\":\"they/them\""))
        // Nil email/login_id drop out of the summary entirely.
        XCTAssertFalse(rendered.contains("email"))
        XCTAssertFalse(rendered.contains("login_id"))
        XCTAssertFalse(rendered.contains("Rivera"))
    }

    func testIDFormatIsUnaffected() throws {
        let redacted = try decodeUsers().map { $0.anonymized() }
        XCTAssertEqual(try OutputFormatter.render(redacted, format: .id), "9001\n9002")
    }

    // MARK: - Default (non-anonymous) output is unchanged

    func testDefaultOutputKeepsFullNamesAndContact() throws {
        let users = try decodeUsers()
        let rendered = try OutputFormatter.render(users, format: .json)
        XCTAssertTrue(rendered.contains("Alex Rivera"))
        XCTAssertTrue(rendered.contains("Rivera, Alex"))
        XCTAssertTrue(rendered.contains("arivera@example.edu"))
        XCTAssertTrue(rendered.contains("arivera"))
    }
}
