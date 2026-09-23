import Foundation

public struct Extraction: Sendable {
    public let text: String?, failure: String?
    static let notRequested = Extraction(text: nil, failure: nil)
}

public enum TextExtractor {
    private static let extensions = Set(["txt", "md", "markdown", "csv", "tsv", "log", "json", "xml", "yaml", "yml", "rtf"])
    public static func extract(url: URL, limit: Int) -> Extraction {
        guard extensions.contains(url.pathExtension.lowercased()) else { return Extraction(text: nil, failure: "Unsupported direct content format") }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path), let size = attrs[.size] as? NSNumber else { return Extraction(text: nil, failure: "Unreadable") }
        guard size.intValue <= limit else { return Extraction(text: nil, failure: "Content exceeds \(limit)-byte limit") }
        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else { return Extraction(text: nil, failure: "Unreadable") }
        for encoding in [String.Encoding.utf8, .utf16, .utf16LittleEndian, .utf16BigEndian, .isoLatin1] {
            if let text = String(data: data, encoding: encoding) { return Extraction(text: text, failure: nil) }
        }
        return Extraction(text: nil, failure: "Unsupported text encoding")
    }
}
