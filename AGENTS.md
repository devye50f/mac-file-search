# Repository instructions

- Treat `Mac-File-Search-Codex-Handover.md` as the source requirements and `docs/CODEX-CLI-HANDOVER.md` as the dated transition record; verify changing Git/PR status rather than copying it into this file.
- Preserve uncommitted work and inspect branch ancestry before switching, rebasing, cherry-picking, or using open PR branches. Never merge an open branch blindly.
- Keep `SearchCore` independent of the SwiftUI app and preserve three-valued unknown semantics: missing, unreadable, or unsupported data must not satisfy a negative predicate.
- Do not trigger cloud-placeholder downloads, disable macOS protections, add telemetry/cloud processing, or claim Intel macOS verification without actually running it on an Intel Mac.
- Run portable tests for source changes. For macOS/package claims, record the Mac/toolchain, exact commands, architecture, signing, and runtime checks; update the detailed acceptance/verification documents honestly.
