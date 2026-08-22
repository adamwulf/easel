import Foundation

public extension CanvasClient {
    /// Lists the people in a course, with email and enrollments included when
    /// the caller's role can see them.
    /// - Parameters:
    ///   - enrollmentType: Only people with this role (teacher, student, ta,
    ///     observer, designer).
    ///   - searchTerm: Partial name or login to match.
    func users(courseID: Int, enrollmentType: String? = nil, searchTerm: String? = nil) async throws -> [CourseUser] {
        var query = [
            URLQueryItem(name: "include[]", value: "email"),
            URLQueryItem(name: "include[]", value: "enrollments")
        ]
        if let enrollmentType {
            query.append(URLQueryItem(name: "enrollment_type[]", value: enrollmentType))
        }
        if let searchTerm {
            query.append(URLQueryItem(name: "search_term", value: searchTerm))
        }
        return try await fetchAll("courses/\(courseID)/users", query: query)
    }
}
