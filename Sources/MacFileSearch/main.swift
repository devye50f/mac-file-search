#if os(macOS)
import SwiftUI
import AppKit
import SearchCore

@main struct MacFileSearchApp: App {
    var body: some Scene {
        WindowGroup { ContentView().frame(minWidth: 980, minHeight: 620) }
        Window("Regex Creator", id: "regex") { RegexCreatorView() }.defaultSize(width: 680, height: 560)
    }
}

@MainActor final class SearchViewModel: ObservableObject {
    @Published var locations: [SearchLocation] = [SearchLocation(path: NSHomeDirectory())]
    @Published var field: Field = .filename
    @Published var op: Operator = .contains
    @Published var value = ""
    @Published var results: [FileRecord] = []
    @Published var status = "Ready — choose Indexed or Direct Scan"
    @Published var running = false
    private var task: Task<Void, Never>?, token: CancellationToken?
    private var generation = UUID()
    func runDirect() {
        cancel(); results = []; running = true; status = "Direct scan: 0 results"
        let generation = UUID(); self.generation = generation
        let token = CancellationToken(); self.token = token
        let search = SavedSearch(name: "Current", expression: .criterion(.init(field: field, op: op, value: value)), locations: locations)
        task = Task {
            let summary = await DirectScanner().search(search, token: token) { [weak self] batch in
                await MainActor.run {
                    guard self?.generation == generation else { return }
                    self?.results.append(contentsOf: batch)
                    self?.status = "Direct scan: \(self?.results.count ?? 0) results…"
                }
            }
            guard self.generation == generation, !Task.isCancelled else { return }
            status = "Direct scan complete — \(summary.matched) matches; \(summary.unknown) incomplete; \(summary.skipped) skipped"
            running = false
        }
    }
    func cancel() {
        generation = UUID()
        let tokenToCancel = token
        token = nil
        Task { await tokenToCancel?.cancel() }
        task?.cancel()
        task = nil
        running = false
    }
    func clear() { cancel(); value = ""; results = []; status = "Ready" }
}

struct ContentView: View {
    @StateObject private var model = SearchViewModel()
    @State private var selectedID: FileRecord.ID?
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        NavigationSplitView {
            List {
                Section("Search Locations") { ForEach(model.locations) { Text($0.path).lineLimit(1).help($0.path) } }
                Section("Saved Searches") { Text("Save current criteria from File > Save Search").foregroundStyle(.secondary) }
                Section("Regex Patterns") { Button("Open Regex Creator") { openWindow(id: "regex") } }
            }.navigationTitle("Mac File Search")
        } detail: {
            VStack(spacing: 10) {
                HStack {
                    Picker("Field", selection: $model.field) { ForEach(Field.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.frame(width: 150)
                    Picker("Operator", selection: $model.op) { ForEach(Operator.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.frame(width: 180)
                    TextField("Value", text: $model.value).accessibilityLabel("Filter value")
                    if model.op == .matchesRegex || model.op == .doesNotMatchRegex { Button("Create…") { openWindow(id: "regex") } }
                }
                HStack {
                    Button("Direct Scan", action: model.runDirect).keyboardShortcut(.return).disabled(model.running)
                    Button("Cancel", action: model.cancel).disabled(!model.running)
                    Button("Clear", action: model.clear)
                    Spacer(); Text(model.status).foregroundStyle(.secondary)
                }
                Table(model.results, selection: $selectedID) {
                    TableColumn("Name", value: \.name)
                    TableColumn("Location") { Text(($0.path as NSString).deletingLastPathComponent) }
                    TableColumn("Kind") { Text($0.kind ?? "Unknown") }
                    TableColumn("Size") { Text($0.size.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "—") }
                    TableColumn("Modified") { Text($0.modified?.formatted() ?? "—") }
                }
                if let item = model.results.first(where: { $0.id == selectedID }) {
                    GroupBox("Details") { HStack { VStack(alignment: .leading) { Text(item.name).bold(); Text(item.path).textSelection(.enabled); Text(item.contentFailure ?? "Metadata available") }; Spacer()
                        Button("Open") { NSWorkspace.shared.open(URL(fileURLWithPath: item.path)) }
                        Button("Reveal") { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)]) }
                        Button("Copy Path") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(item.path, forType: .string) }
                    }.padding(6) }
                }
            }.padding().navigationTitle("Results")
        }
    }
}

struct RegexCreatorView: View {
    @State private var literal = "invoice_"; @State private var raw = #"\Ainvoice_[0-9]{4}_[0-9]{4}\.pdf\z"#
    @State private var sample = "invoice_2026_0042.pdf"; @State private var caseSensitive = true
    private var result: String { do { let r = try NSRegularExpression(pattern: raw, options: caseSensitive ? [] : [.caseInsensitive]); return r.firstMatch(in: sample, range: NSRange(sample.startIndex..., in: sample)) == nil ? "No match" : "Match" } catch { return "Invalid: \(error.localizedDescription)" } }
    var body: some View { Form {
        Section("Guided Builder") { TextField("Literal text", text: $literal); Button("Escape literal") { raw = NSRegularExpression.escapedPattern(for: literal) }; Text("Literal blocks are escaped. Add digits as [0-9] or Unicode decimals as \\p{Nd}; use (?:…)? and {min,max} for optional/repeated blocks.").foregroundStyle(.secondary) }
        Section("Advanced ICU-compatible regex") { TextEditor(text: $raw).font(.system(.body, design: .monospaced)).frame(height: 90); Toggle("Case sensitive", isOn: $caseSensitive) }
        Section("Tester") { TextEditor(text: $sample).frame(height: 100); Text(result).bold(); Text("Testing uses Foundation NSRegularExpression, the same dialect as direct search.") }
        Section("Role template") { Text("Create bounded patterns for an explicit role phrase before or after a name. Qualified and ‘on behalf of’ matches require review; no authority is inferred.") }
    }.padding().accessibilityLabel("Regex Creator") }
}
#else
import Foundation
@main struct UnsupportedPlatform {
    static func main() { print("MacFileSearch is a native macOS application. Build this target on macOS 13 or later.") }
}
#endif
