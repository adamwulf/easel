import Foundation

public extension CanvasClient {
    /// Lists every active student's submissions in a course, with each
    /// submission's user included. Students with concluded or inactive
    /// enrollments are left out.
    /// - Parameters:
    ///   - assignmentIDs: Only submissions for these assignments; empty means
    ///     every assignment in the course.
    ///   - state: Only submissions in this workflow state; nil means all states.
    func submissions(
        courseID: Int,
        assignmentIDs: [Int] = [],
        state: SubmissionState? = nil
    ) async throws -> [Submission] {
        var query = [
            URLQueryItem(name: "student_ids[]", value: "all"),
            URLQueryItem(name: "enrollment_state", value: "active"),
            URLQueryItem(name: "include[]", value: "user")
        ]
        for assignmentID in assignmentIDs {
            query.append(URLQueryItem(name: "assignment_ids[]", value: String(assignmentID)))
        }
        if let state {
            query.append(URLQueryItem(name: "workflow_state", value: state.rawValue))
        }
        return try await fetchAll("courses/\(courseID)/students/submissions", query: query)
    }
}
