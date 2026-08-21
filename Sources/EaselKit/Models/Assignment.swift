import Foundation

/// A Canvas assignment. When Canvas has a rubric attached, `rubric` holds the
/// criteria and `rubricSettings` the rubric's identity and totals.
public struct Assignment: Codable, Sendable, Equatable, CanvasRow {
    public let id: Int
    public let name: String?
    public let description: String?
    public let dueAt: Date?
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

/// The fields that can change on an assignment. Nil fields are omitted from
/// the request, so Canvas leaves them untouched.
public struct AssignmentUpdate: Encodable, Sendable, Equatable {
    public let name: String?
    public let description: String?
    public let published: Bool?
    public let pointsPossible: Double?
    /// ISO 8601, passed through verbatim.
    public let dueAt: String?

    public init(
        name: String? = nil,
        description: String? = nil,
        published: Bool? = nil,
        pointsPossible: Double? = nil,
        dueAt: String? = nil
    ) {
        self.name = name
        self.description = description
        self.published = published
        self.pointsPossible = pointsPossible
        self.dueAt = dueAt
    }

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case published
        case pointsPossible = "points_possible"
        case dueAt = "due_at"
    }
}

struct AssignmentUpdateBody: Encodable, Sendable {
    let assignment: AssignmentUpdate
}
