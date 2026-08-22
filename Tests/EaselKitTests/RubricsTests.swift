import EaselKit
import Foundation
import XCTest

final class RubricsTests: XCTestCase {
    func testListRubrics() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/rubrics", json: Fixtures.rubricsList)
        let client = CanvasClient.stubbed(transport)

        let rubrics = try await client.rubrics(courseID: 101)

        XCTAssertEqual(rubrics.count, 1)
        XCTAssertEqual(rubrics[0].id, 9)
        XCTAssertEqual(rubrics[0].title, "Portrait Rubric")
    }

    func testShowRubricDecodesCriteria() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/rubrics/9", json: Fixtures.rubricShow)
        let client = CanvasClient.stubbed(transport)

        let rubric = try await client.rubric(courseID: 101, id: 9)

        XCTAssertEqual(rubric.pointsPossible, 100.0)
        let criteria = try XCTUnwrap(rubric.data)
        XCTAssertEqual(criteria.count, 2)
        XCTAssertEqual(criteria[0].description, "Likeness")
        XCTAssertEqual(criteria[1].ratings?.last?.points, 15.0)
    }

    func testCreateRubricBuildsIndexedHashBody() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/rubrics", method: "POST", json: Fixtures.rubricCreateResponse)
        let client = CanvasClient.stubbed(transport)

        let draft = try RubricDraft.parse(json: Fixtures.rubricDraftJSON)
        let association = RubricAssociationRequest(associationID: 501)
        let result = try await client.createRubric(courseID: 101, draft: draft, association: association)

        XCTAssertEqual(result.rubric?.id, 10)
        XCTAssertEqual(result.rubricAssociation?.associationID, 501)

        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.method, "POST")
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])

        let rubric = try XCTUnwrap(object["rubric"] as? [String: Any])
        XCTAssertEqual(rubric["title"] as? String, "Essay Rubric")
        let criteria = try XCTUnwrap(rubric["criteria"] as? [String: Any])
        XCTAssertEqual(criteria.count, 2)
        let criterion0 = try XCTUnwrap(criteria["0"] as? [String: Any])
        XCTAssertEqual(criterion0["description"] as? String, "Thesis")
        XCTAssertEqual(criterion0["long_description"] as? String, "A clear, arguable thesis.")
        XCTAssertEqual(criterion0["points"] as? Double, 5.0)
        let ratings = try XCTUnwrap(criterion0["ratings"] as? [String: Any])
        XCTAssertEqual(ratings.count, 3)
        let rating0 = try XCTUnwrap(ratings["0"] as? [String: Any])
        XCTAssertEqual(rating0["description"] as? String, "Excellent")
        XCTAssertEqual(rating0["points"] as? Double, 5.0)

        let associationParams = try XCTUnwrap(object["rubric_association"] as? [String: Any])
        XCTAssertEqual(associationParams["association_id"] as? Int, 501)
        XCTAssertEqual(associationParams["association_type"] as? String, "Assignment")
        XCTAssertEqual(associationParams["use_for_grading"] as? Bool, true)
        XCTAssertEqual(associationParams["purpose"] as? String, "grading")
    }

    func testUpdateRubricUsesPutOnRubricPath() async throws {
        let transport = StubTransport()
        await transport.on("/courses/101/rubrics/9", method: "PUT", json: Fixtures.rubricCreateResponse)
        let client = CanvasClient.stubbed(transport)

        let draft = try RubricDraft.parse(json: Fixtures.rubricDraftJSON)
        let result = try await client.updateRubric(courseID: 101, id: 9, draft: draft)

        XCTAssertEqual(result.rubric?.id, 10)
        let recorded = await transport.recorded
        let request = try XCTUnwrap(recorded.first)
        XCTAssertEqual(request.method, "PUT")
        XCTAssertTrue(request.url.path.hasSuffix("/courses/101/rubrics/9"))
        let bodyData = try XCTUnwrap(request.body)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        XCTAssertNil(object["rubric_association"], "no association was requested")
    }

    func testRubricResultFallsBackToBareRubric() throws {
        let result = try RubricResult.decode(from: Data(Fixtures.rubricBareResponse.utf8))
        XCTAssertEqual(result.rubric?.id, 10)
        XCTAssertNil(result.rubricAssociation)
    }

    func testRubricDraftParseErrorIsTyped() {
        XCTAssertThrowsError(try RubricDraft.parse(json: "{\"title\": 42}")) { error in
            guard case CanvasError.decoding(let type, _)? = error as? CanvasError else {
                XCTFail("expected CanvasError.decoding, got \(error)")
                return
            }
            XCTAssertEqual(type, "RubricDraft")
        }
    }
}
