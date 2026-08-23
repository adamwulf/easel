import Foundation

/// A person enrolled in a course. Email and enrollments appear when the list
/// request asks for them via `include[]` (the client does by default).
public struct CourseUser: Codable, Sendable, Equatable, CanvasRow {
    public let id: Int
    public let name: String?
    public let sortableName: String?
    public let shortName: String?
    public let sisUserID: String?
    public let loginID: String?
    public let email: String?
    public let pronouns: String?
    public let enrollments: [Enrollment]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortableName = "sortable_name"
        case shortName = "short_name"
        case sisUserID = "sis_user_id"
        case loginID = "login_id"
        case email
        case pronouns
        case enrollments
    }

    public var rowID: String {
        String(id)
    }

    public var summaryRow: SummaryRow {
        SummaryRow([
            ("id", .int(id)),
            ("name", name.map(JSONScalar.string)),
            ("email", email.map(JSONScalar.string)),
            ("login_id", loginID.map(JSONScalar.string)),
            ("pronouns", pronouns.map(JSONScalar.string)),
        ])
    }

    public var markdownRow: String {
        Markdown.document(
            heading: Markdown.heading(2, name, handle: "#\(id)"),
            fields: [
                Markdown.field("email", email),
                Markdown.field("login_id", loginID),
                Markdown.field("sis_user_id", sisUserID),
                Markdown.field("pronouns", pronouns),
                Markdown.field("short_name", shortName),
                Markdown.field("sortable_name", sortableName),
            ],
            sections: [enrollmentsSection]
        )
    }

    /// Returns a copy safe for anonymous output: no last names, no contact
    /// information. `name` and `short_name` become the first three letters of
    /// the given name plus a one-letter surname initial ("Adam Wulf" → "Ada W");
    /// `sortable_name` keeps Canvas's sort-by-surname ordering as
    /// "W, Ada". `email` and `login_id` (the only identifying addresses on a
    /// user) are dropped. The numeric id, sis_user_id, pronouns, and enrollments
    /// carry no name and are kept unchanged.
    public func anonymized() -> CourseUser {
        CourseUser(
            id: id,
            name: name.map(CourseUser.redactName),
            sortableName: sortableName.map(CourseUser.redactSortableName),
            shortName: shortName.map(CourseUser.redactName),
            sisUserID: sisUserID,
            loginID: nil,
            email: nil,
            pronouns: pronouns,
            enrollments: enrollments
        )
    }

    /// Reduces a "First Last" name to the first three letters of the given name
    /// plus a one-letter surname initial: "Adam Wulf" → "Ada W". A given name
    /// shorter than three letters contributes only what it has ("Jo Smith" →
    /// "Jo S"); middle names are dropped, so only the final token's initial is
    /// used ("Mary Jane Watson" → "Mar W"). A single-token name has no surname to
    /// abbreviate, so just its first three letters remain ("Prince" → "Pri").
    /// An empty name stays empty.
    static func redactName(_ full: String) -> String {
        let tokens = full.split(whereSeparator: { $0.isWhitespace })
        guard let first = tokens.first else { return full }
        let stub = String(first.prefix(3))
        guard tokens.count > 1, let initial = tokens.last?.first else { return stub }
        return "\(stub) \(initial)"
    }

    /// Reduces Canvas's "Last, First" sortable name to a surname initial plus the
    /// first three letters of the given name, keeping the sort-by-surname
    /// ordering: "Wulf, Adam" → "W, Ada". A value with no comma is treated as a
    /// plain name via `redactName`.
    static func redactSortableName(_ sortable: String) -> String {
        let parts = sortable.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return redactName(sortable) }
        let last = parts[0].trimmingCharacters(in: .whitespaces)
        let first = parts[1].trimmingCharacters(in: .whitespaces)
        let stub = String(first.prefix(3))
        guard let initial = last.first else { return stub }
        return "\(initial), \(stub)"
    }

    /// The user's enrollments rendered as a table, or nil when there are none.
    private var enrollmentsSection: String? {
        guard let enrollments, !enrollments.isEmpty else { return nil }
        let table = Markdown.table(
            headers: ["Type", "Role", "State", "Section"],
            rows: enrollments.map { enrollment in
                [
                    enrollment.type ?? "",
                    enrollment.role ?? "",
                    enrollment.enrollmentState ?? "",
                    enrollment.courseSectionID.map(String.init) ?? "",
                ]
            }
        )
        return Markdown.heading(3, "Enrollments") + "\n" + table
    }
}

/// One enrollment of a user in a course.
public struct Enrollment: Codable, Sendable, Equatable {
    public let type: String?
    public let role: String?
    public let enrollmentState: String?
    public let courseSectionID: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case role
        case enrollmentState = "enrollment_state"
        case courseSectionID = "course_section_id"
    }
}
