# Mac File Search — Codex Handover Prompts

## How to use

Give this file to Codex in the project workspace, preferably on the Intel Mac where the app will run, and ask it to execute **Prompt 1**. Prompt 1 contains the complete scope and authorizes implementation through local delivery; it is not a request for a plan only.

**Prompt 2** is a follow-up for a focused correctness review. **Prompt 3** is a follow-up for release verification and packaging. They reinforce requirements already included in Prompt 1; you do not need to keep sending prompts to authorize ordinary progress. **Prompt 4** resumes interrupted work.

No preparation is required for hardware details that Codex can inspect. If the execution environment is not the target Mac, Codex must identify what it cannot verify there.

The working name is **Mac File Search**. Renaming and elaborate branding are not priorities.

---

## Prompt 1 — Build and deliver the app

You are responsible for end-to-end implementation of a lightweight native macOS file-search app for my personal use on an **Intel Mac**. Build working software, verify it, and deliver an installable local .app and reproducible source project. Do not stop at a proposal, mockup, source snippets, or an untested claim that it works.

### Working approach and environment

1. Inspect the workspace and applicable project instructions. If a project already exists, preserve unrelated work and extend it.
2. Establish the actual target macOS version, Intel architecture, available RAM, Xcode/Swift toolchain, and build environment. Do not infer the OS from a browser user agent. If running on my Mac, detect these directly. If running elsewhere, use available target information and ask only for genuinely blocking facts.
3. Use Swift and native Apple frameworks. Choose AppKit and/or SwiftUI according to target compatibility and table performance. Produce an x86_64 build; a universal build is optional. Avoid Electron, a browser-based UI, a bundled language model, and an always-running custom indexing service.
4. Make routine implementation choices yourself and document significant assumptions. Proceed through implementation, meaningful tests, fixes, and packaging without requesting approval at every milestone. Do not incur fees or publish externally as part of this local delivery.
5. Maintain concise project documentation: requirements/acceptance status, architectural decisions, current progress, and exact build/test/run instructions. Use existing documentation rather than creating redundant files.
6. If macOS execution is unavailable, do all useful portable work and prepare the native project/build scripts. Clearly identify the remaining Mac build and runtime checks. Do not represent a Linux build, mocked framework, cross-compilation, or an Apple Silicon test as verified Intel operation.
7. The app operates locally without cloud processing, telemetry, accounts, or API calls. No paid Apple membership is required for this personal local build. Do not disable OS security protections to make it work.

### Product and interface

Build a native GUI containing:
- A sidebar for selected search locations, named saved searches, and reusable regex patterns.
- A filter builder with field, operator, and value controls.
- A sortable results table, with name, path/location, kind, size, and relevant dates.
- A preview/details card with Quick Look where available, metadata, and content-match snippets.
- Open, Reveal in Finder, and Copy Path actions.
- Clear search state, progressive result counts, cancellation, and a useful summary of skipped or incomplete coverage.
- Keyboard navigation, accessible control labels, sensible tab order, and support for resizing.

Keep unusual metadata and advanced regex options out of the default path. Provide an Advanced section.

A terminal interface is deferred. Keep the search model independent of the GUI so one can be added later.

### Search criteria

Support nested ALL / ANY / NOT groups and combinations of:

| Field | Required behavior |
| --- | --- |
| Filename | Contains, equals, does not contain, starts with, ends with, matches regex, does not match regex. Make inclusion/exclusion of the extension explicit. |
| Full path | Contains, equals, excludes, matches regex, does not match regex. |
| Kind | Friendly type categories using available content-type information, separate from the literal extension filter. |
| Extension | One or several extensions, with inclusion/exclusion. Normalize a leading dot and offer predictable case handling. |
| Finder tags | Any/all/none of selected tags; clarify behavior when tags are unavailable. |
| Metadata | A documented, typed set of useful fields such as author, title, comments, image dimensions, and duration where available; an advanced attribute selector can expose supported additional fields. Do not promise every field for every format. |
| Contents | Literal/phrase and regex matching in documented supported formats. Distinguish indexed search semantics from direct text matching. |
| Hidden status | Any / hidden / visible, accounting for dot names, supported filesystem flags, and clearly defined treatment of hidden ancestor folders. |
| System locations | Include/exclude a documented set of OS/application-support paths, separate from hidden status. This is a location rule, not an invented universal system-file attribute. Allow inspection/editing of the rules. |
| Dates | Created, modified, and date added to current folder when available; before, after, inclusive date range, and relative ranges such as last 7 days. Do not substitute another timestamp for missing date-added data. |
| Location | One or multiple folders or mounted local/external volumes, with include-subfolders and excluded-subtree controls. |
| File size | Above, below, inclusive range; display units explicitly. Default to logical file bytes. Do not mislabel a directory entry's size as the total contents of that folder. |

