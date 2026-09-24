import XCTest
@testable import SearchCore

final class SearchCoreTests: XCTestCase {
    let known = FileRecord(path: "/tmp/Invoice.PDF", name: "Invoice.PDF", kind: "com.adobe.pdf", size: 42,
                           created: Date(timeIntervalSince1970: 10), modified: nil, dateAdded: nil, isHidden: false,
                           content: "signed by mr william james, secretary", contentFailure: nil)
    func testOperatorsAndFilenameExtensionChoice() {
        XCTAssertEqual(Evaluator.evaluate(.init(field: .filename, op: .contains, value: "invoice"), record: known), .yes)
        XCTAssertEqual(Evaluator.evaluate(.init(field: .filename, op: .endsWith, value: ".pdf"), record: known), .yes)
        XCTAssertEqual(Evaluator.evaluate(.init(field: .filename, op: .equals, value: "Invoice", caseMode: .sensitive, includeExtensionInFilename: false), record: known), .yes)
        XCTAssertEqual(Evaluator.evaluate(.init(field: .fileExtension, op: .equals, value: "pdf"), record: known), .yes)
    }
    func testUnknownNeverMakesNegativeTrue() {
        XCTAssertEqual(Evaluator.evaluate(.init(field: .modified, op: .after, value: "2026-01-01T00:00:00Z"), record: known), .unknown)
        let absent = FileRecord(path: "x", name: "x", kind: nil, size: nil, created: nil, modified: nil, dateAdded: nil, isHidden: nil, content: nil, contentFailure: "failed")
        XCTAssertEqual(Evaluator.evaluate(.init(field: .contents, op: .doesNotMatchRegex, value: "secret"), record: absent), .unknown)
    }
    func testThreeValuedGroups() {
        let yes = Expression.criterion(.init(field: .filename, op: .contains, value: "Invoice"))
        let unknown = Expression.criterion(.init(field: .dateAdded, op: .after, value: "2020-01-01T00:00:00Z"))
        XCTAssertEqual(Evaluator.evaluate(.group(.all, [yes, unknown]), record: known), .unknown)
        XCTAssertEqual(Evaluator.evaluate(.group(.any, [yes, unknown]), record: known), .yes)
        XCTAssertEqual(Evaluator.evaluate(.group(.not, [unknown]), record: known), .unknown)
    }
    func testSizeInclusiveRangeAndInvalidOrdering() {
        XCTAssertEqual(Evaluator.evaluate(.init(field: .size, op: .inclusiveRange, value: "40", secondValue: "50"), record: known), .yes)
        XCTAssertEqual(Evaluator.evaluate(.init(field: .size, op: .inclusiveRange, value: "50", secondValue: "40"), record: known), .unknown)
        XCTAssertEqual(Evaluator.evaluate(.init(field: .size, op: .inclusiveRange, value: "40"), record: known), .unknown)
    }
    func testRegexFixture() {
        let c = Criterion(field: .filename, op: .matchesRegex, value: #"\Ainvoice_[0-9]{4}_[0-9]{4}\.pdf\z"#, caseMode: .sensitive)
        func record(_ name: String) -> FileRecord { .init(path: name, name: name, kind: nil, size: 0, created: nil, modified: nil, dateAdded: nil, isHidden: false, content: nil, contentFailure: nil) }
        XCTAssertEqual(Evaluator.evaluate(c, record: record("invoice_2026_0042.pdf")), .yes)
        XCTAssertEqual(Evaluator.evaluate(c, record: record("old_invoice_2026_0042.pdf")), .no)
        XCTAssertEqual(Evaluator.evaluate(c, record: record("invoice_2026_0042.pdf\n")), .no)
    }
    func testPersistenceRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("store.json")
        let search = SavedSearch(name: "PDFs", expression: .criterion(.init(field: .fileExtension, op: .equals, value: "pdf")), locations: [.init(path: "/tmp")])
        try Store.save(.init(searches: [search], patterns: [.init(name: "invoice", pattern: "invoice", caseSensitive: false)]), to: url)
        XCTAssertEqual(try Store.load(from: url).searches.first?.name, "PDFs")
    }
    func testRoleExamples() {
        let options = RoleOptions(phrases: ["secretary", "Secretary of the Board", "board secretary"])
        XCTAssertEqual(RoleMatcher.candidates(in: "signed by mr william james, secretary", options: options).first?.name.lowercased(), "william james")
        XCTAssertTrue(RoleMatcher.candidates(in: "Please contact the secretary for copies.", options: options).isEmpty)
        XCTAssertTrue(RoleMatcher.candidates(in: "William James, former secretary", options: options).isEmpty)
        XCTAssertTrue(RoleMatcher.candidates(in: "signed by William James on behalf of the secretary", options: options).isEmpty)
        XCTAssertEqual(RoleMatcher.candidates(in: "Secretary James", options: options).first?.isPartial, true)
    }
    func testDirectScanAndOverlapDeduplication() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("needle".utf8).write(to: root.appendingPathComponent("one.txt"))
        let search = SavedSearch(name: "test", expression: .criterion(.init(field: .contents, op: .contains, value: "needle")), locations: [.init(path: root.path), .init(path: root.path)])
        let box = ResultBox(); let summary = await DirectScanner().search(search) { await box.add($0) }
        let delivered = await box.count
        XCTAssertEqual(summary.matched, 1); XCTAssertEqual(delivered, 1)
    }
    func testEmptyFilenameSearchFindsFilesAndReportsExaminedCount() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("fixture".utf8).write(to: root.appendingPathComponent("visible.txt"))
        let search = SavedSearch(name: "all", expression: .criterion(.init(field: .filename, op: .contains, value: "")), locations: [.init(path: root.path)])
        let box = ResultBox()
        let summary = await DirectScanner().search(search) { await box.add($0) }
        let delivered = await box.count
        XCTAssertEqual(summary.examined, 1)
        XCTAssertEqual(summary.matched, 1)
        XCTAssertEqual(delivered, 1)
    }
    func testUnavailableLocationIsReported() async {
        let missing = "/path/that/does/not/exist/\(UUID().uuidString)"
        let search = SavedSearch(name: "missing", expression: .criterion(.init(field: .filename, op: .contains, value: "")), locations: [.init(path: missing)])
        let summary = await DirectScanner().search(search) { _ in }
        XCTAssertEqual(summary.skipped, 1)
        XCTAssertTrue(summary.messages.contains { $0.contains("Unavailable location") })
    }
}
actor ResultBox { var count = 0; func add(_ values: [FileRecord]) { count += values.count } }

private extension StoredData {
    init(searches: [SavedSearch], patterns: [PatternPreset]) { self.init(); self.searches = searches; self.patterns = patterns }
}
