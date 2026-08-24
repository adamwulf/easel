import Foundation

/// A Canvas assignment. When Canvas has a rubric attached, `rubric` holds the
/// criteria and `rubricSettings` the rubric's identity and totals.
public struct Assignment: Codable, Sendable, Equatable, CanvasRow {
    public let id: Int
    public let name: String?
    public let description: String?
    public let dueAt: Date?
    public let unlockAt: Date?
    public let lockAt: Date?
    public let pointsPossible: Double?
    public let published: Bool?
    public let htmlURL: String?
    public let submissionTypes: [String]?
    public let courseID: Int?
    public let assignmentGroupID: Int?
    public let gradingType: String?
    public let rubric: [RubricCriterion]?
    public let rubricSettings: RubricSettings?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case dueAt = "due_at"
        case unlockAt = "unlock_at"
        case lockAt = "lock_at"
        case pointsPossible = "points_possible"
        case published
        case htmlURL = "html_url"
        case submissionTypes = "submission_types"
        case courseID = "course_id"
        case assignmentGroupID = "assignment_group_id"
        case gradingType = "grading_type"
        case rubric
        case rubricSettings = "rubric_settings"
    }

    public var rowID: String {
        String(id)
    }

    public var summaryRow: SummaryRow {
        SummaryRow([
            ("id", .int(id)),
            ("name", name.map(JSONScalar.string)),
            ("points_possible", pointsPossible.map(JSONScalar.double)),
            ("due_at", dueAt.map(JSONScalar.date)),
            ("published", published.map(JSONScalar.bool)),
            ("course_id", courseID.map(JSONScalar.int)),
        ])
    }

    public var markdownRow: String {
        Markdown.document(
            heading: Markdown.heading(2, name, handle: "#\(id)"),
            fields: [
                Markdown.field("points_possible", Markdown.number(pointsPossible)),
                Markdown.field("grading_type", gradingType),
                Markdown.field("due_at", Markdown.date(dueAt)),
                Markdown.field("unlock_at", Markdown.date(unlockAt)),
                Markdown.field("lock_at", Markdown.date(lockAt)),
                Markdown.field("published", Markdown.bool(published)),
                Markdown.field("submission_types", Markdown.list(submissionTypes)),
                Markdown.field("course_id", Markdown.int(courseID)),
                Markdown.urlField("html_url", htmlURL),
            ],
            // Description is stored as HTML; passed through verbatim.
            sections: [description, rubricSection]
        )
    }

    /// The attached rubric rendered as a criteria table, or nil when the
    /// assignment carries no rubric.
    private var rubricSection: String? {
        guard let rubric, !rubric.isEmpty else { return nil }
        var heading = Markdown.heading(3, rubricSettings?.title ?? "Rubric")
        if let points = Markdown.number(rubricSettings?.pointsPossible) {
            heading += " (\(points) pts)"
        }
        return heading + "\n" + rubric.markdownTable
    }
}

/// Summary of the rubric attached to an assignment.
public struct RubricSettings: Codable, Sendable, Equatable {
    public let id: Int?
    public let title: String?
    public let pointsPossible: Double?
    public let freeFormCriterionComments: Bool?
    public let hideScoreTotal: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case pointsPossible = "points_possible"
        case freeFormCriterionComments = "free_form_criterion_comments"
        case hideScoreTotal = "hide_score_total"
    }
}

/// The fields used to create an assignment. Canvas requires `name`; nil
/// optional fields are omitted from the request.
public struct AssignmentCreate: Encodable, Sendable, Equatable {
    public let name: String
    public let description: String?
    public let published: Bool?
    public let pointsPossible: Double?
    /// ISO 8601 with a time zone, passed through verbatim.
    public let dueAt: String?
    /// ISO 8601 with a time zone; the date the assignment becomes available.
    public let unlockAt: String?
    /// ISO 8601 with a time zone; the date the assignment locks.
    public let lockAt: String?

    public init(
        name: String,
        description: String? = nil,
        published: Bool? = nil,
        pointsPossible: Double? = nil,
        dueAt: String? = nil,
        unlockAt: String? = nil,
        lockAt: String? = nil
    ) {
        self.name = name
        self.description = description
        self.published = published
        self.pointsPossible = pointsPossible
        self.dueAt = dueAt
        self.unlockAt = unlockAt
        self.lockAt = lockAt
    }

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case published
        case pointsPossible = "points_possible"
        case dueAt = "due_at"
        case unlockAt = "unlock_at"
        case lockAt = "lock_at"
    }
}

/// The fields that can change on an assignment. Nil fields are omitted from
/// the request, so Canvas leaves them untouched.
public struct AssignmentUpdate: Encodable, Sendable, Equatable {
    public let name: String?
    public let description: String?
    public let published: Bool?
    public let pointsPossible: Double?
    /// ISO 8601 with a time zone, passed through verbatim.
    public let dueAt: String?
    /// ISO 8601 with a time zone; the date the assignment becomes available.
    public let unlockAt: String?
    /// ISO 8601 with a time zone; the date the assignment locks.
    public let lockAt: String?

    public init(
        name: String? = nil,
        description: String? = nil,
        published: Bool? = nil,
        pointsPossible: Double? = nil,
        dueAt: String? = nil,
        unlockAt: String? = nil,
        lockAt: String? = nil
    ) {
        self.name = name
        self.description = description
        self.published = published
        self.pointsPossible = pointsPossible
        self.dueAt = dueAt
        self.unlockAt = unlockAt
        self.lockAt = lockAt
    }

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case published
        case pointsPossible = "points_possible"
        case dueAt = "due_at"
        case unlockAt = "unlock_at"
        case lockAt = "lock_at"
    }
}

struct AssignmentCreateBody: Encodable, Sendable {
    let assignment: AssignmentCreate
}

struct AssignmentUpdateBody: Encodable, Sendable {
    let assignment: AssignmentUpdate
}
