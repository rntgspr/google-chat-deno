---
human_revised: false
plan: maintenance-stable-macos-code-signing
task: T3
status: partial
date: 2026-09-12
summary: Persistent release signing is published on the work branch and its authorized GitHub Actions candidate run is in progress.
---

# Hand-off — maintenance-stable-macos-code-signing / T3

## Files touched

<!-- cumaru:touched -->
| Link | Description |
|------|-------------|
| [Build script](../../../build.sh) | Added explicit inside-out signing with the CI identity and retained local ad-hoc builds. |
| [Release workflow](../../../.github/workflows/release.yml) | Added temporary signing credential import and cleanup and updated signing metadata. |
| [Plan](index.md) | Marked T3 in progress. |
| [T3](t3.md) | Recorded implementation progress. |
<!-- /cumaru:touched -->

## Decisions made during implementation

- CI imports the T2 identity before build.sh and restricts its Keychain import to codesign. The three
  private secrets are supplied only to the import step; the build receives the public identity name
  and temporary Keychain path.
- The dedicated signing directory lives under RUNNER_TEMP. The PKCS#12 is removed immediately after
  import. An always-run cleanup step deletes the signing Keychain and removes its directory before
  packaging, including when import or build fails. GitHub-hosted runner disposal is the final fallback.
- Persistent signing discovers regular Mach-O files without following symlinks, then signs nested
  app/framework bundles in depth order and the main app last. It uses timestamp=none and adds no
  hardened-runtime flags, entitlements, trust changes, or credential-architecture changes.
- build.sh uses Bash with pipefail so failures in its NUL-delimited traversal stop the build. Missing
  parts of the CI signing configuration fail explicitly; local builds without that configuration keep
  the existing ad-hoc signature.
- No new tests or verification gates were added. Existing workflow checks predate this plan and remain
  unchanged. T4 remains the manual application installation task.
- The candidate is produced from a dedicated maintenance-stable-macos-code-signing branch through
  the existing manual draft-prerelease workflow, without moving main or publishing a final version.

## Commands run / verification

- Reviewed the implementation diff and confirmed there are no whitespace errors.
- Confirmed the remote already has the dispatchable Release workflow and no existing releases.
- GitHub Actions production execution and its resulting artifact are pending.
- Implementation commit: 05b071c on maintenance-stable-macos-code-signing. The working branch includes
  the user's existing local baseline commit 51b619e and the signing work; main was not advanced.
- Following explicit user authorization, the branch was pushed and candidate v0.0.1-rc.1 was dispatched.
  Run: https://github.com/rntgspr/google-chat-deno/actions/runs/34727753380.
- The first run imported the identity successfully but signing reported no identity found; cleanup
  succeeded. The import step omitted registering the Keychain in the runner user's search list,
  which the codesign manual requires even when an explicit Keychain selects the signing identity.
  Added that runner-only registration before repeating the candidate.

## Pending / follow-ups

- Record the actual workflow result, cleanup outcome, and candidate artifact before marking T3 done.
- T4 installs the resulting app; no installation or cross-release credential continuity is claimed here.

## Suggestions for the Lead

The existing workflow metadata reports strict signature status. Keep that output consistent with the
unchanged existing check. The bootstrap spec should describe self-signed official releases and ad-hoc
local builds when the plan is absorbed.
