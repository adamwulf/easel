import Foundation

/// JSON coders configured for Canvas. Models use explicit snake_case
/// `CodingKeys`, so no key-conversion strategy is applied; dates are ISO 8601
/// (Canvas sends both `Z` and offset forms, occasionally with fractional
/// seconds).
public enum CanvasJSON {
    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = parseISO8601(string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unrecognized date format: \(string)"
                )
            }
            return date
        }
        return decoder
    }

    public static func makeEncoder(pretty: Bool) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = pretty
            ? [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            : [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    static func parseISO8601(_ string: String) -> Date? {
        // ISO8601DateFormatter is thread-safe, but instances are created locally
        // so no shared mutable state crosses concurrency domains.
        let plain = ISO8601DateFormatter()
        if let date = plain.date(from: string) {
            return date
        }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: string)
    }
}
