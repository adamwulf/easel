import Foundation

public extension CanvasClient {
    /// Lists every active student's submissions in a course, with each
    /// submission's user included. Students with concluded or inactive
    /// enrollments are left out.
    /// - Parameters:
    ///   - assignmentIDs: Only submissions for these assignments; empty means
    ///     every published assignment in the course. Canvas answers 403
    ///     ("invalid assignment ids requested") for an unpublished id.
    ///   - status: Only submissions with this easel status; nil means all.
    ///     No Canvas `workflow_state` matches a status (a `graded` row can be
    ///     not submitted), so this fetches every state and filters here.
    func submissions(
        courseID: Int,
        assignmentIDs: [Int] = [],
        status: SubmissionStatus? = nil
    ) async throws -> [Submission] {
        var query = [
            URLQueryItem(name: "student_ids[]", value: "all"),
            URLQueryItem(name: "enrollment_state", value: "active"),
            URLQueryItem(name: "include[]", value: "user")
        ]
        for assignmentID in assignmentIDs {
            query.append(URLQueryItem(name: "assignment_ids[]", value: String(assignmentID)))
        }
        let submissions: [Submission] = try await fetchAll("courses/\(courseID)/students/submissions", query: query)
        guard let status else { return submissions }
        return submissions.filter { $0.status == status }
    }
}
