import Foundation

public struct RoleCandidate: Equatable, Sendable { public let name, role, evidence, label: String; public let isPartial: Bool }
public struct RoleOptions: Sendable {
    public var phrases: [String]; public var excludeQualifiers = ["former", "assistant", "deputy", "acting"]; public var includeQualified = false
    public init(phrases: [String]) { self.phrases = phrases }
}
public enum RoleMatcher {
    public static func candidates(in text: String, options: RoleOptions) -> [RoleCandidate] {
        let name = #"(?:[\p{L}][\p{L}'’\-]+(?:\s+[\p{L}]\.)?(?:\s+[\p{L}][\p{L}'’\-]+)?)"#
        let roles = options.phrases.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
        guard !roles.isEmpty else { return [] }
        let patterns = ["(?<name>\(name))\\s*,?\\s*(?:the\\s+)?(?<role>\(roles))", "(?<role>\(roles))\\s*,?\\s*(?<name>\(name))"]
        var out: [RoleCandidate] = []
        for pattern in patterns {
            guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let ns = text as NSString
            for match in re.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                let evidence = ns.substring(with: match.range)
                let lower = evidence.lowercased()
                let qualified = options.excludeQualifiers.first { lower.contains($0 + " ") }
                if qualified != nil && !options.includeQualified { continue }
                let candidateName = ns.substring(with: match.range(withName: "name"))
                let role = ns.substring(with: match.range(withName: "role"))
                let words = Set(candidateName.lowercased().split(separator: " ").map(String.init))
                let nonNames: Set<String> = ["please", "contact", "the", "for", "copies", "signed", "by", "former", "assistant", "deputy", "acting", "behalf", "of"]
                if !words.isDisjoint(with: nonNames) { continue }
                out.append(.init(name: candidateName, role: role, evidence: evidence,
                                 label: qualified.map { "qualified role: \($0)" } ?? "explicit role phrase",
                                 isPartial: !candidateName.contains(" ")))
            }
        }
        var seen = Set<String>()
        return out.filter {
            seen.insert("\($0.name.lowercased())\u{0}\($0.role.lowercased())\u{0}\($0.evidence.lowercased())").inserted
        }
    }
}
