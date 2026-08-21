import Foundation

/// A Canvas wiki page. Pages are addressed by their `url` slug (or by
/// `page_id:<id>` to force an id lookup).
public struct Page: Codable, Sendable, Equatable, CanvasRow {
    public let pageID: Int
    public let url: String
    public let title: String?
    public let body: String?
    public let published: Bool?
    public let frontPage: Bool?
    public let editingRoles: String?
    public let lockedForUser: Bool?
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case pageID = "page_id"
        case url
        case title
        case body
        case published
        case frontPage = "front_page"
        case editingRoles = "editing_roles"
        case lockedForUser = "locked_for_user"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public var rowID: String {
        url
    }
}

/// The fields that can change on a page. Nil fields are omitted from the
/// request, so Canvas leaves them untouched.
public struct PageUpdate: Encodable, Sendable, Equatable {
    public let title: String?
    public let body: String?
    public let published: Bool?

    public init(title: String? = nil, body: String? = nil, published: Bool? = nil) {
        self.title = title
        self.body = body
        self.published = published
    }
}

struct PageUpdateBody: Encodable, Sendable {
    let wikiPage: PageUpdate

    enum CodingKeys: String, CodingKey {
        case wikiPage = "wiki_page"
    }
}
