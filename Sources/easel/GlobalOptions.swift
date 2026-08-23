import ArgumentParser
import EaselKit

/// Options shared by every command.
struct GlobalOptions: ParsableArguments {
    @Option(help: "Canvas host, like \"school.instructure.com\". Defaults to CANVAS_HOST from the environment or the nearest .env file.")
    var host: String?

    @Option(name: [.short, .long], help: "Output format: json, jsonl, smalljsonl, md, or id.")
    var format: OutputFormat = .json

    @Flag(help: "Redact last names, emails, and login ids from output. EASEL_ANONYMOUS in the environment or nearest .env also turns this on; once on it cannot be turned off.")
    var anonymous: Bool = false

    /// Resolves configuration (CANVAS_API_KEY, host) and builds the client.
    func makeClient() throws -> CanvasClient {
        let config = try CanvasConfig.resolve(host: host)
        return CanvasClient(config: config)
    }

    /// Whether anonymous output mode is on. One-way: it's on when `--anonymous`
    /// is given OR when `EASEL_ANONYMOUS` is truthy in the environment or nearest
    /// `.env`. The flag can only turn redaction on — nothing turns it off — so a
    /// truthy env var is a hard privacy guarantee an agent can't bypass.
    var isAnonymous: Bool {
        CanvasConfig.resolveAnonymous(flag: anonymous)
    }
}
