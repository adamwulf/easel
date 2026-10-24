import ArgumentParser
import EaselKit

struct SubmissionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submissions",
        abstract: "List the active students' submissions in a course.",
        discussion: """
        Canvas keeps a submission for every student an assignment is assigned to.
        --state filters by easel's own status, which every submission has exactly
        one of, checked in this order:
          excused        the student is excused
          not-submitted  nothing turned in, even if the missing work has a grade
          needs-grading  turned in and waiting on a grade (Canvas's rule)
          graded         turned in and graded for the current attempt
        On-paper and no-submission assignments have nothing turned in online, so
        every student who isn't excused is not-submitted there.
        """
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Option(help: "Only submissions for this published assignment id; repeat for more. Omit for every published assignment.")
    var assignment: [Int] = []

    @Option(help: "Only submissions with this status: not-submitted, needs-grading, graded, or excused.")
    var state: SubmissionStatus?

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        var submissions = try await client.submissions(courseID: courseID, assignmentIDs: assignment, status: state)
        if options.isAnonymous {
            submissions = submissions.map { $0.anonymized() }
        }
        try Easel.emit(submissions, format: options.format)
    }
}

extension SubmissionStatus: ExpressibleByArgument {}
