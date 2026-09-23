# Acceptance and verification record

Recorded 2026-09-22 in Ubuntu 24.04.4, x86_64, 17 GiB RAM, Swift 6.2.4. This is **not macOS** and is not evidence of Intel macOS operation.

## Support matrix

| Capability | Indexed search | Direct literal | Direct regex | Extraction/location | Status |
|---|---:|---:|---:|---|---|
| Names, path, extension, size, dates, hidden | Not wired | Yes | Yes for string fields | Filesystem metadata | Partial |
| TXT/Markdown/CSV/TSV/log/JSON/XML/YAML | Spotlight-dependent | Yes | Yes | Whole decoded text; no line map | Implemented with limits |
| RTF | Spotlight-dependent | Partial | Partial | Raw decoding, not rich-text normalization | Partial |
| PDF | Spotlight-dependent | No | No | PDFKit planned; scanned/OCR deferred | Blocked |
| DOCX | Spotlight-dependent | No | No | Main-document XML extraction planned | Blocked |
| Finder tags/useful document metadata | Not wired | No | No | Unknown, never a negative match | Blocked |
| Role template | N/A | Rule based | Foundation regex | Evidence text, no page map | Partial |

## Requirement status

### Implemented

- Native Swift package and SwiftUI/AppKit actions; resizable split view and native table.
- Serializable nested ALL/ANY/NOT model, typed fields, case choices, explicit filename-extension option, and three-valued missing-data semantics.
- Direct accessible-folder enumeration, subtree exclusions, package boundary, directory-symlink avoidance, overlap deduplication, batched results, cancellation token, content byte limit, and skip/unknown summary.
- Atomic JSON model/preset persistence and controlled fixture tests.
- Foundation/ICU regex validation and shared live-search semantics for basic flags.
- Conservative local role candidate rules. They do not infer authority or missing names.

### Partial

- GUI currently exposes a single criterion and one initial home scope; nested builder, scope editor, Advanced controls, saved-search management, highlighted snippets/captures, and Finder-tag controls need wiring.
- Cancellation is checked per enumerated entry, but generation IDs and independent worker termination are absent.
- Kind currently uses extension in portable scanning rather than macOS content types.
- Hidden entries are enumerated and file hidden state is read; hidden-ancestor policy is not yet selectable.
- Regex creator provides raw editing and a minimal guided literal escape, not the complete block builder/test suite.
- Role matcher covers several required negative cases but needs clause-boundary, Unicode, wrapped-line, and two-person/two-role fixtures.

### Blocked / not delivered

- Spotlight `NSMetadataQuery` route and indexed/direct reconciliation.
- PDFKit PDF, reliable RTF, and DOCX direct extractors with honest source mapping.
- An isolated regex worker with a hard time/memory budget. Current regex matching must not be considered safe for adversarial input.
- Quick Look preview, rich snippets, security-scoped bookmark identity, unavailable-volume UI, relative-date UI, local-time date boundaries, metadata selector, Finder tags, and system-rule editor.
- macOS compilation, x86_64 `.app`, launch, signing, Finder/Quick Look/Spotlight integration, restart behavior, and actual Intel runtime verification.
- 100,000-entry macOS benchmark, first-result/cancellation/worker-termination measurements, peak memory, idle CPU, and external-HDD measurements.

Because these are material Prompt 1 requirements, this project is an honest intermediate delivery, **not a completed app**.

## Verification checklist

Portable automated tests cover core string operators, explicit extension behavior, unknown negatives, nested three-valued groups, anchored regex/newline rejection, JSON round-trip, overlap deduplication, direct content discovery, and selected role positives/negatives. macOS integration checks must be run from `MACOS-VERIFICATION.md`.
