import ArgumentParser
import EaselKit

struct PageCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "page",
        abstract: "Show one wiki page, including its body."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Argument(help: "The page url slug, or \"page_id:<id>\" to look up by id.")
    var urlOrID: String

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let page = try await client.page(courseID: courseID, urlOrID: urlOrID)
        try Easel.emit(page, format: options.format)
    }
}
