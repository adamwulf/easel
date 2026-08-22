import EaselKit
import XCTest

final class LinkHeaderTests: XCTestCase {
    func testParsesNextFromCanvasStyleHeader() {
        let header = "<https://school.instructure.com/api/v1/courses?page=1&per_page=100>; rel=\"current\","
            + "<https://school.instructure.com/api/v1/courses?page=2&per_page=100>; rel=\"next\","
            + "<https://school.instructure.com/api/v1/courses?page=1&per_page=100>; rel=\"first\","
            + "<https://school.instructure.com/api/v1/courses?page=3&per_page=100>; rel=\"last\""
        XCTAssertEqual(
            LinkHeader.nextPageURL(from: header)?.absoluteString,
            "https://school.instructure.com/api/v1/courses?page=2&per_page=100"
        )
    }

    func testNoNextReturnsNil() {
        let header = "<https://school.instructure.com/api/v1/courses?page=3>; rel=\"last\""
        XCTAssertNil(LinkHeader.nextPageURL(from: header))
    }

    func testNilHeaderReturnsNil() {
        XCTAssertNil(LinkHeader.nextPageURL(from: nil))
    }

    func testUnquotedRelIsAccepted() {
        let header = "<https://example.com/api/v1/courses?page=2>; rel=next"
        XCTAssertEqual(
            LinkHeader.nextPageURL(from: header)?.absoluteString,
            "https://example.com/api/v1/courses?page=2"
        )
    }
}
