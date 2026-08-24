import Foundation

/// A Canvas wiki page. Pages are addressed by their `url` slug (or by
/// `page_id:<id>` to force an id lookup).
public struct Page: Codable, Sendable, Equatable, CanvasRow {
    public let pageID: Int
    public let url: String
    public let title: String?
    public let body: String?
    public let published: Bool?
    public let publishAt: Date?
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
        case publishAt = "publish_at"
        case frontPage = "front_page"
        case editingRoles = "editing_roles"
        case lockedForUser = "locked_for_user"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public var rowID: String {
        url
    }

    public var summaryRow: SummaryRow {
        SummaryRow([
            ("page_id", .int(pageID)),
            ("url", .string(url)),
            ("title", title.map(JSONScalar.string)),
            ("published", published.map(JSONScalar.bool)),
            ("front_page", frontPage.map(JSONScalar.bool)),
            ("updated_at", updatedAt.map(JSONScalar.date)),
        ])
    }

    public var markdownRow: String {
        Markdown.document(
            heading: Markdown.heading(2, title, handle: url),
            fields: [
                Markdown.field("published", Markdown.bool(published)),
                Markdown.field("front_page", Markdown.bool(frontPage)),
                Markdown.field("editing_roles", editingRoles),
                Markdown.field("locked_for_user", Markdown.bool(lockedForUser)),
                Markdown.field("publish_at", Markdown.date(publishAt)),
                Markdown.field("created_at", Markdown.date(createdAt)),
                Markdown.field("updated_at", Markdown.date(updatedAt)),
            ],
            // The body is stored as HTML; passed through verbatim.
            sections: [body]
        )
    }
}

/// The fields used to create a page. Canvas requires a title; nil optional
/// fields are omitted so Canvas can apply its course defaults.
public struct PageCreate: Encodable, Sendable, Equatable {
    public let title: String
    public let body: String?
    public let editingRoles: String?
    public let notifyOfUpdate: Bool?
    public let published: Bool?
    public let frontPage: Bool?
    /// ISO 8601 with a time zone; schedules a future publication date. Only
    /// takes effect when the Canvas account has the Scheduled Page Publication
    /// feature enabled.
    public let publishAt: String?

    public init(
        title: String,
        body: String? = nil,
        editingRoles: String? = nil,
        notifyOfUpdate: Bool? = nil,
        published: Bool? = nil,
        frontPage: Bool? = nil,
        publishAt: String? = nil
    ) {
        self.title = title
        self.body = body
        self.editingRoles = editingRoles
        self.notifyOfUpdate = notifyOfUpdate
        self.published = published
        self.frontPage = frontPage
        self.publishAt = publishAt
    }

    enum CodingKeys: String, CodingKey {
        case title
        case body
        case editingRoles = "editing_roles"
        case notifyOfUpdate = "notify_of_update"
        case published
        case frontPage = "front_page"
        case publishAt = "publish_at"
    }
}

/// The fields that can change on a page. Nil fields are omitted from the
/// request, so Canvas leaves them untouched.
public struct PageUpdate: Encodable, Sendable, Equatable {
    public let title: String?
    public let body: String?
    public let published: Bool?
    /// ISO 8601 with a time zone; schedules a future publication date. Only
    /// takes effect when the Canvas account has the Scheduled Page Publication
    /// feature enabled. (Pages have no unlock/lock dates in the Canvas API.)
    public let publishAt: String?

    public init(title: String? = nil, body: String? = nil, published: Bool? = nil, publishAt: String? = nil) {
        self.title = title
        self.body = body
        self.published = published
        self.publishAt = publishAt
    }

    enum CodingKeys: String, CodingKey {
        case title
        case body
        case published
        case publishAt = "publish_at"
    }
}

struct PageCreateBody: Encodable, Sendable {
    let wikiPage: PageCreate

    enum CodingKeys: String, CodingKey {
        case wikiPage = "wiki_page"
    }
}

struct PageUpdateBody: Encodable, Sendable {
    let wikiPage: PageUpdate

    enum CodingKeys: String, CodingKey {
        case wikiPage = "wiki_page"
    }
}
