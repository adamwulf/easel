import ArgumentParser
import EaselKit

struct SubmissionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submissions",
        abstract: "List the active students' submissions in a course.",
        discussion: """
        Canvas keeps a submission for every student an assignment is assigned to.
        A student has not turned it in when "submitted_at" is null and "excused"
        is not true, in any state: --state unsubmitted misses missing work that
        got a grade (such as a 0), because Canvas marks that row graded.
        Excused is a flag, not a state: Canvas lists excused students as graded,
        with "excused": true and no score.
        """
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Option(help: "Only submissions for this published assignment id; repeat for more. Omit for every published assignment.")
    var assignment: [Int] = []

    @Option(help: "Only submissions in this state: submitted, unsubmitted, graded, or pending_review.")
    var state: SubmissionState?

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        let client = try options.makeClient()
        var submissions = try await client.submissions(courseID: courseID, assignmentIDs: assignment, state: state)
        if options.isAnonymous {
            submissions = submissions.map { $0.anonymized() }
        }
        try Easel.emit(submissions, format: options.format)
    }
}

extension SubmissionState: ExpressibleByArgument {}
