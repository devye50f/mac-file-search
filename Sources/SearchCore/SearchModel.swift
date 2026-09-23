import Foundation

public enum Truth: String, Codable, Sendable { case yes, no, unknown }
public enum GroupMode: String, Codable, Sendable { case all, any, not }
public enum Field: String, Codable, CaseIterable, Sendable {
    case filename, fullPath, kind, fileExtension, contents, hidden, systemLocation, created, modified, dateAdded, size
}
public enum Operator: String, Codable, CaseIterable, Sendable {
    case contains, equals, excludes, startsWith, endsWith, matchesRegex, doesNotMatchRegex
    case above, below, inclusiveRange, before, after
}
public enum CaseMode: String, Codable, Sendable { case sensitive, insensitive }

public struct Criterion: Codable, Hashable, Sendable {
    public var field: Field
    public var op: Operator
    public var value: String
    public var secondValue: String?
    public var caseMode: CaseMode
    public var includeExtensionInFilename: Bool
    public init(field: Field, op: Operator, value: String, secondValue: String? = nil,
                caseMode: CaseMode = .insensitive, includeExtensionInFilename: Bool = true) {
        self.field = field; self.op = op; self.value = value; self.secondValue = secondValue
        self.caseMode = caseMode; self.includeExtensionInFilename = includeExtensionInFilename
    }
}

public indirect enum Expression: Codable, Hashable, Sendable {
    case criterion(Criterion)
    case group(GroupMode, [Expression])
}

public struct SearchLocation: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var path: String
    public var volumeIdentifier: String?
    public var includeSubfolders: Bool
    public var excludedSubtrees: [String]
    public init(path: String, volumeIdentifier: String? = nil, includeSubfolders: Bool = true, excludedSubtrees: [String] = []) {
        id = UUID(); self.path = path; self.volumeIdentifier = volumeIdentifier
        self.includeSubfolders = includeSubfolders; self.excludedSubtrees = excludedSubtrees
    }
}

public struct SearchSettings: Codable, Hashable, Sendable {
    public var inspectPackages = false
    public var includeSystemLocations = false
    public var followDirectorySymlinks = false
    public var maximumContentBytes = 20 * 1_024 * 1_024
    public init() {}
}

public struct SavedSearch: Codable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var expression: Expression
    public var locations: [SearchLocation]
    public var settings: SearchSettings
    public init(name: String, expression: Expression, locations: [SearchLocation], settings: SearchSettings = .init()) {
        id = UUID(); self.name = name; self.expression = expression; self.locations = locations; self.settings = settings
    }
}

public struct FileRecord: Sendable, Identifiable {
    public var id: String { path }
    public let path: String
    public let name: String
    public let kind: String?
    public let size: Int64?
    public let created: Date?
    public let modified: Date?
    public let dateAdded: Date?
    public let isHidden: Bool?
    public let content: String?
    public let contentFailure: String?
}

public struct SearchSummary: Sendable {
    public var examined = 0, matched = 0, unknown = 0, skipped = 0
    public var messages: [String] = []
    public init() {}
}
