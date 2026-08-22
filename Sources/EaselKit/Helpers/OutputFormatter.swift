import Foundation

/// A model that the CLI can print. Each format asks the model for one piece:
/// `rowID` for `id`, `summaryRow` for `smalljsonl`, `markdownRow` for `md`
/// (the `json`/`jsonl` forms use `Codable` directly).
public protocol CanvasRow: Codable, Sendable {
    /// The value shown by the `id` format — the natural handle an agent uses to
    /// fetch the full object (numeric id for most models, url slug for pages).
    var rowID: String { get }
    /// The compact id/title/meta subset shown by the `smalljsonl` format.
    var summaryRow: SummaryRow { get }
    /// The self-contained Markdown rendering shown by the `md` format.
    var markdownRow: String { get }
}

public enum OutputFormat: String, Sendable, CaseIterable {
    case json
    case jsonl
    case smalljsonl
    case md
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
        case .smalljsonl:
            return try items.map { try jsonString($0.summaryRow, pretty: false) }.joined(separator: "\n")
        case .md:
            return items.map(\.markdownRow).joined(separator: "\n\n")
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
        case .smalljsonl:
            return try jsonString(item.summaryRow, pretty: false)
        case .md:
            return item.markdownRow
        case .id:
            return item.rowID
        }
    }

    static func jsonString<T: Encodable>(_ value: T, pretty: Bool) throws -> String {
        let data = try CanvasJSON.makeEncoder(pretty: pretty).encode(value)
        return String(decoding: data, as: UTF8.self)
    }
}
