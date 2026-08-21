import FellerBuncher
import Foundation
import Logging

/// Routes all swift-log output (including EaselKit's) to rotating files in
/// `~/Library/Logs/easel/`, keeping stdout for command results and stderr for
/// errors. If file logging cannot start, the tool still runs — it just notes
/// the problem once on stderr.
enum EaselLog {
    static func bootstrapIfPossible() -> LoggingHandle? {
        do {
            let logDir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Logs/easel", isDirectory: true)
            return try bootstrap(
                processName: "easel",
                logDir: logDir,
                console: .none,
                minimumLevel: .debug
            )
        } catch {
            FileHandle.standardError.write(Data("easel: file logging unavailable: \(error)\n".utf8))
            return nil
        }
    }
}
