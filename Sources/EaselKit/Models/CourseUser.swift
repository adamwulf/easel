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
