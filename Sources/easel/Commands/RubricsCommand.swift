import ArgumentParser
import EaselKit

struct RubricsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rubrics",
        abstract: "List the rubrics in a course."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let rubrics = try await client.rubrics(courseID: courseID)
        try Easel.emit(rubrics, format: options.format)
    }
}
