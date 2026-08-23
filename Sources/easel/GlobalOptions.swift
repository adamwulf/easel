import ArgumentParser
import EaselKit

/// Options shared by every command.
struct GlobalOptions: ParsableArguments {
    @Option(help: "Canvas host, like \"school.instructure.com\". Defaults to CANVAS_HOST from the environment or the nearest .env file.")
    var host: String?

    @Option(name: [.short, .long], help: "Output format: json, jsonl, smalljsonl, md, or id.")
    var format: OutputFormat = .json

    @Flag(
        inversion: .prefixedNo,
        help: "Redact last names, emails, and login ids from output. Defaults to EASEL_ANONYMOUS from the environment or the nearest .env file."
    )
    var anonymous: Bool?

    /// Resolves configuration (CANVAS_API_KEY, host) and builds the client.
    func makeClient() throws -> CanvasClient {
        let config = try CanvasConfig.resolve(host: host)
        return CanvasClient(config: config)
    }

    /// Whether anonymous output mode is on: `--anonymous`/`--no-anonymous` wins,
    /// otherwise `EASEL_ANONYMOUS` from the environment or nearest `.env`.
    var isAnonymous: Bool {
        CanvasConfig.resolveAnonymous(flag: anonymous)
    }
}
