import ArgumentParser
import EaselKit

struct RubricCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rubric",
        abstract: "Show one rubric, including its criteria and ratings."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Argument(help: "The rubric id.")
    var rubricID: Int

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let rubric = try await client.rubric(courseID: courseID, id: rubricID)
        try Easel.emit(rubric, format: options.format)
    }
}
