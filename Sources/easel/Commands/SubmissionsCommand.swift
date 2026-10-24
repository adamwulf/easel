import ArgumentParser
import EaselKit

struct SubmissionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submissions",
        abstract: "List the active students' submissions in a course.",
        discussion: """
        Canvas keeps a submission for every student an assignment is assigned to,
        so --state unsubmitted lists, for each assignment, the students who have
        not turned it in.
        Excused is a flag, not a state: excused students who never submitted are
        listed as unsubmitted with "excused": true.
        """
    )

    @Argument(help: "The course id.")
    var courseID: Int

    @Option(help: "Only submissions for this assignment id; repeat for more. Omit for every assignment.")
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
