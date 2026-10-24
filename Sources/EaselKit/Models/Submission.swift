import Foundation

/// One student's submission for one assignment. Canvas keeps a submission for
/// every student an assignment is assigned to, so a list covers the whole
/// roster. `status` reduces Canvas's fields to what a teacher means by "not
/// turned in" or "needs grading". `user` appears when the request asks for it
/// via `include[]` (the client does by default).
public struct Submission: Codable, Sendable, Equatable, CanvasRow {
    public let id: Int
    public let userID: Int
    public let assignmentID: Int
    /// `submitted`, `unsubmitted`, `graded`, or `pending_review`. A
    /// resubmission after grading comes back `submitted` with the old score
    /// (see `gradeMatchesCurrentSubmission`). `graded` alone doesn't mean
    /// scored: excused rows and cleared grades stay `graded` with a nil score.
    public let workflowState: String?
    public let submissionType: String?
    public let attempt: Int?
    public let submittedAt: Date?
    public let gradedAt: Date?
    public let score: Double?
    public let grade: String?
    /// False when the student resubmitted after the last grading.
    public let gradeMatchesCurrentSubmission: Bool?
    /// Excused is a flag, not a workflow state. Canvas marks an excused
    /// submission `graded` with a nil score and grade.
    public let excused: Bool?
    public let late: Bool?
    public let missing: Bool?
    public let latePolicyStatus: String?
    public let secondsLate: Int?
    public let graderID: Int?
    public let previewURL: String?
    public let user: CourseUser?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case assignmentID = "assignment_id"
        case workflowState = "workflow_state"
        case submissionType = "submission_type"
        case attempt
        case submittedAt = "submitted_at"
        case gradedAt = "graded_at"
        case score
        case grade
        case gradeMatchesCurrentSubmission = "grade_matches_current_submission"
        case excused
        case late
        case missing
        case latePolicyStatus = "late_policy_status"
        case secondsLate = "seconds_late"
        case graderID = "grader_id"
        case previewURL = "preview_url"
        case user
    }

    /// The student's user id: the handle Canvas uses to fetch or grade one
    /// submission within an assignment.
    public var rowID: String {
        String(userID)
    }

    /// The submission's easel status. Every submission has exactly one,
    /// checked in this order: excused, then not submitted (no `submittedAt`,
    /// even when the missing work has a grade), then needs grading, else
    /// graded.
    public var status: SubmissionStatus {
        if excused == true { return .excused }
        if submittedAt == nil { return .notSubmitted }
        if needsGrading { return .needsGrading }
        return .graded
    }

    /// Canvas's needs-grading rule (`Submission.needs_grading_conditions`, the
    /// one behind an assignment's `needs_grading_count`), minus the excused
    /// check that `status` makes first. A resubmission after grading is
    /// `submitted` with the old score and a false
    /// `gradeMatchesCurrentSubmission`; a cleared grade stays `graded` with a
    /// nil score.
    private var needsGrading: Bool {
        guard submissionType != nil else { return false }
        switch workflowState {
        case "pending_review":
            return true
        case "submitted", "graded":
            return score == nil || gradeMatchesCurrentSubmission == false
        default:
            return false
        }
    }

    public var summaryRow: SummaryRow {
        SummaryRow([
            ("id", .int(id)),
            ("user_id", .int(userID)),
            ("assignment_id", .int(assignmentID)),
            ("name", user?.name.map(JSONScalar.string)),
            ("workflow_state", workflowState.map(JSONScalar.string)),
            ("submission_type", submissionType.map(JSONScalar.string)),
            ("submitted_at", submittedAt.map(JSONScalar.date)),
            ("score", score.map(JSONScalar.double)),
            ("grade", grade.map(JSONScalar.string)),
            ("grade_matches_current_submission", gradeMatchesCurrentSubmission.map(JSONScalar.bool)),
            ("excused", excused.map(JSONScalar.bool)),
            ("late", late.map(JSONScalar.bool)),
            ("missing", missing.map(JSONScalar.bool)),
        ])
    }

    public var markdownRow: String {
        Markdown.document(
            heading: Markdown.heading(2, user?.name ?? "User \(userID)", handle: "#\(userID)"),
            fields: [
                Markdown.field("assignment_id", Markdown.int(assignmentID)),
                Markdown.field("workflow_state", workflowState),
                Markdown.field("submission_type", submissionType),
                Markdown.field("attempt", Markdown.int(attempt)),
                Markdown.field("submitted_at", Markdown.date(submittedAt)),
                Markdown.field("graded_at", Markdown.date(gradedAt)),
                Markdown.field("score", Markdown.number(score)),
                Markdown.field("grade", grade),
                Markdown.field("grade_matches_current_submission", Markdown.bool(gradeMatchesCurrentSubmission)),
                Markdown.field("excused", Markdown.bool(excused)),
                Markdown.field("late", Markdown.bool(late)),
                Markdown.field("missing", Markdown.bool(missing)),
                Markdown.field("late_policy_status", latePolicyStatus),
                Markdown.urlField("preview_url", previewURL),
            ]
        )
    }

    /// Returns a copy safe for anonymous output: the embedded user is redacted
    /// with `CourseUser.anonymized()`. The submission's own fields carry no
    /// name or contact data and are kept unchanged.
    public func anonymized() -> Submission {
        Submission(
            id: id,
            userID: userID,
            assignmentID: assignmentID,
            workflowState: workflowState,
            submissionType: submissionType,
            attempt: attempt,
            submittedAt: submittedAt,
            gradedAt: gradedAt,
            score: score,
            grade: grade,
            gradeMatchesCurrentSubmission: gradeMatchesCurrentSubmission,
            excused: excused,
            late: late,
            missing: missing,
            latePolicyStatus: latePolicyStatus,
            secondsLate: secondsLate,
            graderID: graderID,
            previewURL: previewURL,
            user: user?.anonymized()
        )
    }
}

/// easel's own submission status, derived from Canvas's fields by
/// `Submission.status`. Canvas's `workflow_state` can't answer "who hasn't
/// turned it in": grading missing work (a teacher's 0, or the late policy)
/// marks it `graded`, and so does excusing a student.
public enum SubmissionStatus: String, Sendable, CaseIterable {
    /// Not turned in: no `submitted_at`, and not excused.
    case notSubmitted = "not-submitted"
    /// Turned in and waiting on a grade, by Canvas's needs-grading rule.
    case needsGrading = "needs-grading"
    /// Turned in and graded for the current attempt.
    case graded
    /// Excused from the assignment, whether or not anything was turned in.
    case excused
}