Additional rules:
- Treat created/modified filesystem dates separately from document-internal content dates exposed as metadata.
- Define date boundaries, local time-zone handling, and relative-date semantics. Recompute relative ranges each time a saved search runs.
- Make case sensitivity explicit. Preserve non-English names and text; do not restrict all names to ASCII.
- Distinguish missing, unsupported, unreadable, and genuinely absent values. Failed extraction or unavailable metadata must not become a successful "does not contain" or NOT match. Define and test the behavior of unknown values through compound groups; show incomplete evaluation separately.
- Save the criteria and settings, not a stale result list. Support naming, editing, duplicating, deleting, and rerunning saved searches across app restarts.
- Preserve location identity when practical and report unavailable volumes. Never silently replace an unavailable saved scope with the whole computer or an unrelated drive that happens to have the same name.

### Search architecture and coverage

Use two explicitly described routes:

**Indexed search:** use Spotlight/NSMetadataQuery for responsive queries over eligible indexed files. It may omit unindexed, excluded, stale, or otherwise unavailable data.

**Direct scan:** independently enumerate selected accessible folders/volumes and evaluate supported criteria. This must work for basic filesystem filters and supported direct content extraction even when Spotlight has no entry.

Do not call indexed-only results exhaustive. Make the chosen route and its limitations intelligible. A user must be able to request a direct scan of the chosen scope; background fallback must not conceal an unexpectedly costly whole-disk scan.

Plan queries so that inexpensive location/name/type/date/size filters reduce work before content extraction when logically valid. Preserve OR/NOT semantics: an optimization must never narrow away legitimate matches. If a filter cannot be evaluated safely through an index, retain a direct evaluation route or mark the limitation.

Implement:
- Background work, bounded concurrency, compiled-pattern reuse, batched result delivery, and a results table that does not create a heavy view for every file.
- Prompt cancellation and a new-search generation identity so late results from an old search cannot pollute a new one.
- Stable deduplication for overlapping scopes and indexed/direct results, with a documented policy for symlinks, hard links, and aliases.
- No following symlink loops; no entering unrelated mounted volumes by accident.
- Clear behavior for macOS packages/bundles, with an advanced option to inspect their contents.
- Handling for permissions, protected folders, files changing or disappearing during search, disconnected drives, and unavailable cloud placeholders.
- Ordinary system permission guidance where needed, including Full Disk Access if relevant. It does not override filesystem access restrictions.
- No automatic cloud-file downloads or external-service calls.
- No continuous scanning while idle.

The direct route is complete only with respect to accessible, successfully evaluated files and the supported predicates. Summarize the scope, exclusions, errors, skipped files, timeouts, and unsupported criteria.

### Content formats

Before implementation, record a format support matrix distinguishing indexed search, direct literal matching, direct regex matching, extraction completeness, and location/snippet support.

Default v1 direct-extraction priorities, unless my actual needs indicate otherwise:
1. Plain-text formats such as TXT, Markdown, CSV/TSV, logs, JSON, and XML, with documented encoding handling.
2. Text-bearing PDFs through a suitable native framework.
3. RTF and DOCX where reliable local extraction can be implemented with native APIs or a small justified dependency.

Treat these as explicit implementation priorities, not a claim of universal document support. If RTF/DOCX extraction cannot be delivered reliably on the target OS, mark the gap in the acceptance report and explain it. Do not quietly count filename search as content support.

