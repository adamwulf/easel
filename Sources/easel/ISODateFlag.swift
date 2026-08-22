import ArgumentParser
import EaselKit

/// Validates date flags before anything is sent to Canvas. easel requires a
/// full ISO 8601 date-time with an explicit time zone (offset or `Z`), because
/// Canvas treats zone-less values as UTC — a silent five/six hour surprise.
enum ISODateFlag {
    static func validate(_ value: String?, flag: String) throws {
        guard let value else {
            return
        }
        guard CanvasJSON.parseISO8601(value) != nil else {
            throw ValidationError(
                "\(flag) must be a full ISO 8601 date-time with a time zone, "
                    + "like \"2026-09-05T23:59:00-05:00\" or \"2026-09-06T04:59:00Z\"."
            )
        }
    }
}
