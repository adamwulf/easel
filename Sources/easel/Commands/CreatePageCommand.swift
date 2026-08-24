import ArgumentParser
import EaselKit

struct CreatePageCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-page",
        abstract: "Create a new wiki page in a course."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Option(help: "The page title.")
    var title: String

    @Option(help: "HTML body content.")
    var body: String?

    @Option(help: "Path to a file with HTML body content; use \"-\" for stdin.")
    var bodyFile: String?

    @Option(help: "Comma-separated roles allowed to edit the page (teachers, students, members, public).")
    var editingRoles: String?

    @Option(help: "Whether to notify participants of the new page (true or false).")
    var notifyOfUpdate: Bool?

    @Option(help: "Whether to publish the page immediately (true or false).")
    var published: Bool?

    @Option(help: "Whether to make this the course front page (true or false).")
    var frontPage: Bool?

    @Option(help: "Schedule publication, as ISO 8601 with a time zone. Needs the Scheduled Page Publication feature enabled in Canvas.")
    var publishAt: String?

    @OptionGroup var options: GlobalOptions

    func validate() throws {
        if body != nil && bodyFile != nil {
            throw ValidationError("Use only one of --body or --body-file.")
        }
        try ISODateFlag.validate(publishAt, flag: "--publish-at")
    }

    func run() async throws {
        let client = try options.makeClient()
        let bodyContent = try body ?? bodyFile.map { try FileInput.read($0) }
        let draft = PageCreate(
            title: title,
            body: bodyContent,
            editingRoles: editingRoles,
            notifyOfUpdate: notifyOfUpdate,
            published: published,
            frontPage: frontPage,
            publishAt: publishAt
        )
        let page = try await client.createPage(courseID: courseID, page: draft)
        try Easel.emit(page, format: options.format)
    }
}
