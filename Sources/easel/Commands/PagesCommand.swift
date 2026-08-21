import ArgumentParser
import EaselKit

struct PagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pages",
        abstract: "List the wiki pages in a course (without bodies; use \"page\" for a body)."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Option(help: "Only pages whose title matches this term.")
    var search: String?

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let pages = try await client.pages(courseID: courseID, searchTerm: search)
        try Easel.emit(pages, format: options.format)
    }
}
