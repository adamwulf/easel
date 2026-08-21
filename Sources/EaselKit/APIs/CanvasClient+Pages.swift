import Foundation

public extension CanvasClient {
    /// Lists a course's wiki pages, sorted by title. Bodies are not included;
    /// fetch a single page for its body.
    func pages(courseID: Int, searchTerm: String? = nil) async throws -> [Page] {
        var query = [URLQueryItem(name: "sort", value: "title")]
        if let searchTerm {
            query.append(URLQueryItem(name: "search_term", value: searchTerm))
        }
        return try await fetchAll("courses/\(courseID)/pages", query: query)
    }

    /// Fetches one page, including its body. `urlOrID` is the page's url slug;
    /// pass `page_id:<id>` to force lookup by id.
    func page(courseID: Int, urlOrID: String) async throws -> Page {
        try await api.get("courses/\(courseID)/pages/\(urlOrID)")
    }

    /// Updates a page's title, body, and/or published state.
    func updatePage(courseID: Int, urlOrID: String, update: PageUpdate) async throws -> Page {
        try await api.put("courses/\(courseID)/pages/\(urlOrID)", body: PageUpdateBody(wikiPage: update))
    }
}
