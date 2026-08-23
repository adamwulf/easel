import Foundation
import XCTest
@testable import EaselKit

final class CanvasConfigTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("easel-config-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: root)
    }

    private func writeEnvFile(_ contents: String) throws {
        try contents.write(to: root.appendingPathComponent(".env"), atomically: true, encoding: .utf8)
    }

    func testEnvironmentBeatsDotEnv() throws {
        try writeEnvFile("CANVAS_API_KEY=file-token\nCANVAS_HOST=file.instructure.com\n")
        let config = try CanvasConfig.resolve(
            environment: ["CANVAS_API_KEY": "env-token", "CANVAS_HOST": "env.instructure.com"],
            startingIn: root
        )
        XCTAssertEqual(config.token, "env-token")
        XCTAssertEqual(config.baseURL.absoluteString, "https://env.instructure.com")
    }

    func testDotEnvFallback() throws {
        try writeEnvFile("CANVAS_API_KEY=file-token\nCANVAS_HOST=file.instructure.com\n")
        let config = try CanvasConfig.resolve(environment: [:], startingIn: root)
        XCTAssertEqual(config.token, "file-token")
        XCTAssertEqual(config.baseURL.absoluteString, "https://file.instructure.com")
    }

    func testExplicitHostBeatsEnvironment() throws {
        let config = try CanvasConfig.resolve(
            host: "cli.instructure.com",
            environment: ["CANVAS_API_KEY": "env-token", "CANVAS_HOST": "env.instructure.com"],
            startingIn: root
        )
        XCTAssertEqual(config.baseURL.absoluteString, "https://cli.instructure.com")
    }

    func testMissingAPIKeyThrows() {
        XCTAssertThrowsError(
            try CanvasConfig.resolve(environment: ["CANVAS_HOST": "x.instructure.com"], startingIn: root)
        ) { error in
            XCTAssertEqual(error as? CanvasError, .missingAPIKey)
        }
    }

    func testMissingHostThrows() {
        XCTAssertThrowsError(
            try CanvasConfig.resolve(environment: ["CANVAS_API_KEY": "token"], startingIn: root)
        ) { error in
            XCTAssertEqual(error as? CanvasError, .missingHost)
        }
    }

    func testHostNormalizationAddsScheme() throws {
        let url = try CanvasConfig.normalizeHost("school.instructure.com")
        XCTAssertEqual(url.absoluteString, "https://school.instructure.com")
    }

    func testHostNormalizationStripsTrailingSlash() throws {
        let url = try CanvasConfig.normalizeHost("https://school.instructure.com/")
        XCTAssertEqual(url.absoluteString, "https://school.instructure.com")
    }

    func testHostNormalizationRejectsGarbage() {
        XCTAssertThrowsError(try CanvasConfig.normalizeHost("not a host"))
        XCTAssertThrowsError(try CanvasConfig.normalizeHost(""))
        XCTAssertThrowsError(try CanvasConfig.normalizeHost("ftp://school.example.com"))
    }

    func testAPIBaseURL() {
        let config = CanvasConfig(baseURL: URL(string: "https://school.instructure.com")!, token: "token")
        XCTAssertEqual(config.apiBaseURL.absoluteString, "https://school.instructure.com/api/v1")
    }

    // MARK: - Anonymous mode resolution

    func testAnonymousDefaultsOffWhenUnset() {
        XCTAssertFalse(CanvasConfig.resolveAnonymous(environment: [:], startingIn: root))
    }

    func testAnonymousFromEnvironment() {
        XCTAssertTrue(CanvasConfig.resolveAnonymous(environment: ["EASEL_ANONYMOUS": "1"], startingIn: root))
        XCTAssertTrue(CanvasConfig.resolveAnonymous(environment: ["EASEL_ANONYMOUS": "true"], startingIn: root))
    }

    func testAnonymousExplicitNegativeIsOff() {
        for negative in ["0", "false", "no", "off", "FALSE", "Off"] {
            XCTAssertFalse(
                CanvasConfig.resolveAnonymous(environment: ["EASEL_ANONYMOUS": negative], startingIn: root),
                "\(negative) should read as off"
            )
        }
    }

    func testAnonymousFromDotEnvFallback() throws {
        try writeEnvFile("EASEL_ANONYMOUS=yes\n")
        XCTAssertTrue(CanvasConfig.resolveAnonymous(environment: [:], startingIn: root))
    }

    func testAnonymousEnvironmentBeatsDotEnv() throws {
        try writeEnvFile("EASEL_ANONYMOUS=true\n")
        XCTAssertFalse(CanvasConfig.resolveAnonymous(environment: ["EASEL_ANONYMOUS": "0"], startingIn: root))
    }

    func testAnonymousFlagTurnsOnDespiteFalsyEnv() {
        // The flag can only turn redaction ON — even when the env says off.
        XCTAssertTrue(
            CanvasConfig.resolveAnonymous(flag: true, environment: ["EASEL_ANONYMOUS": "0"], startingIn: root)
        )
        XCTAssertTrue(
            CanvasConfig.resolveAnonymous(flag: true, environment: [:], startingIn: root)
        )
    }

    func testAnonymousEnvTruthyCannotBeDisabled() throws {
        // Anonymous mode is one-way: a truthy env/.env value stays on even
        // though the flag defaults to off (there is no --no-anonymous).
        XCTAssertTrue(
            CanvasConfig.resolveAnonymous(flag: false, environment: ["EASEL_ANONYMOUS": "true"], startingIn: root)
        )
        try writeEnvFile("EASEL_ANONYMOUS=true\n")
        XCTAssertTrue(CanvasConfig.resolveAnonymous(flag: false, environment: [:], startingIn: root))
    }
}
