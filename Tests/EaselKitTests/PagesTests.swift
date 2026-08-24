import EaselKit
import Foundation
import XCTest

final class PagesTests: XCTestCase {
    func testListPages() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/pages", json: Fixtures.pagesList)
        let client = CanvasClient.stubbed(transport)

        let pages = try await client.pages(courseID: 101)

        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages[0].url, "course-syllabus")
        XCTAssertEqual(pages[0].rowID, "course-syllabus")
        XCTAssertEqual(pages[0].published, true)
        XCTAssertNil(pages[0].body)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.url.query?.contains("sort=title"), true)
    }

    func testSearchTermQuery() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/pages", json: Fixtures.pagesList)
        let client = CanvasClient.stubbed(transport)

        _ = try await client.pages(courseID: 101, searchTerm: "syllabus")

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.url.query?.contains("search_term=syllabus"), true)
    }

    func testShowPageIncludesBody() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/pages/course-syllabus", json: Fixtures.pageShow)
        let client = CanvasClient.stubbed(transport)

        let page = try await client.page(courseID: 101, urlOrID: "course-syllabus")

        XCTAssertEqual(page.pageID, 11)
        XCTAssertEqual(page.title, "Course Syllabus")
        XCTAssertEqual(page.body, "<h2>Welcome</h2><p>Bring a sketchbook to every class.</p>")
    }

    func testCreatePageSendsAllProvidedFields() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/pages", method: "POST", json: Fixtures.pageCreated)
        let client = CanvasClient.stubbed(transport)

        let draft = PageCreate(
            title: "Week 2 Materials",
            body: "<h2>Week 2</h2><p>Read before class.</p>",
            editingRoles: "teachers,students",
            notifyOfUpdate: true,
            published: true,
            frontPage: false,
            publishAt: "2026-08-31T08:00:00-05:00"
        )
        let page = try await client.createPage(courseID: 101, page: draft)

        XCTAssertEqual(page.pageID, 13)
        XCTAssertEqual(page.url, "week-2-materials")

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        let wikiPage = try XCTUnwrap(object["wiki_page"] as? [String: Any])
        XCTAssertEqual(wikiPage["title"] as? String, "Week 2 Materials")
        XCTAssertEqual(wikiPage["body"] as? String, "<h2>Week 2</h2><p>Read before class.</p>")
        XCTAssertEqual(wikiPage["editing_roles"] as? String, "teachers,students")
        XCTAssertEqual(wikiPage["notify_of_update"] as? Bool, true)
        XCTAssertEqual(wikiPage["published"] as? Bool, true)
        XCTAssertEqual(wikiPage["front_page"] as? Bool, false)
        XCTAssertEqual(wikiPage["publish_at"] as? String, "2026-08-31T08:00:00-05:00")
    }

    func testCreatePageOmitsOptionalFields() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/pages", method: "POST", json: Fixtures.pageCreated)
        let client = CanvasClient.stubbed(transport)

        _ = try await client.createPage(courseID: 101, page: PageCreate(title: "Week 2 Materials"))

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        let wikiPage = try XCTUnwrap(object["wiki_page"] as? [String: Any])
        XCTAssertEqual(wikiPage.count, 1)
        XCTAssertEqual(wikiPage["title"] as? String, "Week 2 Materials")
    }

    func testUpdatePageSendsOnlyProvidedFields() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/pages/course-syllabus", method: "PUT", json: Fixtures.pageUpdated)
        let client = CanvasClient.stubbed(transport)

        let update = PageUpdate(title: "Syllabus (Fall 2026)", body: "<h2>Welcome</h2><p>Updated for fall.</p>")
        let page = try await client.updatePage(courseID: 101, urlOrID: "course-syllabus", update: update)

        XCTAssertEqual(page.title, "Syllabus (Fall 2026)")

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.method, "PUT")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        let wikiPage = try XCTUnwrap(object["wiki_page"] as? [String: Any])
        XCTAssertEqual(wikiPage["title"] as? String, "Syllabus (Fall 2026)")
        XCTAssertEqual(wikiPage["body"] as? String, "<h2>Welcome</h2><p>Updated for fall.</p>")
        XCTAssertNil(wikiPage["published"], "nil fields must be omitted so Canvas leaves them untouched")
        XCTAssertNil(wikiPage["publish_at"])
    }

    func testUpdatePageSendsPublishAt() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/pages/week-1-materials", method: "PUT", json: Fixtures.pageUpdated)
        let client = CanvasClient.stubbed(transport)

        let update = PageUpdate(publishAt: "2026-08-24T08:00:00-05:00")
        _ = try await client.updatePage(courseID: 101, urlOrID: "week-1-materials", update: update)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        let wikiPage = try XCTUnwrap(object["wiki_page"] as? [String: Any])
        XCTAssertEqual(wikiPage["publish_at"] as? String, "2026-08-24T08:00:00-05:00")
        XCTAssertNil(wikiPage["title"])
        XCTAssertNil(wikiPage["body"])
    }

    func testDeletePageUsesDeleteAndReturnsPage() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/pages/week-2-materials", method: "DELETE", json: Fixtures.pageCreated)
        let client = CanvasClient.stubbed(transport)

        let page = try await client.deletePage(courseID: 101, urlOrID: "week-2-materials")

        XCTAssertEqual(page.pageID, 13)
        XCTAssertEqual(page.url, "week-2-materials")
        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.method, "DELETE")
        XCTAssertNil(request.body)
    }
}
