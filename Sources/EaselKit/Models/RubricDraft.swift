import Foundation

/// A rubric described as plain JSON (the shape agents author in a file):
///
/// ```json
/// {
///   "title": "Essay Rubric",
///   "free_form_criterion_comments": false,
///   "criteria": [
///     {
///       "description": "Thesis",
///       "long_description": "A clear, arguable thesis.",
///       "points": 5,
///       "ratings": [
///         { "description": "Excellent", "points": 5 },
///         { "description": "Adequate", "points": 3 },
///         { "description": "Missing", "points": 0 }
///       ]
///     }
///   ]
/// }
/// ```
///
/// Canvas's rubric endpoints expect criteria and ratings as hashes keyed by
/// index (a Rails form-parameter convention), so `EaselKit` converts this
/// array form before sending — see `RubricBody`.
public struct RubricDraft: Codable, Sendable, Equatable {
    public let title: String
    public let freeFormCriterionComments: Bool?
    public let criteria: [CriterionDraft]

    enum CodingKeys: String, CodingKey {
        case title
        case freeFormCriterionComments = "free_form_criterion_comments"
        case criteria
    }

    public init(title: String, freeFormCriterionComments: Bool? = nil, criteria: [CriterionDraft]) {
        self.title = title
        self.freeFormCriterionComments = freeFormCriterionComments
        self.criteria = criteria
    }

    public static func parse(json: String) throws -> RubricDraft {
        do {
            return try CanvasJSON.makeDecoder().decode(RubricDraft.self, from: Data(json.utf8))
        } catch {
            throw CanvasError.decoding(type: "RubricDraft", message: String(describing: error))
        }
    }
}

public struct CriterionDraft: Codable, Sendable, Equatable {
    public let description: String
    public let longDescription: String?
    public let points: Double
    public let criterionUseRange: Bool?
    public let ratings: [RatingDraft]

    enum CodingKeys: String, CodingKey {
        case description
        case longDescription = "long_description"
        case points
        case criterionUseRange = "criterion_use_range"
        case ratings
    }

    public init(
        description: String,
        longDescription: String? = nil,
        points: Double,
        criterionUseRange: Bool? = nil,
        ratings: [RatingDraft]
    ) {
        self.description = description
        self.longDescription = longDescription
        self.points = points
        self.criterionUseRange = criterionUseRange
        self.ratings = ratings
    }
}

public struct RatingDraft: Codable, Sendable, Equatable {
    public let description: String
    public let longDescription: String?
    public let points: Double

    enum CodingKeys: String, CodingKey {
        case description
        case longDescription = "long_description"
        case points
    }

    public init(description: String, longDescription: String? = nil, points: Double) {
        self.description = description
        self.longDescription = longDescription
        self.points = points
    }
}

/// How the rubric should attach to an assignment.
public struct RubricAssociationRequest: Sendable, Equatable {
    public let associationID: Int
    public let associationType: String
    public let useForGrading: Bool
    public let purpose: String
    public let hideScoreTotal: Bool?

    public init(
        associationID: Int,
        associationType: String = "Assignment",
        useForGrading: Bool = true,
        purpose: String = "grading",
        hideScoreTotal: Bool? = nil
    ) {
        self.associationID = associationID
        self.associationType = associationType
        self.useForGrading = useForGrading
        self.purpose = purpose
        self.hideScoreTotal = hideScoreTotal
    }
}

/// The request body Canvas expects for create/update rubric. Criteria and
/// ratings are sent as `{"0": {...}, "1": {...}}` hashes because Canvas's
/// Rails controllers read them exactly as form-encoded indexed parameters.
struct RubricBody: Encodable, Sendable {
    let rubric: RubricParams
    let rubricAssociation: AssociationParams?

    enum CodingKeys: String, CodingKey {
        case rubric
        case rubricAssociation = "rubric_association"
    }

    init(draft: RubricDraft, association: RubricAssociationRequest?, skipUpdatingPointsPossible: Bool? = nil) {
        self.rubric = RubricParams(draft: draft, skipUpdatingPointsPossible: skipUpdatingPointsPossible)
        self.rubricAssociation = association.map(AssociationParams.init)
    }

    struct RubricParams: Encodable, Sendable {
        let title: String
        let freeFormCriterionComments: Bool?
        let skipUpdatingPointsPossible: Bool?
        let criteria: [String: CriterionParams]

        enum CodingKeys: String, CodingKey {
            case title
            case freeFormCriterionComments = "free_form_criterion_comments"
            case skipUpdatingPointsPossible = "skip_updating_points_possible"
            case criteria
        }

        init(draft: RubricDraft, skipUpdatingPointsPossible: Bool?) {
            self.title = draft.title
            self.freeFormCriterionComments = draft.freeFormCriterionComments
            self.skipUpdatingPointsPossible = skipUpdatingPointsPossible
            self.criteria = Dictionary(
                uniqueKeysWithValues: draft.criteria.enumerated().map { index, criterion in
                    (String(index), CriterionParams(draft: criterion))
                }
            )
        }
    }

    struct CriterionParams: Encodable, Sendable {
        let description: String
        let longDescription: String?
        let points: Double
        let criterionUseRange: Bool?
        let ratings: [String: RatingParams]

        enum CodingKeys: String, CodingKey {
            case description
            case longDescription = "long_description"
            case points
            case criterionUseRange = "criterion_use_range"
            case ratings
        }

        init(draft: CriterionDraft) {
            self.description = draft.description
            self.longDescription = draft.longDescription
            self.points = draft.points
            self.criterionUseRange = draft.criterionUseRange
            self.ratings = Dictionary(
                uniqueKeysWithValues: draft.ratings.enumerated().map { index, rating in
                    (String(index), RatingParams(draft: rating))
                }
            )
        }
    }

    struct RatingParams: Encodable, Sendable {
        let description: String
        let longDescription: String?
        let points: Double

        enum CodingKeys: String, CodingKey {
            case description
            case longDescription = "long_description"
            case points
        }

        init(draft: RatingDraft) {
            self.description = draft.description
            self.longDescription = draft.longDescription
            self.points = draft.points
        }
    }

    struct AssociationParams: Encodable, Sendable {
        let associationID: Int
        let associationType: String
        let useForGrading: Bool
        let purpose: String
        let hideScoreTotal: Bool?

        enum CodingKeys: String, CodingKey {
            case associationID = "association_id"
            case associationType = "association_type"
            case useForGrading = "use_for_grading"
            case purpose
            case hideScoreTotal = "hide_score_total"
        }

        init(request: RubricAssociationRequest) {
            self.associationID = request.associationID
            self.associationType = request.associationType
            self.useForGrading = request.useForGrading
            self.purpose = request.purpose
            self.hideScoreTotal = request.hideScoreTotal
        }
    }
}
