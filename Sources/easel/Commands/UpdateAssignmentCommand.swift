import ArgumentParser
import EaselKit

struct UpdateAssignmentCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update-assignment",
        abstract: "Update an assignment's name, description, points, due date, and/or published state."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Argument(help: "The assignment id.")
    var assignmentID: Int

    @Option(help: "New assignment name.")
    var name: String?

    @Option(help: "New HTML description.")
    var description: String?

    @Option(help: "Path to a file with a new HTML description; use \"-\" for stdin.")
    var descriptionFile: String?

    @Option(help: "New published state (true or false).")
    var published: Bool?

    @Option(help: "New points possible.")
    var points: Double?

    @Option(help: "New due date, ISO 8601, like \"2026-09-05T23:59:00-05:00\".")
    var dueAt: String?

    @OptionGroup var options: GlobalOptions

    func validate() throws {
        if description != nil && descriptionFile != nil {
            throw ValidationError("Use only one of --description or --description-file.")
        }
        if name == nil && description == nil && descriptionFile == nil
            && published == nil && points == nil && dueAt == nil {
            throw ValidationError(
                "Provide at least one change: --name, --description, --description-file, "
                    + "--published, --points, or --due-at."
            )
        }
    }

    func run() async throws {
        let client = try options.makeClient()
        let descriptionContent = try description ?? descriptionFile.map { try FileInput.read($0) }
        let update = AssignmentUpdate(
            name: name,
            description: descriptionContent,
            published: published,
            pointsPossible: points,
            dueAt: dueAt
        )
        let assignment = try await client.updateAssignment(courseID: courseID, id: assignmentID, update: update)
        try Easel.emit(assignment, format: options.format)
    }
}
