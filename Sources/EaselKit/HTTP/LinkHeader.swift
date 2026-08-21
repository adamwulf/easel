import Foundation

/// Canvas paginates list endpoints with RFC 5988 `Link` headers, for example:
/// `<https://school.instructure.com/api/v1/courses?page=2>; rel="next", <...>; rel="last"`.
public enum LinkHeader {
    /// Returns the URL tagged `rel="next"`, or nil when there is no next page.
    public static func nextPageURL(from header: String?) -> URL? {
        guard let header else {
            return nil
        }
        for part in header.split(separator: ",") {
            let segments = part.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let urlSegment = segments.first,
                  urlSegment.hasPrefix("<"),
                  urlSegment.hasSuffix(">") else {
                continue
            }
            let isNext = segments.dropFirst().contains { segment in
                let compact = segment.replacingOccurrences(of: " ", with: "")
                return compact == "rel=\"next\"" || compact == "rel=next"
            }
            if isNext {
                return URL(string: String(urlSegment.dropFirst().dropLast()))
            }
        }
        return nil
    }
}
