import Foundation

public enum Evaluator {
    public static func evaluate(_ expression: Expression, record: FileRecord) -> Truth {
        switch expression {
        case .criterion(let c): return evaluate(c, record: record)
        case .group(let mode, let children):
            let values = children.map { evaluate($0, record: record) }
            switch mode {
            case .all:
                if values.contains(.no) { return .no }
                return values.contains(.unknown) ? .unknown : .yes
            case .any:
                if values.contains(.yes) { return .yes }
                return values.contains(.unknown) ? .unknown : .no
            case .not:
                guard children.count == 1 else { return .unknown }
                switch values[0] { case .yes: return .no; case .no: return .yes; case .unknown: return .unknown }
            }
        }
    }

    public static func evaluate(_ c: Criterion, record r: FileRecord) -> Truth {
        if c.field == .size {
            guard let n = r.size, let first = Int64(c.value) else { return .unknown }
            switch c.op { case .above: return n > first ? .yes : .no; case .below: return n < first ? .yes : .no
            case .inclusiveRange:
                guard let s = c.secondValue, let last = Int64(s), first <= last else { return .unknown }
                return (first...last).contains(n) ? .yes : .no
            default: return .unknown }
        }
        if [.created, .modified, .dateAdded].contains(c.field) {
            let date = c.field == .created ? r.created : (c.field == .modified ? r.modified : r.dateAdded)
            guard let date, let boundary = parseISO8601(c.value) else { return .unknown }
            switch c.op {
            case .before: return date < boundary ? .yes : .no
            case .after: return date > boundary ? .yes : .no
            case .inclusiveRange:
                guard let second = c.secondValue, let end = parseISO8601(second), boundary <= end else { return .unknown }
                return (boundary...end).contains(date) ? .yes : .no
            default: return .unknown
            }
        }
        let source: String?
        switch c.field {
        case .filename:
            source = c.includeExtensionInFilename ? r.name : (r.name as NSString).deletingPathExtension
        case .fullPath: source = r.path
        case .kind: source = r.kind
        case .fileExtension: source = (r.name as NSString).pathExtension
        case .contents: source = r.content
        case .hidden: source = r.isHidden.map(String.init)
        case .systemLocation: source = Self.isSystemPath(r.path).description
        default: source = nil
        }
        guard let source else { return .unknown }
        let options: String.CompareOptions = c.caseMode == .insensitive ? [.caseInsensitive, .diacriticInsensitive] : []
        if c.field == .fileExtension, c.op == .equals || c.op == .excludes {
            let extensions = c.value
                .split(whereSeparator: { $0 == "," || $0 == ";" || $0.isWhitespace })
                .map { $0.hasPrefix(".") ? String($0.dropFirst()) : String($0) }
                .filter { !$0.isEmpty }
            guard !extensions.isEmpty else { return .unknown }
            let matches = extensions.contains { source.compare($0, options: options) == .orderedSame }
            return (c.op == .excludes ? !matches : matches) ? .yes : .no
        }
        let positive: Bool
        switch c.op {
        case .contains, .excludes: positive = source.range(of: c.value, options: options) != nil
        case .equals: positive = source.compare(c.value, options: options) == .orderedSame
        case .startsWith: positive = source.range(of: c.value, options: [.anchored] + options) != nil
        case .endsWith: positive = source.range(of: c.value, options: [.anchored, .backwards] + options) != nil
        case .matchesRegex, .doesNotMatchRegex:
            do {
                let flags: NSRegularExpression.Options = c.caseMode == .insensitive ? [.caseInsensitive] : []
                let regex = try NSRegularExpression(pattern: c.value, options: flags)
                positive = regex.firstMatch(in: source, range: NSRange(source.startIndex..., in: source)) != nil
            } catch { return .unknown }
        default: return .unknown
        }
        let negative = c.op == .excludes || c.op == .doesNotMatchRegex
        return (negative ? !positive : positive) ? .yes : .no
    }

    public static func isSystemPath(_ path: String) -> Bool {
        ["/System", "/Library", "/private", "/usr", "/bin", "/sbin"].contains { path == $0 || path.hasPrefix($0 + "/") }
    }

    private static func parseISO8601(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}

private extension String.CompareOptions {
    static func + (lhs: Self, rhs: Self) -> Self { lhs.union(rhs) }
}
