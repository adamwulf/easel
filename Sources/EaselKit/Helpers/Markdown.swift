import Foundation

/// Helpers for rendering models as Markdown for the `md` output format. Canvas
/// records are flat, so each model builds an H2 heading plus a labeled field
/// list (and, where it has children, a table). Scalar text is escaped so titles
/// and values render literally; HTML bodies (page body, assignment description)
/// pass through verbatim because Canvas stores them as HTML and Markdown
/// renderers accept inline HTML. Field labels keep Canvas's snake_case names, so
/// output cross-references the Canvas docs the same way `json` does.
enum Markdown {
    /// A heading line: `## Title (handle)`. An empty title falls back to
    /// "Untitled"; `handle` (an id or url) is appended in parentheses when set.
    static func heading(_ level: Int, _ title: String?, handle: String? = nil) -> String {
        let name = title.flatMap { $0.isEmpty ? nil : $0 } ?? "Untitled"
        let hashes = String(repeating: "#", count: level)
        guard let handle else { return "\(hashes) \(escapeInline(name))" }
        return "\(hashes) \(escapeInline(name)) (\(handle))"
    }

    /// A `- **label:** value` line, or nil when the value is nil/empty so the
    /// caller drops the line rather than printing a blank field.
    static func field(_ label: String, _ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return "- **\(label):** \(escapeInline(value))"
    }

    /// A field whose value is a URL, rendered as a `<autolink>` so it stays a
    /// working link without needing the escaping the emphasis characters get.
    static func urlField(_ label: String, _ url: String?) -> String? {
        guard let url, !url.isEmpty else { return nil }
        return "- **\(label):** <\(url)>"
    }

    /// Assembles a record: the heading and its bullet fields form one block,
    /// then each non-empty section follows after a blank line.
    static func document(heading: String, fields: [String?], sections: [String?] = []) -> String {
        var blocks: [String] = []
        let bullets = fields.compactMap { $0 }
        blocks.append(bullets.isEmpty ? heading : heading + "\n" + bullets.joined(separator: "\n"))
        blocks.append(contentsOf: sections.compactMap { $0 }.filter { !$0.isEmpty })
        return blocks.joined(separator: "\n\n")
    }

    /// A GitHub-style Markdown table. Cells are escaped and flattened to a
    /// single line so pipes and newlines never break the columns.
    static func table(headers: [String], rows: [[String]]) -> String {
        var lines = ["| " + headers.map(cell).joined(separator: " | ") + " |"]
        lines.append("| " + headers.map { _ in "---" }.joined(separator: " | ") + " |")
        for row in rows {
            lines.append("| " + row.map(cell).joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Scalar formatters (nil in -> nil out, so fields drop cleanly)

    static func date(_ value: Date?) -> String? {
        guard let value else { return nil }
        // Created locally so no formatter state crosses concurrency domains.
        return ISO8601DateFormatter().string(from: value)
    }

    static func number(_ value: Double?) -> String? {
        guard let value else { return nil }
        if value == value.rounded() && abs(value) < 1e15 {
            return String(Int(value))
        }
        return String(value)
    }

    static func bool(_ value: Bool?) -> String? {
        value.map { $0 ? "true" : "false" }
    }

    static func int(_ value: Int?) -> String? {
        value.map(String.init)
    }

    static func list(_ values: [String]?) -> String? {
        guard let values, !values.isEmpty else { return nil }
        return values.joined(separator: ", ")
    }

    // MARK: - Escaping

    /// Escapes the Markdown metacharacters that break inline text. Angle
    /// brackets are escaped so a title like `Using <canvas>` renders literally
    /// instead of as inline HTML (HTML bodies pass through their own section,
    /// never this function). Underscore is intentionally left alone: CommonMark
    /// treats intraword `_` literally, so tokens like `online_upload` stay
    /// readable while still rendering correctly.
    static func escapeInline(_ text: String) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        for character in text {
            switch character {
            case "\\", "`", "*", "[", "]", "<", ">":
                out.append("\\")
                out.append(character)
            default:
                out.append(character)
            }
        }
        return out
    }

    /// Escapes a table cell: inline metacharacters, plus pipes, and newlines
    /// collapsed to spaces so multi-line values stay on one row.
    static func cell(_ text: String) -> String {
        escapeInline(text)
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
