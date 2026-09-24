import Foundation

public actor CancellationToken {
    private var cancelled = false
    public init() {}
    public func cancel() { cancelled = true }
    public func isCancelled() -> Bool { cancelled }
}

public struct DirectScanner: Sendable {
    public init() {}
    public func search(_ search: SavedSearch, token: CancellationToken = .init(), onBatch: @Sendable ([FileRecord]) async -> Void) async -> SearchSummary {
        var summary = SearchSummary(), batch: [FileRecord] = [], identities = Set<String>()
        let fm = FileManager.default
        for location in search.locations {
            if await token.isCancelled() { summary.messages.append("Cancelled"); break }
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: location.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                summary.skipped += 1; summary.messages.append("Unavailable location: \(location.path)"); continue
            }
            let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .isPackageKey, .isHiddenKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey, .addedToDirectoryDateKey, .fileResourceIdentifierKey]
            var enumerationFailures: [(path: String, description: String)] = []
            guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: location.path), includingPropertiesForKeys: keys,
                options: location.includeSubfolders ? [] : [.skipsSubdirectoryDescendants], errorHandler: { url, error in
                    enumerationFailures.append((url.path, error.localizedDescription))
                    return true
                }) else {
                if enumerationFailures.isEmpty {
                    summary.skipped += 1
                    summary.messages.append("Unable to enumerate: \(location.path)")
                } else {
                    summary.recordEnumerationFailures(enumerationFailures)
                }
                continue
            }
            while let url = enumerator.nextObject() as? URL {
                if await token.isCancelled() { summary.messages.append("Cancelled"); break }
                if location.excludedSubtrees.contains(where: { url.path == $0 || url.path.hasPrefix($0 + "/") }) { enumerator.skipDescendants(); continue }
                do {
                    let v = try url.resourceValues(forKeys: Set(keys))
                    if v.isSymbolicLink == true && v.isDirectory == true { enumerator.skipDescendants(); continue }
                    if v.isPackage == true && !search.settings.inspectPackages { enumerator.skipDescendants() }
                    guard v.isRegularFile == true else { continue }
                    if !search.settings.includeSystemLocations && Evaluator.isSystemPath(url.path) { summary.skipped += 1; continue }
                    let identity = (v.fileResourceIdentifier.map { String(describing: $0) }) ?? url.standardizedFileURL.path
                    guard identities.insert(identity).inserted else { continue }
                    let needsContent = search.expression.referencesContents
                    let extraction = needsContent ? TextExtractor.extract(url: url, limit: search.settings.maximumContentBytes) : .notRequested
                    let record = FileRecord(path: url.path, name: url.lastPathComponent, kind: url.pathExtension.lowercased(),
                        size: v.fileSize.map(Int64.init), created: v.creationDate, modified: v.contentModificationDate,
                        dateAdded: v.addedToDirectoryDate, isHidden: v.isHidden,
                        content: extraction.text, contentFailure: extraction.failure)
                    summary.examined += 1
                    switch Evaluator.evaluate(search.expression, record: record) {
                    case .yes: summary.matched += 1; batch.append(record)
                    case .unknown: summary.unknown += 1
                    case .no: break
                    }
                    if batch.count >= 100 { await onBatch(batch); batch.removeAll(keepingCapacity: true) }
                } catch { summary.skipped += 1; summary.messages.append("Unreadable: \(url.path)") }
            }
            summary.recordEnumerationFailures(enumerationFailures)
        }
        if !batch.isEmpty { await onBatch(batch) }
        return summary
    }
}

extension SearchSummary {
    mutating func recordEnumerationFailures(_ failures: [(path: String, description: String)]) {
        skipped += failures.count
        messages.append(contentsOf: failures.map { "Unreadable: \($0.path) (\($0.description))" })
    }
}

private extension Expression {
    var referencesContents: Bool {
        switch self { case .criterion(let c): return c.field == .contents; case .group(_, let xs): return xs.contains { $0.referencesContents } }
    }
}