Document PDF reading-order limits and DOCX coverage, such as main text versus headers, footers, or text boxes. A scanned page, encrypted file, extraction failure, size limit, or partially extracted document must not be reported as a complete negative match.

For direct regex, match the extracted text itself. Do not assume the complete raw text can be retrieved from Spotlight. State line/paragraph/page boundaries and any supported multiline behavior. Do not split content into arbitrary chunks that silently miss matches spanning boundaries. Set bounded sizes and report skips explicitly.

Map snippets and captures back to the displayed source text. If normalization joins wrapped lines or changes whitespace, preserve enough mapping to show honest evidence.

### Regex search and embedded creator

Use one documented regex dialect and matching implementation throughout the search engine, preview tester, saved patterns, and role template. Prefer Foundation NSRegularExpression / ICU compatibility if suitable for the supported OS. Verify specific supported features against the actual runtime. Do not mix Swift-native, JavaScript, or PCRE semantics silently.

Add an embedded creator accessible beside every regex filter. It must also open in a detachable window for independent testing against pasted text. It is one app, not a second program.

The guided builder supports:
- Literal text, safely escaped as literal input.
- Digits with a distinction between ASCII 0–9 and Unicode decimal digits.
- Unicode letters, whitespace, user-specified character sets, and alternatives.
- Optional segments, grouping, and exact/minimum/maximum repetitions.
- Match anywhere versus whole value, and appropriate line-boundary controls.
- Explicit flags for case sensitivity, multiline anchors, and whether dot spans newlines.
- Short descriptions of the generated blocks.

The advanced editor supports raw compatible regex, live syntax validation, highlighted matches, capture-group inspection, and copy/paste. Do not promise to convert every handwritten regex back into visual blocks; preserve it in advanced mode when it cannot be represented faithfully.

The tester supports:
- Pasted sample text or a deliberately selected sample of filenames/content.
- "Should match" and "should not match" examples.
- Visible pass/fail results and matched spans.
- "Use in search" and reusable named pattern presets.
- Storing tests and flags with a pattern where useful.
- No claim that a few examples uniquely identify the intended general pattern.

Prevent pathological matching from freezing the application. Moving a regex onto a background thread alone is not sufficient. Establish an enforceable execution budget/cancellation mechanism supported by the chosen engine, or use an isolated worker that can be terminated. Cover preview matching and document search, not just one path. Report aborted evaluation as unknown/timed out, never "no match."

Example fixture:
- Whole-filename pattern: \Ainvoice_[0-9]{4}_[0-9]{4}\.pdf\z
- Match: invoice_2026_0042.pdf
- Reject: invoice_26_0042.pdf
- Reject: old_invoice_2026_0042.pdf
- Reject: invoice_2026_0042.pdf followed by an actual newline.
- Uppercase extension behavior must follow the selected case option.

### "Find a person by role" template

Include a guided, local, rule-based template within the regex creator. It helps search document text for an unknown person's name connected to a chosen position.

Inputs:
- Role, such as secretary.
- User-selected equivalent phrases, such as board secretary, secretary to the board, secretary of the board, or corporate secretary. These are not automatically interchangeable.
- Name before role, role before name, or both.
- Optional honorifics, middle initials/names, punctuation, and bounded layout whitespace.
- Optional signing-language requirement.
- Optional explicit board-context requirement.
- Qualifiers to exclude or flag, such as former, assistant, deputy, or acting.
- Whether "on behalf of" references should be returned and how they are labelled.

Use several bounded patterns/rules where clearer than one enormous regex. Preserve the actual role phrase. Handle Unicode, apostrophes, and hyphens without assuming every culture uses first-name/last-name order.

Present candidate results with:
- File/path and page or other text location when reliably available.
- Extracted name as written, including partial-name status.
- Role phrase as written and any user-approved normalized category.
- Surrounding passage with highlighted evidence.
- Matched rule and meaningful labels such as explicit role phrase, surname only, qualified role, or ambiguous association. Avoid invented numerical confidence scores.

