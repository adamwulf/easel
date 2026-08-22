import Foundation

/// One JSON value allowed in a `smalljsonl` summary. Summaries stay flat — only
/// these scalars — so the output is compact meta (ids, titles, a few fields)
/// without the nested bloat of the full `jsonl` form.
public enum JSONScalar: Encodable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        // The encoder applies its ISO 8601 date strategy, matching `jsonl`.
        case .date(let value): try container.encode(value)
        }
    }
}

/// An ordered set of named scalars, encoded as a JSON object for the
/// `smalljsonl` format. Nil values are dropped, so absent fields never appear
/// in the output. Field names keep Canvas's snake_case, matching `jsonl`.
public struct SummaryRow: Encodable, Sendable {
    private let fields: [(String, JSONScalar)]

    public init(_ fields: [(String, JSONScalar?)]) {
        self.fields = fields.compactMap { key, value in value.map { (key, $0) } }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for (key, value) in fields {
            try container.encode(value, forKey: DynamicKey(key))
        }
    }

    /// A coding key built from an arbitrary field name at runtime.
    private struct DynamicKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }

        init(_ stringValue: String) { self.stringValue = stringValue }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}
