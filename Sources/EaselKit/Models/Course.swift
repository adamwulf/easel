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
}
