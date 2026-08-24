import Foundation

public extension CanvasClient {
    /// Lists a course's rubrics.
    func rubrics(courseID: Int) async throws -> [Rubric] {
        try await fetchAll("courses/\(courseID)/rubrics")
    }

    /// Fetches one rubric, including its criteria.
    func rubric(courseID: Int, id: Int) async throws -> Rubric {
        try await api.get("courses/\(courseID)/rubrics/\(id)")
    }

    /// Creates a rubric in a course, optionally attached to an assignment.
    func createRubric(
        courseID: Int,
        draft: RubricDraft,
        association: RubricAssociationRequest? = nil
    ) async throws -> RubricResult {
        let body = RubricBody(draft: draft, association: association)
        let data = try await api.sendJSON(method: "POST", path: "courses/\(courseID)/rubrics", body: body)
        return try RubricResult.decode(from: data)
    }

    /// Replaces a rubric's title and criteria, optionally (re-)attaching it to
    /// an assignment.
    func updateRubric(
        courseID: Int,
        id: Int,
        draft: RubricDraft,
        association: RubricAssociationRequest? = nil
    ) async throws -> RubricResult {
        let body = RubricBody(draft: draft, association: association)
        let data = try await api.sendJSON(method: "PUT", path: "courses/\(courseID)/rubrics/\(id)", body: body)
        return try RubricResult.decode(from: data)
    }

    /// Deletes a rubric and all of its associations.
    func deleteRubric(courseID: Int, id: Int) async throws -> Rubric {
        try await api.delete("courses/\(courseID)/rubrics/\(id)")
    }
}
