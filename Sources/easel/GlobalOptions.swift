import ArgumentParser
import EaselKit

/// Options shared by every command.
struct GlobalOptions: ParsableArguments {
    @Option(help: "Canvas host, like \"school.instructure.com\". Defaults to CANVAS_HOST from the environment or the nearest .env file.")
    var host: String?

    @Option(name: [.short, .long], help: "Output format: json, jsonl, or id.")
    var format: OutputFormat = .json

    /// Resolves configuration (CANVAS_API_KEY, host) and builds the client.
    func makeClient() throws -> CanvasClient {
        let config = try CanvasConfig.resolve(host: host)
        return CanvasClient(config: config)
    }
}
