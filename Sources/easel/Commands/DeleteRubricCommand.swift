import ArgumentParser
import EaselKit

struct DeleteRubricCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-rubric",
        abstract: "Delete a rubric and remove all of its associations."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Argument(help: "The rubric id.")
    var rubricID: Int

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let rubric = try await client.deleteRubric(courseID: courseID, id: rubricID)
        try Easel.emit(rubric, format: options.format)
    }
}
