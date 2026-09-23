# Mac File Search

Mac File Search is a local, native Swift/SwiftUI file-search prototype for macOS 13+ on Intel Macs. The search model is a separate `SearchCore` module. It never uploads search data, runs a daemon, or downloads cloud placeholders intentionally.

> **Current delivery status:** portable core and direct-scan tests pass on x86_64 Linux. This environment has no macOS SDK, Xcode, Spotlight, Finder, Quick Look, or code-signing tools, so an `.app` cannot honestly be built or runtime-verified here. See [ACCEPTANCE.md](ACCEPTANCE.md) before relying on it.

## Build, test, and package

On an Intel Mac with Xcode Command Line Tools and Swift 5.9 or later:

```sh
swift test
./scripts/build-app.sh
open dist/Mac\ File\ Search.app
```

The script compiles explicitly for `x86_64-apple-macosx13.0`, creates an ad-hoc-signed local app, and writes `dist/Mac-File-Search-macOS-x86_64.zip`. No paid Apple membership is needed. On first launch, Control-click **Open** if Gatekeeper asks. Grant access only to folders you wish to search; Full Disk Access may be needed for protected folders but does not override filesystem permissions.

## User guide

1. **Scope:** the sidebar starts at the home folder. The source model supports multiple roots, exclusions, and saved volume identity; UI editing of these is not complete.
2. **Filters:** select a field, operator, and value. Filename matching includes the extension in the current UI. Size values are logical bytes. Dates are filesystem dates and missing date-added is not substituted.
3. **Search route:** **Direct Scan** enumerates accessible selected folders and reads supported local text formats. Indexed/Spotlight search is not yet wired, so no result is described as exhaustive beyond accessible, evaluated files.
4. **Results:** select a row to see details. Use **Open**, **Reveal**, or **Copy Path**. Counts distinguish unknown/incomplete and skipped entries.
5. **Regex:** choose a regex operator and **Create…**, or use the sidebar. Foundation `NSRegularExpression` (ICU-compatible) is used by the creator and evaluator. The example whole-name expression is `\Ainvoice_[0-9]{4}_[0-9]{4}\.pdf\z`.
6. **Cancellation:** **Cancel** sets the scan token and drops the task. Search generations and isolated, enforceably terminated regex workers remain an acceptance blocker; do not use untrusted/adversarial regular expressions.
7. **Saved items:** JSON persistence and round-trip tests exist, but the complete create/edit/duplicate/delete GUI is not yet connected.

## Architecture and semantics

`SearchCore` owns serializable criteria, three-valued evaluation (`yes`, `no`, `unknown`), persistence, extraction, direct enumeration, and role candidates. The SwiftUI executable supplies a virtualized native `Table`. Missing/unreadable/unsupported values remain **unknown**, including under negative predicates. ALL/ANY/NOT use Kleene-style three-valued logic. Direct scans deduplicate by filesystem resource identifier where available, never traverse directory symlinks, and skip package descendants unless enabled.

Dates are absolute instants; UI calendar-day boundaries and relative dates must be resolved in the user's current calendar when a search starts. Direct content extraction currently supports UTF-8/UTF-16/Latin-1 plain text, Markdown, CSV/TSV, logs, JSON, XML, YAML, and plain RTF bytes only. PDF and DOCX extraction are not delivered.

## Privacy, dependencies, and license

Runtime dependencies are Apple/Foundation frameworks only. Swift Package Manager is used without third-party packages. Accordingly there are no bundled third-party licenses. Search preferences are intended for Application Support; searched documents are never modified. No telemetry, account, API, AI model, or network request is present.
