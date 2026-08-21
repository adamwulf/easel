import Foundation

/// A model that the CLI can print. `rowID` is the value shown by the `id`
/// output format — the natural handle an agent would use to fetch the full
/// object (numeric id for most models, url slug for pages).
public protocol CanvasRow: Codable, Sendable {
    var rowID: String { get }
}

public enum OutputFormat: String, Sendable, CaseIterable {
    case json
    case jsonl
    case id
}

/// Renders models for the CLI. Field names in JSON output match the Canvas
/// API's snake_case names, so agents can cross-reference the Canvas docs.
public enum OutputFormatter {
    public static func render<T: CanvasRow>(_ items: [T], format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try jsonString(items, pretty: true)
        case .jsonl:
            return try items.map { try jsonString($0, pretty: false) }.joined(separator: "\n")
        case .id:
            return items.map(\.rowID).joined(separator: "\n")
        }
    }

    public static func render<T: CanvasRow>(_ item: T, format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try jsonString(item, pretty: true)
        case .jsonl:
            return try jsonString(item, pretty: false)
        case .id:
            return item.rowID
        }
    }

    static func jsonString<T: Encodable>(_ value: T, pretty: Bool) throws -> String {
        let data = try CanvasJSON.makeEncoder(pretty: pretty).encode(value)
        return String(decoding: data, as: UTF8.self)
    }
}
