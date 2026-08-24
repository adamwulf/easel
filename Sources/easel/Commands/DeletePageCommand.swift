import ArgumentParser
import EaselKit

struct DeletePageCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-page",
        abstract: "Delete a wiki page from a course."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Argument(help: "The page url slug, or \"page_id:<id>\" to look up by id.")
    var urlOrID: String

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let page = try await client.deletePage(courseID: courseID, urlOrID: urlOrID)
        try Easel.emit(page, format: options.format)
    }
}
