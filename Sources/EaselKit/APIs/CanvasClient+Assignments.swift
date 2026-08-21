import Foundation

public extension CanvasClient {
    /// Lists a course's assignments in course order.
    func assignments(courseID: Int, searchTerm: String? = nil) async throws -> [Assignment] {
        var query = [URLQueryItem(name: "order_by", value: "position")]
        if let searchTerm {
            query.append(URLQueryItem(name: "search_term", value: searchTerm))
        }
        return try await fetchAll("courses/\(courseID)/assignments", query: query)
    }

    /// Fetches one assignment, including its description and any rubric.
    func assignment(courseID: Int, id: Int) async throws -> Assignment {
        try await api.get("courses/\(courseID)/assignments/\(id)")
    }

    /// Updates an assignment's name, description, published state, points,
    /// and/or due date.
    func updateAssignment(courseID: Int, id: Int, update: AssignmentUpdate) async throws -> Assignment {
        try await api.put("courses/\(courseID)/assignments/\(id)", body: AssignmentUpdateBody(assignment: update))
    }
}
