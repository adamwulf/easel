import ArgumentParser
import EaselKit

struct UpdateRubricCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update-rubric",
        abstract: "Replace a rubric's title and criteria from a JSON file.",
        discussion: "The JSON file uses the same shape as create-rubric."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Argument(help: "The rubric id.")
    var rubricID: Int

    @Option(help: "Path to the rubric JSON file; use \"-\" for stdin.")
    var file: String

    @Option(help: "An assignment id to (re-)attach the rubric to.")
    var assignment: Int?

    @Flag(inversion: .prefixedNo, help: "Use the rubric to grade the assignment (with --assignment).")
    var useForGrading: Bool = true

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let draft = try RubricDraft.parse(json: FileInput.read(file))
        let association = assignment.map {
            RubricAssociationRequest(associationID: $0, useForGrading: useForGrading)
        }
        let result = try await client.updateRubric(
            courseID: courseID,
            id: rubricID,
            draft: draft,
            association: association
        )
        try Easel.emit(result, format: options.format)
    }
}