Never infer an unobserved first name, treat every nearby capitalized phrase as a person, or assert that a matched title establishes actual authority or a legally effective signature. The feature identifies textual candidates.

Required examples, in case-sensitive and case-insensitive configurations as appropriate:
1. "signed by mr william james, secretary" -> candidate William James / secretary, preserving original casing in evidence.
2. "mr william s. james, the secretary" -> candidate William S. James / secretary.
3. "Secretary James" -> James; partial/surname-only; no invented first name.
4. "William James, Secretary of the Board" -> explicit board-secretary phrase.
5. "The board secretary, William James, signed..." -> name after role.
6. "William James, former secretary" -> flagged or excluded according to settings.
7. "William James, assistant secretary" -> not silently treated as an unqualified secretary when that qualifier is excluded.
8. "signed by William James on behalf of the secretary" -> do not assign the secretary role to William James.
9. "William James attended the meeting. He was subsequently appointed secretary." -> no automatic person-role link; cross-sentence pronoun resolution is out of scope.
10. "Please contact the secretary for copies." -> no invented named-person match.
11. Wrapped-line, apostrophe, hyphenated, and Unicode-name examples -> preserve evidence and document supported behavior.
12. Passages containing two people and two roles -> do not connect names across unrelated clauses merely because the words are nearby.

In strict board mode, the word "secretary" alone is insufficient. Define whether board context must be in the explicit role phrase or a bounded surrounding passage; default to explicit evidence and show the setting.

No LLM, external API, downloaded language model, generic coreference resolution, or automatic AI pattern generation in v1. Keep an extension point for later optional language analysis.

### Boundaries

Defer:
- Date deleted, deletion history, recovery, and trash-history reconstruction.
- OCR of scanned documents/images.
- General archive-content search; DOCX container handling is only for document extraction.
- Searching disconnected drives via a persistent inventory.
- A custom full-disk content index, always-on watcher, or background daemon.
- A separate terminal interface, separate regex app, universal visual support for every regex construct, and AI natural-language generation.
- Bulk rename, replacement, move, or deletion actions.

The app is a search/preview tool. Save its own preferences and presets; do not modify searched documents.

### Validation and performance

Use controlled fixtures, not a blanket scan of private user data. Test real filesystem and macOS integrations where available, alongside pure query/model tests.

The acceptance checklist must cover:
- Every required operator and nested ALL/ANY/NOT behavior, especially missing values.
- Saved search/pattern round trips and fresh relative dates.
- Basic indexed/direct agreement where both have coverage, and direct discovery of unindexed fixture files.
- Tags, metadata absence, file dates, hidden paths, overlapping roots, package rules, and size units.
- Permission errors, missing files, unavailable volumes, and stale results after cancellation.
- Each delivered extraction format and documented failure/partial-coverage behavior.
- Regex semantics, whole-value boundaries, Unicode, invalid syntax, adversarial matching, and enforced cancellation/budgets.
- Positive and negative role-template fixtures.
- Preview/result consistency with the same pattern and flags.
- App restart and launching the packaged app outside the development environment.

Create a representative large synthetic filename dataset, ideally around 100,000 entries when the test environment allows it. Do not present synthetic results as predictions for every external HDD.

Record target hardware, OS, dataset characteristics, storage type, first-result latency, completion time, peak memory including workers, and idle behavior. Starting goals are responsive UI input around 150 ms or less under normal load, visible cancellation acknowledgement around 250 ms, and near-zero idle CPU. Verify actual worker termination separately from the UI acknowledgement. Refine and report performance targets based on measurements rather than making unsupported "instant search" claims.

### Completion and deliverables

Deliver:
1. A built Intel-compatible .app in an installable ZIP or equivalent local package.
2. Source project and an exact reproducible build command compatible with the selected toolchain.
3. Meaningful tests and their actual results, with macOS-only checks separated from portable checks.
4. A brief user guide covering filters, saved searches, permissions, fast indexed versus direct scanning, the regex creator, and role matching.
5. A support/limitations matrix, measured performance notes, and a requirements checklist showing implemented, partial, blocked, or deferred status.
6. Any dependencies and their licenses.

