# Remaining macOS verification

Shortest next step: clone/copy this repository to the target Intel Mac, install Xcode Command Line Tools, and run:

```sh
swift test
./scripts/build-app.sh
open "$PWD/dist/Mac File Search.app"
```

Before declaring release readiness, verify on controlled fixtures: app launch outside Xcode; direct unindexed discovery; Spotlight/direct agreement after the indexed route is implemented; protected-folder errors; unavailable/remounted volume identity; hidden ancestors; packages; hard links and symlinks; Finder tags; all extractors and partial failures; stale-result rejection after cancellation; saved items after restart; Quick Look; all role fixtures; malicious regex hard termination; and 100,000 filenames. Record model, macOS version, filesystem/storage, first-result and completion latency, peak app plus worker memory, cancellation acknowledgement and actual termination, and idle CPU.

Do not substitute Apple Silicon testing or “compiled for Intel” for actual Intel execution. Do not bypass Gatekeeper or SIP. Ad-hoc signing is suitable only for this local personal package.
