import Foundation

public struct PatternPreset: Codable, Identifiable, Sendable {
    public var id = UUID(); public var name: String; public var pattern: String; public var caseSensitive: Bool
    public init(name: String, pattern: String, caseSensitive: Bool) { self.name = name; self.pattern = pattern; self.caseSensitive = caseSensitive }
}
public struct StoredData: Codable, Sendable { public var searches: [SavedSearch] = []; public var patterns: [PatternPreset] = []; public init() {} }

public enum Store {
    public static func load(from url: URL) throws -> StoredData { try JSONDecoder().decode(StoredData.self, from: Data(contentsOf: url)) }
    public static func save(_ data: StoredData, to url: URL) throws {
        let encoded = try JSONEncoder().encode(data); try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: url, options: .atomic)
    }
}
