import ArgumentParser
import EaselKit

struct UsersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "users",
        abstract: "List the people in a course."
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Option(help: "Only people with this role: teacher, student, ta, observer, or designer.")
    var enrollmentType: String?

    @Option(help: "Only people whose name or login matches this term.")
    var search: String?

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        var users = try await client.users(courseID: courseID, enrollmentType: enrollmentType, searchTerm: search)
        if options.isAnonymous {
            users = users.map { $0.anonymized() }
        }
        try Easel.emit(users, format: options.format)
    }
}
