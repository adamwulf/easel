import Foundation

/// A Canvas rubric. `data` holds the criteria.
public struct Rubric: Codable, Sendable, Equatable, CanvasRow {
    public let id: Int
    public let title: String?
    public let contextID: Int?
    public let contextType: String?
    public let pointsPossible: Double?
    public let freeFormCriterionComments: Bool?
    public let readOnly: Bool?
    public let reusable: Bool?
    public let data: [RubricCriterion]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case contextID = "context_id"
        case contextType = "context_type"
        case pointsPossible = "points_possible"
        case freeFormCriterionComments = "free_form_criterion_comments"
        case readOnly = "read_only"
        case reusable
        case data
    }

    public var rowID: String {
        String(id)
    }

    public var summaryRow: SummaryRow {
        SummaryRow([
            ("id", .int(id)),
            ("title", title.map(JSONScalar.string)),
            ("points_possible", pointsPossible.map(JSONScalar.double)),
            ("context_type", contextType.map(JSONScalar.string)),
        ])
    }

    public var markdownRow: String {
        Markdown.document(
            heading: Markdown.heading(2, title, handle: "#\(id)"),
            fields: [
                Markdown.field("points_possible", Markdown.number(pointsPossible)),
                Markdown.field("context_type", contextType),
                Markdown.field("context_id", Markdown.int(contextID)),
                Markdown.field("free_form_criterion_comments", Markdown.bool(freeFormCriterionComments)),
                Markdown.field("read_only", Markdown.bool(readOnly)),
                Markdown.field("reusable", Markdown.bool(reusable)),
            ],
            sections: [criteriaSection]
        )
    }

    /// The rubric's criteria rendered as a table, or nil when it has none.
    private var criteriaSection: String? {
        guard let data, !data.isEmpty else { return nil }
        return Markdown.heading(3, "Criteria") + "\n" + data.markdownTable
    }
}

extension [RubricCriterion] {
    /// Renders rubric criteria as a `Criterion | Points | Ratings` table, each
    /// rating shown as `description (points)`. Shared by rubric and assignment
    /// Markdown output.
    var markdownTable: String {
        Markdown.table(
            headers: ["Criterion", "Points", "Ratings"],
            rows: map { criterion in
                [
                    criterion.description ?? "",
                    Markdown.number(criterion.points) ?? "",
                    (criterion.ratings ?? []).map { rating in
                        let points = Markdown.number(rating.points).map { " (\($0))" } ?? ""
                        return (rating.description ?? "") + points
                    }.joined(separator: ", "),
                ]
            }
        )
    }
}

/// One criterion in a rubric. Canvas uses string ids like `"_10"`.
public struct RubricCriterion: Codable, Sendable, Equatable {
    public let id: String?
    public let description: String?
    public let longDescription: String?
    public let points: Double?
    public let criterionUseRange: Bool?
    public let ratings: [RubricRating]?

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case longDescription = "long_description"
        case points
        case criterionUseRange = "criterion_use_range"
        case ratings
    }
}

/// One rating level within a criterion.
public struct RubricRating: Codable, Sendable, Equatable {
    public let id: String?
    public let description: String?
    public let longDescription: String?
    public let points: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case longDescription = "long_description"
        case points
    }
}

/// Links a rubric to an assignment (or other context).
public struct RubricAssociation: Codable, Sendable, Equatable {
    public let id: Int?
    public let rubricID: Int?
    public let associationID: Int?
    public let associationType: String?
    public let useForGrading: Bool?
    public let purpose: String?
    public let hideScoreTotal: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case rubricID = "rubric_id"
        case associationID = "association_id"
        case associationType = "association_type"
        case useForGrading = "use_for_grading"
        case purpose
        case hideScoreTotal = "hide_score_total"
    }
}

/// What Canvas returns from create/update rubric: usually a wrapper holding
/// the rubric and its association, but some deployments return the bare
/// rubric, so decoding falls back to that.
public struct RubricResult: Codable, Sendable, Equatable, CanvasRow {
    public let rubric: Rubric?
    public let rubricAssociation: RubricAssociation?

    enum CodingKeys: String, CodingKey {
        case rubric
        case rubricAssociation = "rubric_association"
    }

    public init(rubric: Rubric?, rubricAssociation: RubricAssociation?) {
        self.rubric = rubric
        self.rubricAssociation = rubricAssociation
    }

    public var rowID: String {
        rubric.map { String($0.id) } ?? ""
    }

    public var summaryRow: SummaryRow {
        SummaryRow([
            ("rubric_id", rubric.map { .int($0.id) }),
            ("title", rubric?.title.map(JSONScalar.string)),
            ("points_possible", rubric?.pointsPossible.map(JSONScalar.double)),
        ])
    }

    public var markdownRow: String {
        rubric?.markdownRow ?? Markdown.heading(2, "Rubric")
    }

    public static func decode(from data: Data) throws -> RubricResult {
        let decoder = CanvasJSON.makeDecoder()
        if let wrapper = try? decoder.decode(RubricResult.self, from: data), wrapper.rubric != nil {
            return wrapper
        }
        do {
            let bare = try decoder.decode(Rubric.self, from: data)
            return RubricResult(rubric: bare, rubricAssociation: nil)
        } catch {
            throw CanvasError.decoding(type: "RubricResult", message: String(describing: error))
        }
    }
}
