import ArgumentParser
import EaselKit

struct AssignmentsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "assignments",
        abstract: "List the assignments in a course."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Option(help: "Only assignments whose title matches this term.")
    var search: String?

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let assignments = try await client.assignments(courseID: courseID, searchTerm: search)
        try Easel.emit(assignments, format: options.format)
    }
}
