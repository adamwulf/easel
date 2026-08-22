import ArgumentParser
import Foundation

/// Reads text content for options that accept a file path, where `-` means
/// standard input.
enum FileInput {
    static func read(_ path: String) throws -> String {
        if path == "-" {
            guard let data = try FileHandle.standardInput.readToEnd(),
                  let text = String(data: data, encoding: .utf8) else {
                throw ValidationError("Could not read UTF-8 text from stdin.")
            }
            return text
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }
}
