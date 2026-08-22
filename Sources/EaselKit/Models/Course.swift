import Foundation

/// A Canvas course. Most fields are optional so decoding stays tolerant of
/// instance-specific payload differences.
public struct Course: Codable, Sendable, Equatable, CanvasRow {
    public let id: Int
    public let name: String?
    public let courseCode: String?
    public let workflowState: String?
    public let accountID: Int?
    public let enrollmentTermID: Int?
    public let startAt: Date?
    public let endAt: Date?
    public let defaultView: String?
    public let totalStudents: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case courseCode = "course_code"
        case workflowState = "workflow_state"
        case accountID = "account_id"
        case enrollmentTermID = "enrollment_term_id"
        case startAt = "start_at"
        case endAt = "end_at"
        case defaultView = "default_view"
        case totalStudents = "total_students"
    }

    public var rowID: String {
        String(id)
    }

    public var summaryRow: SummaryRow {
        SummaryRow([
            ("id", .int(id)),
            ("name", name.map(JSONScalar.string)),
            ("course_code", courseCode.map(JSONScalar.string)),
            ("workflow_state", workflowState.map(JSONScalar.string)),
            ("total_students", totalStudents.map(JSONScalar.int)),
        ])
    }

    public var markdownRow: String {
        Markdown.document(
            heading: Markdown.heading(2, name, handle: "#\(id)"),
            fields: [
                Markdown.field("course_code", courseCode),
                Markdown.field("workflow_state", workflowState),
                Markdown.field("start_at", Markdown.date(startAt)),
                Markdown.field("end_at", Markdown.date(endAt)),
                Markdown.field("default_view", defaultView),
                Markdown.field("total_students", Markdown.int(totalStudents)),
                Markdown.field("account_id", Markdown.int(accountID)),
                Markdown.field("enrollment_term_id", Markdown.int(enrollmentTermID)),
            ]
        )
    }
}
