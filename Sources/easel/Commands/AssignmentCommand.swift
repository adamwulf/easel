import ArgumentParser
import EaselKit

struct AssignmentCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "assignment",
        abstract: "Show one assignment, including its description and rubric."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Argument(help: "The assignment id.")
    var assignmentID: Int

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let assignment = try await client.assignment(courseID: courseID, id: assignmentID)
        try Easel.emit(assignment, format: options.format)
    }
}
