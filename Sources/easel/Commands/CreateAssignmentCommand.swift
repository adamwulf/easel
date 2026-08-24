import ArgumentParser
import EaselKit

struct CreateAssignmentCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-assignment",
        abstract: "Create a new assignment in a course."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Option(help: "The assignment name.")
    var name: String

    @Option(help: "HTML description.")
    var description: String?

    @Option(help: "Path to a file with an HTML description; use \"-\" for stdin.")
    var descriptionFile: String?

    @Option(help: "Whether to publish the assignment immediately (true or false).")
    var published: Bool?

    @Option(help: "Points possible.")
    var points: Double?

    @Option(help: "Due date, ISO 8601 with a time zone, like \"2026-09-05T23:59:00-05:00\".")
    var dueAt: String?

    @Option(help: "Date the assignment becomes available, ISO 8601 with a time zone.")
    var unlockAt: String?

    @Option(help: "Date the assignment locks, ISO 8601 with a time zone.")
    var lockAt: String?

    @OptionGroup var options: GlobalOptions

    func validate() throws {
        if description != nil && descriptionFile != nil {
            throw ValidationError("Use only one of --description or --description-file.")
        }
        try ISODateFlag.validate(dueAt, flag: "--due-at")
        try ISODateFlag.validate(unlockAt, flag: "--unlock-at")
        try ISODateFlag.validate(lockAt, flag: "--lock-at")
    }

    func run() async throws {
        let client = try options.makeClient()
        let descriptionContent = try description ?? descriptionFile.map { try FileInput.read($0) }
        let draft = AssignmentCreate(
            name: name,
            description: descriptionContent,
            published: published,
            pointsPossible: points,
            dueAt: dueAt,
            unlockAt: unlockAt,
            lockAt: lockAt
        )
        let assignment = try await client.createAssignment(courseID: courseID, assignment: draft)
        try Easel.emit(assignment, format: options.format)
    }
}
