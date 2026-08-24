import ArgumentParser
import EaselKit

struct DeleteAssignmentCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-assignment",
        abstract: "Delete an assignment from a course."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Argument(help: "The assignment id.")
    var assignmentID: Int

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let assignment = try await client.deleteAssignment(courseID: courseID, id: assignmentID)
        try Easel.emit(assignment, format: options.format)
    }
}
