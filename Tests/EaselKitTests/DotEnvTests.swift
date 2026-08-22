import EaselKit
import Foundation
import XCTest

/// These tests always pass an explicit `startingIn` directory inside a fresh
/// temp tree, so the walk-up never touches real `.env` files (and never reads
/// a real API key).
final class DotEnvTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("easel-dotenv-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: root)
    }

    private func write(_ contents: String, in directory: URL) throws {
        try contents.write(to: directory.appendingPathComponent(".env"), atomically: true, encoding: .utf8)
    }

    private func makeSubdirectory(_ components: String...) throws -> URL {
        var dir = root!
        for component in components {
            dir = dir.appendingPathComponent(component, isDirectory: true)
        }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func testFindsValueInStartingDirectory() throws {
        try write("EASEL_TEST_KEY=direct-value\n", in: root)
        XCTAssertEqual(DotEnv.loadValue(forKey: "EASEL_TEST_KEY", startingIn: root), "direct-value")
    }

    func testWalksUpToParent() throws {
        let nested = try makeSubdirectory("a", "b", "c")
        try write("EASEL_TEST_KEY=from-root\n", in: root)
        XCTAssertEqual(DotEnv.loadValue(forKey: "EASEL_TEST_KEY", startingIn: nested), "from-root")
    }

    func testClosestEnvWins() throws {
        let middle = try makeSubdirectory("a")
        let nested = try makeSubdirectory("a", "b")
        try write("EASEL_TEST_KEY=far\n", in: root)
        try write("EASEL_TEST_KEY=near\n", in: middle)
        XCTAssertEqual(DotEnv.loadValue(forKey: "EASEL_TEST_KEY", startingIn: nested), "near")
    }

    func testExactKeyMatchOnly() throws {
        try write("EASEL_TEST_KEY_EXTRA=wrong\nEASEL_TEST_KEY=right\n", in: root)
        XCTAssertEqual(DotEnv.loadValue(forKey: "EASEL_TEST_KEY", startingIn: root), "right")
    }

    func testSkipsCommentsAndStripsQuotes() throws {
        try write(
            """
            # a comment
            EASEL_QUOTED="double quoted"
            EASEL_SINGLE='single quoted'
            export EASEL_EXPORTED=exported-value
            """,
            in: root
        )
        XCTAssertEqual(DotEnv.loadValue(forKey: "EASEL_QUOTED", startingIn: root), "double quoted")
        XCTAssertEqual(DotEnv.loadValue(forKey: "EASEL_SINGLE", startingIn: root), "single quoted")
        XCTAssertEqual(DotEnv.loadValue(forKey: "EASEL_EXPORTED", startingIn: root), "exported-value")
    }

    func testEmptyValueCountsAsUnset() throws {
        try write("EASEL_TEST_KEY=\n", in: root)
        XCTAssertNil(DotEnv.loadValue(forKey: "EASEL_TEST_KEY", startingIn: root))
    }

    func testMissingKeyReturnsNil() throws {
        try write("EASEL_OTHER_KEY=value\n", in: root)
        XCTAssertNil(DotEnv.loadValue(forKey: "EASEL_TEST_MISSING_KEY_XYZ", startingIn: root))
    }
}
