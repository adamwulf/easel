import Foundation

/// Reads values out of `.env` files. Starting in a directory (the current
/// working directory by default), walks up parent directories until the
/// filesystem root; the closest `.env` that defines the key wins.
public enum DotEnv {
    public static func loadValue(forKey key: String, startingIn directory: URL? = nil) -> String? {
        var dir = (directory ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).standardizedFileURL
        while true {
            let envFileURL = dir.appendingPathComponent(".env")
            if let value = parseValue(forKey: key, in: envFileURL) {
                return value
            }
            let parent = dir.deletingLastPathComponent().standardizedFileURL
            if parent.path == dir.path {
                break
            }
            dir = parent
        }
        return nil
    }

    /// Parses one `.env` file. Skips blank lines and `#` comments, allows an
    /// optional `export ` prefix, requires an exact `KEY=` match, and strips one
    /// pair of surrounding single or double quotes. Empty values count as unset.
    static func parseValue(forKey key: String, in fileURL: URL) -> String? {
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }
        for line in contents.split(separator: "\n", omittingEmptySubsequences: true) {
            var assignment = line.trimmingCharacters(in: .whitespaces)
            if assignment.isEmpty || assignment.hasPrefix("#") {
                continue
            }
            if assignment.hasPrefix("export ") {
                assignment = String(assignment.dropFirst("export ".count)).trimmingCharacters(in: .whitespaces)
            }
            guard assignment.hasPrefix(key + "=") else {
                continue
            }
            var value = String(assignment.dropFirst(key.count + 1)).trimmingCharacters(in: .whitespaces)
            if value.count >= 2,
               (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            return value.isEmpty ? nil : value
        }
        return nil
    }
}
