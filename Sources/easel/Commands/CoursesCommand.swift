import ArgumentParser
import EaselKit

struct CoursesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "courses",
        abstract: "List your courses."
    )

    @Option(help: "Only courses where you have this role: teacher, student, ta, observer, or designer.")
    var enrollmentType: String?

    @Option(help: "Only courses in this state: unpublished, available, or completed.")
    var state: String?

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        let courses = try await client.courses(enrollmentType: enrollmentType, state: state)
        try Easel.emit(courses, format: options.format)
    }
}
