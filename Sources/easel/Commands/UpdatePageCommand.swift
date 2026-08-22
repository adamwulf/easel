import ArgumentParser
import EaselKit

struct UpdatePageCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update-page",
        abstract: "Update a wiki page's title, body, and/or published state."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Argument(help: "The page url slug, or \"page_id:<id>\" to look up by id.")
    var urlOrID: String

    @Option(help: "New page title.")
    var title: String?

    @Option(help: "New HTML body content.")
    var body: String?

    @Option(help: "Path to a file with new HTML body content; use \"-\" for stdin.")
    var bodyFile: String?

    @Option(help: "New published state (true or false).")
    var published: Bool?

    @Option(help: "Schedule a future publication date, ISO 8601 with a time zone. Needs the Scheduled Page Publication feature enabled in Canvas.")
    var publishAt: String?

    @OptionGroup var options: GlobalOptions

    func validate() throws {
        if body != nil && bodyFile != nil {
            throw ValidationError("Use only one of --body or --body-file.")
        }
        if title == nil && body == nil && bodyFile == nil && published == nil && publishAt == nil {
            throw ValidationError(
                "Provide at least one change: --title, --body, --body-file, --published, or --publish-at."
            )
        }
        try ISODateFlag.validate(publishAt, flag: "--publish-at")
    }

    func run() async throws {
        let client = try options.makeClient()
        let bodyContent = try body ?? bodyFile.map { try FileInput.read($0) }
        let update = PageUpdate(title: title, body: bodyContent, published: published, publishAt: publishAt)
        let page = try await client.updatePage(courseID: courseID, urlOrID: urlOrID, update: update)
        try Easel.emit(page, format: options.format)
    }
}
