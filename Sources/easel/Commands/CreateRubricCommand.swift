import ArgumentParser
import EaselKit

struct CreateRubricCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-rubric",
        abstract: "Create a rubric from a JSON file and attach it to an assignment.",
        discussion: """
        The JSON file describes the rubric with criteria and ratings as arrays:

          {
            "title": "Essay Rubric",
            "criteria": [
              {
                "description": "Thesis",
                "points": 5,
                "ratings": [
                  { "description": "Excellent", "points": 5 },
                  { "description": "Missing", "points": 0 }
                ]
              }
            ]
          }
        """
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Option(help: "The assignment id to attach the rubric to.")
    var assignment: Int

    @Option(help: "Path to the rubric JSON file; use \"-\" for stdin.")
    var file: String

    @Flag(inversion: .prefixedNo, help: "Use the rubric to grade the assignment.")
    var useForGrading: Bool = true

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let draft = try RubricDraft.parse(json: FileInput.read(file))
        let association = RubricAssociationRequest(associationID: assignment, useForGrading: useForGrading)
        let result = try await client.createRubric(courseID: courseID, draft: draft, association: association)
        try Easel.emit(result, format: options.format)
    }
}