Use signing appropriate for local personal use. Explain any normal launch/setup step; do not require paid distribution signing or notarization unless I later request public distribution.

Finish with what was delivered, how to install/run it, what was actually tested on Intel, and any remaining blocker. If you cannot produce or verify the .app, say exactly why and give the shortest concrete next step. Do not label the full task complete while a material required feature or the target build remains missing.

Start now with environment inspection and a short implementation plan, then proceed through the work.

---

## Prompt 2 — Audit search correctness and regex behavior

Continue the existing Mac File Search project under Prompt 1's requirements. Review the actual code and observed behavior; do not rebuild it from scratch.

Perform a focused correctness review, implement fixes, and run the checks needed to verify them:
- Can indexed-only results be mistaken for exhaustive results?
- Can query pushdown, especially with OR/NOT, exclude legitimate results?
- Do unknown metadata, failed extraction, and regex timeouts incorrectly satisfy negative predicates?
- Can an unavailable saved drive resolve to the wrong location?
- Can stale results survive cancellation or a changed query?
- Are overlapping scopes, symlinks, hidden ancestors, packages, and file-size/date semantics consistent?
- Do all supported formats have honest extraction and coverage reporting?
- Do the regex creator, tester, role template, and live search use identical dialect, flags, boundaries, and normalization?
- Can a pathological pattern consume unbounded time or leave an abandoned worker running?
- Does role matching mistake a former/assistant role, a person signing on behalf of someone, or a nearby unrelated name for the target role?
- Are patterns, examples, and search presets preserved correctly after restart?

Use positive, negative, missing-data, and adversarial fixtures. Prefer tests that catch actual defects over tests that restate implementation details. Do not introduce new product features or dependencies unless a concrete defect requires them.

Report findings by user impact, fixes made, verification performed, and anything still unresolved. Continue to release readiness where the environment permits.

---

## Prompt 3 — Package and verify delivery

Continue the existing Mac File Search project. Complete the delivery requirements of Prompt 1 rather than providing another plan.

1. Resolve any remaining material acceptance failures.
2. Build for the detected target macOS and Intel x86_64 using the documented toolchain.
3. Verify required resources, helper processes, entitlements/signing choices, and bundled dependencies are present and correctly resolved.
4. Launch the packaged app outside Xcode from a normal location. Verify a saved search, direct scan, regex preview/search, role search, and cancellation with controlled fixtures.
5. Confirm no development-machine paths or missing dependencies prevent ordinary use.
6. Record measured performance and supported-format limitations without extrapolating beyond the evidence.
7. Produce the local .app package, source/build instructions, user guide, and final acceptance report.

Do not purchase memberships, publish to an app store, distribute externally, or weaken macOS security. A locally usable personal build is the goal.

Distinguish compiled-for-Intel from actually tested-on-Intel. If the required Mac is unavailable, preserve the work, provide exact remaining commands/steps, and clearly identify the blocked checks instead of claiming success.

---

## Prompt 4 — Resume after an interruption

Resume the existing Mac File Search project using this handover file, the repository, and its current progress/acceptance records.

Inspect actual state before making assumptions. Preserve user changes. Identify the latest successfully verified milestone and the next incomplete requirement. Do not restart, recreate finished components, or silently shrink the agreed scope.

Provide a short status update and continue implementation, fixes, verification, and local packaging. Ask only for a fact or action that is genuinely necessary and unavailable through the environment. Maintain an accurate progress record and report environment-related verification gaps explicitly.

---

## Technical references

These references establish the principal API semantics; verify availability and behavior on the selected macOS/SDK before choosing implementation details.

- [Apple: searching file metadata with NSMetadataQuery](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryingMetadata.html)
- [Apple: Spotlight metadata query syntax](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html)
- [Apple: common Spotlight metadata attributes](https://developer.apple.com/library/archive/documentation/CoreServices/Reference/MetadataAttributesRef/Reference/CommonAttrs.html)
- [ICU: regular-expression syntax and behavior](https://unicode-org.github.io/icu/userguide/strings/regexp.html)
- [Apple: developer program and local development versus distribution](https://developer.apple.com/programs/)

