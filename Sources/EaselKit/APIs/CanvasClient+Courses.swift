import Foundation

public extension CanvasClient {
    /// Lists the caller's courses.
    /// - Parameters:
    ///   - enrollmentType: Only courses where the caller has this role
    ///     (teacher, student, ta, observer, designer).
    ///   - state: Only courses in this state (unpublished, available, completed).
    func courses(enrollmentType: String? = nil, state: String? = nil) async throws -> [Course] {
        var query: [URLQueryItem] = []
        if let enrollmentType {
            query.append(URLQueryItem(name: "enrollment_type", value: enrollmentType))
        }
        if let state {
            query.append(URLQueryItem(name: "state[]", value: state))
        }
        return try await fetchAll("courses", query: query)
    }
}
